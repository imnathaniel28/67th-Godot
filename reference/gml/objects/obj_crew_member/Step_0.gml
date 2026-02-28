// === DEPTH SORTING ===
depth = -y;

// === RECRUITING STATES (before hired) ===
if (!is_hired) {
    // Find target player if not set
    if (target_player == noone || !instance_exists(target_player)) {
        target_player = instance_nearest(x, y, player1);
    }

    switch (state) {
        case "recruiting_approach":
            if (target_player != noone && instance_exists(target_player)) {
                var _dist = point_distance(x, y, target_player.x, target_player.y);

                if (_dist > 50) {
                    // Move toward player
                    var _dir = point_direction(x, y, target_player.x, target_player.y);
                    var _old_x = x;
                    var _old_y = y;

                    x += lengthdir_x(move_speed, _dir);
                    y += lengthdir_y(move_speed, _dir);

                    // Update facing
                    var _hor = x - _old_x;
                    var _ver = y - _old_y;
                    if (abs(_hor) > abs(_ver)) {
                        facing = (_hor > 0) ? "right" : "left";
                    } else if (abs(_ver) > 0.1) {
                        facing = (_ver > 0) ? "down" : "up";
                    }
                } else {
                    // Close enough - start recruitment
                    state = "recruiting_waiting";
                    // Face player
                    var _dir = point_direction(x, y, target_player.x, target_player.y);
                    if (_dir >= 315 || _dir < 45) facing = "right";
                    else if (_dir >= 45 && _dir < 135) facing = "down";
                    else if (_dir >= 135 && _dir < 225) facing = "left";
                    else facing = "up";
                }
            }
            break;

        case "recruiting_waiting":
            // Keep facing player
            if (target_player != noone && instance_exists(target_player)) {
                var _dir = point_direction(x, y, target_player.x, target_player.y);
                if (_dir >= 315 || _dir < 45) facing = "right";
                else if (_dir >= 45 && _dir < 135) facing = "down";
                else if (_dir >= 135 && _dir < 225) facing = "left";
                else facing = "up";
            }
            // Dialog handled in Draw_64 event
            break;

        case "rejected":
            // Walk away off-screen
            x += lengthdir_x(move_speed * 1.5, leave_direction);
            y += lengthdir_y(move_speed * 1.5, leave_direction);

            // Destroy when off-screen
            if (x < -100 || x > room_width + 100 || y < -100 || y > room_height + 100) {
                instance_destroy();
            }
            break;
    }

    // Update sprite for recruiting states
    var _moving = (state == "recruiting_approach" || state == "rejected");
    switch (facing) {
        case "down":  sprite_index = _moving ? spr_player_walk_down : spr_player_idle_down; break;
        case "up":    sprite_index = _moving ? spr_player_walk_up : spr_player_idle_up; break;
        case "left":  sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
        case "right": sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
    }

    exit; // Don't run working logic while recruiting
}

// === CHECK IF OWNER EXISTS (only for hired workers) ===
if (owner == noone || !instance_exists(owner)) {
    instance_destroy(); // No owner = destroy self
    exit;
}

// === TEST RUN EXPIRATION CHECK ===
if (is_test_run && game_ctrl.time_current >= test_run_end_time) {
    // Test run over - notify player and await decision
    // For now, just show debug message
    show_debug_message(worker_name + "'s test run is over! Owner must decide to hire or fire.");
    // Player will see this in their crew management UI
}

// === WORK/BREAK TIMER ===
if (state == "roaming" || state == "selling") {
    work_timer++;
    if (work_timer >= work_duration * 60) { // Convert seconds to frames
        // Time for a break
        state = "break";
        work_timer = 0;
        status_color = c_yellow;
    }
} else if (state == "break") {
    break_timer++;
    if (break_timer >= break_duration * 60) {
        // Back to work
        state = "roaming";
        break_timer = 0;
        status_color = c_lime;
    }
}

// === STATE MACHINE ===
switch (state) {
    case "roaming":
        // Find nearest customer NPC
        var _nearest_customer = instance_nearest(x, y, obj_npc_customer);
        var _customer_dist = 9999;

        if (_nearest_customer != noone) {
            _customer_dist = point_distance(x, y, _nearest_customer.x, _nearest_customer.y);

            // Spot a potential customer - check if they're wandering and not already being served
            if (_customer_dist < detection_radius &&
                _nearest_customer.state == "wander" &&
                !_nearest_customer.is_chasing) {
                // Approach the customer to make a sale
                state = "selling";
                target_customer = _nearest_customer;
                sale_timer = 180; // 3 second transaction
                status_color = c_purple; // Purple = selling

                show_debug_message(worker_name + " spotted a customer! Moving to sell...");
                break;
            }
        }

        // === WANDER SYSTEM (like NPCs) ===
        if (wander_pause_timer > 0) {
            wander_pause_timer--;
        } else {
            if (wander_timer > 0) {
                // Move in current wander direction
                var _old_x = x;
                var _old_y = y;

                x += lengthdir_x(move_speed * 0.7, wander_direction);
                y += lengthdir_y(move_speed * 0.7, wander_direction);

                // Stay within territory bounds
                if (assigned_territory != "free") {
                    var _dist_from_center = point_distance(x, y, territory_x, territory_y);
                    if (_dist_from_center > territory_radius) {
                        // Pick direction back toward center
                        wander_direction = point_direction(x, y, territory_x, territory_y);
                    }
                }

                // Update sprite based on movement
                var _hor = x - _old_x;
                var _ver = y - _old_y;
                if (abs(_hor) > abs(_ver)) {
                    facing = (_hor > 0) ? "right" : "left";
                } else if (abs(_ver) > 0.1) {
                    facing = (_ver > 0) ? "down" : "up";
                }

                wander_timer--;
            } else {
                // Time to change direction - pause first
                wander_pause_timer = irandom_range(20, 60); // Pause 0.3-1 seconds
                wander_direction = random(360); // New direction
                wander_timer = irandom_range(60, 180); // Walk 1-3 seconds
            }
        }
        break;

    case "selling":
        // Move toward customer to make sale
        if (target_customer != noone && instance_exists(target_customer)) {
            var _dist_to_customer = point_distance(x, y, target_customer.x, target_customer.y);

            // If not close enough, move toward customer
            if (_dist_to_customer > 30) {
                var _dir = point_direction(x, y, target_customer.x, target_customer.y);
                var _old_x = x;
                var _old_y = y;

                x += lengthdir_x(move_speed * 1.2, _dir);
                y += lengthdir_y(move_speed * 1.2, _dir);

                // Update facing
                var _hor = x - _old_x;
                var _ver = y - _old_y;
                if (abs(_hor) > abs(_ver)) {
                    facing = (_hor > 0) ? "right" : "left";
                } else if (abs(_ver) > 0.1) {
                    facing = (_ver > 0) ? "down" : "up";
                }
            } else {
                // Close enough - make the sale
                sale_timer--;

                if (sale_timer <= 0) {
                    // Calculate sale success
                    var _base_sale = irandom_range(15, 45);
                    var _skill_multiplier = (sales_skill / 10);
                    var _sale_amount = floor(_base_sale * _skill_multiplier);

                    // Success chance (skill-based, no heat penalty for now)
                    var _success_chance = (sales_skill * 10);

                    if (random(100) < _success_chance && inventory_drugs > 0) {
                        // SUCCESSFUL SALE
                        daily_earnings += _sale_amount;
                        total_earnings += _sale_amount;
                        inventory_drugs -= 1;
                        worker_xp += 1;

                        show_debug_message(worker_name + " made a sale! +$" + string(_sale_amount) + " (Total today: $" + string(daily_earnings) + ")");

                        // Check for level up
                        if (worker_xp >= xp_to_next_level) {
                            worker_level++;
                            worker_xp = 0;
                            xp_to_next_level = worker_level * 20;

                            // Increase stats on level up
                            sales_skill = min(10, sales_skill + 1);
                            heat_management = min(10, heat_management + 1);
                            loyalty = min(10, loyalty + 1);

                            show_debug_message(worker_name + " leveled up to Level " + string(worker_level) + "!");
                        }

                        // Customer leaves
                        if (instance_exists(target_customer)) {
                            target_customer.state = "leave";
                            target_customer.leave_direction = random(360);
                            target_customer.leave_speed = random_range(1.8, 2.2);
                        }
                    } else {
                        // FAILED SALE
                        show_debug_message(worker_name + " failed a sale!");
                    }

                    // Reset state
                    state = "roaming";
                    target_customer = noone;
                    sale_timer = sale_cooldown;
                    status_color = c_lime;
                }
            }
        } else {
            // Customer disappeared
            state = "roaming";
            target_customer = noone;
            status_color = c_lime;
            show_debug_message(worker_name + " lost the customer, back to roaming.");
        }
        break;

    case "break":
        // Just stand still and chill
        // Animation handled in Draw event
        break;

    case "fleeing":
        // Run from cops (future implementation)
        break;

    case "returning":
        // Return to trap house to drop off money (future implementation)
        break;
}

// === UPDATE SPRITE ===
var _moving = (state == "roaming");
switch (facing) {
    case "down":  sprite_index = _moving ? spr_player_walk_down : spr_player_idle_down; break;
    case "up":    sprite_index = _moving ? spr_player_walk_up : spr_player_idle_up; break;
    case "left":  sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
    case "right": sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
}

// === COOLDOWN TIMERS ===
if (sale_timer > 0) sale_timer--;
