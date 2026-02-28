// Find nearest player
var _nearest = instance_nearest(x, y, player1);
var _dist = (_nearest != noone) ? point_distance(x, y, _nearest.x, _nearest.y) : 9999;

// === CHECK IF TIME TO RETURN FROM GUNSHOT FLEE ===
if (has_fled && instance_exists(obj_game_controller)) {
    if (obj_game_controller.time_current >= flee_until_time) {
        // 1 hour has passed - return to normal behavior
        has_fled = false;
        state = "wander";
        wander_timer = irandom_range(60, 180);
        wander_direction = random(360);
    }
}

// === CROSSWALK NAVIGATION (runs before state machine) ===
if (is_crossing) {
    switch (crossing_phase) {
        case "approach":
            // Move horizontally toward crosswalk center
            if (target_crosswalk != noone) {
                var _target_x = target_crosswalk.center_x;

                if (abs(x - _target_x) > 3) {
                    // Still approaching crosswalk
                    var _dir = (x < _target_x) ? 0 : 180;
                    x += lengthdir_x(wander_speed, _dir);
                } else {
                    // Reached crosswalk, start crossing
                    crossing_phase = "crossing";
                }
            } else {
                // No crosswalk found, abort
                is_crossing = false;
                crossing_phase = "none";
            }
            break;

        case "crossing":
            // Move straight vertically through the street (lock X to crosswalk center)
            var _crossing_speed = move_speed * 1.5; // Cross confidently
            var _at_destination = false;

            if (target_crosswalk != noone) {
                x = target_crosswalk.center_x;
            }

            var _delta_y = crossing_destination_y - y;
            if (abs(_delta_y) <= _crossing_speed) {
                y = crossing_destination_y;
                _at_destination = true;
            } else {
                y += sign(_delta_y) * _crossing_speed;
            }

            if (_at_destination) {
                // Finished crossing
                is_crossing = false;
                crossing_phase = "none";

                // Resume following if we were
                if (state == "follow" && original_target != noone) {
                    target = original_target;
                    original_target = noone;
                }
            }
            break;
    }

    // Skip normal state machine while crossing
} else {

// === STATE MACHINE ===
switch (state) {
    case "waiting":
        // Do nothing, waiting for transaction dialog response
        break;

    case "leave":
        // Run away after successful sale
        var _leave_new_x = x + lengthdir_x(leave_speed, leave_direction);
        var _leave_new_y = y + lengthdir_y(leave_speed, leave_direction);
        apply_crosswalk_constraints(_leave_new_x, _leave_new_y);

        // Check if off-screen (destroy when far from room)
        if (x < -100 || x > room_width + 100 || y < -100 || y > room_height + 100) {
            instance_destroy();
        }
        break;

    case "wander":
        // Check if we're pausing between movements
        if (wander_pause_timer > 0) {
            wander_pause_timer--;
        } else {
            // Wander in current direction
            if (wander_timer > 0) {
                var _wander_new_x = x + lengthdir_x(wander_speed, wander_direction);
                var _wander_new_y = y + lengthdir_y(wander_speed, wander_direction);
                apply_crosswalk_constraints(_wander_new_x, _wander_new_y);

                // NPCs don't check collision in wander state - they move freely
                // This prevents pileups and allows natural clustering

                wander_timer--;
            } else {
                // Time to change direction - pause first
                wander_pause_timer = irandom_range(30, 90); // Pause for 0.5-1.5 seconds
                wander_direction = random(360); // Pick new random direction
                wander_timer = irandom_range(60, 180); // Walk for 1-3 seconds
            }
        }

        // Occasionally decide to cross street while wandering
        if (wander_timer == 1 && random(1) < 0.3) { // 30% chance when changing direction
            var _target_y = (y < game_ctrl.street_y_top)
                ? game_ctrl.street_y_bottom + 40  // Go to bottom sidewalk
                : game_ctrl.street_y_top - 40;     // Go to top sidewalk

            if (needs_to_cross(_target_y)) {
                initiate_crossing(_target_y);
            }
        }

        // Spot player within detection radius?
        // Only chase if no other customer is already chasing (one-at-a-time queue)
        if (_nearest != noone && _dist < detection_radius && !_nearest.is_jailed) {
            if (game_ctrl.customer_chasing_player == noone || game_ctrl.customer_chasing_player == id) {
                state = "follow";
                target = _nearest;
                is_chasing = true;
                game_ctrl.customer_chasing_player = id;

                // Show speech bubble announcing interest (only once per customer)
                if (!has_announced) {
                    has_announced = true;
                    show_speech_bubble = true;
                    speech_bubble_timer = speech_bubble_duration;
                }
            }
        }
        break;

    case "follow":
        // If we already asked and got refused, just leave
        if (has_asked) {
            state = "leave";
            leave_direction = random(360);
            leave_speed = random_range(1.8, 2.2);
            target = noone;
            if (is_chasing) {
                is_chasing = false;
                if (game_ctrl.customer_chasing_player == id) {
                    game_ctrl.customer_chasing_player = noone;
                }
            }
            break;
        }
        
        // Follow the player
        if (target != noone && instance_exists(target) && !target.is_jailed) {
            // Check if we need to cross the street to reach player
            if (needs_to_cross(target.y) && !is_in_crosswalk()) {
                // Player is on opposite side - navigate to crosswalk
                original_target = target;
                var _target_side_y = (target.y < game_ctrl.street_y_top)
                    ? game_ctrl.street_y_top - 40
                    : game_ctrl.street_y_bottom + 40;
                initiate_crossing(_target_side_y);
            } else {
                // Normal follow behavior
                var _dir = point_direction(x, y, target.x, target.y);
                var _follow_new_x = x + lengthdir_x(move_speed, _dir);
                var _follow_new_y = y + lengthdir_y(move_speed, _dir);
                apply_crosswalk_constraints(_follow_new_x, _follow_new_y);

                // NPCs don't check collision in follow state - they need to reach players
                // This allows them to cluster around players for sales
            }

            // If player gets too far away, go back to wander
            var _target_dist = point_distance(x, y, target.x, target.y);
            if (_target_dist > detection_radius * 1.5) {
                state = "wander";
                target = noone;
                // Release chase slot so another customer can chase
                if (is_chasing) {
                    is_chasing = false;
                    if (game_ctrl.customer_chasing_player == id) {
                        game_ctrl.customer_chasing_player = noone;
                    }
                }
            }
        } else {
            state = "wander";
            target = noone;
            // Release chase slot so another customer can chase
            if (is_chasing) {
                is_chasing = false;
                if (game_ctrl.customer_chasing_player == id) {
                    game_ctrl.customer_chasing_player = noone;
                }
            }
        }
        break;

    case "flee":
        // Run away from the snitch (faster than they approached!)
        if (flee_target != noone && instance_exists(flee_target)) {
            var _old_x = x;
            var _old_y = y;
            var _flee_dir = point_direction(flee_target.x, flee_target.y, x, y); // Direction AWAY from snitch

            var _flee_new_x = x + lengthdir_x(move_speed * 2.5, _flee_dir); // Run much faster when fleeing
            var _flee_new_y = y + lengthdir_y(move_speed * 2.5, _flee_dir);
            apply_crosswalk_constraints(_flee_new_x, _flee_new_y);

            // NPCs don't check collision in flee state - they need to escape quickly
            // This allows them to run through crowds when fleeing from snitches

            // If snitch is far enough away, go back to wander
            var _flee_dist = point_distance(x, y, flee_target.x, flee_target.y);
            if (_flee_dist > detection_radius * 2) {
                state = "wander";
                flee_target = noone;
                checked_snitch = noone; // Reset so we can check again if they come back
            }
        } else {
            state = "wander";
            flee_target = noone;
            checked_snitch = noone;
        }
        break;

    case "gambling":
        // NPC is at the dice game, stay near it
        var _dice = instance_nearest(x, y, obj_dice_game);
        if (_dice != noone) {
            var _dice_dist = point_distance(x, y, _dice.x, _dice.y);
            if (_dice_dist > 80) {
                // If dice game is across the street, use a crosswalk
                if (needs_to_cross(_dice.y) && !is_in_crosswalk()) {
                    var _dice_side_y = (_dice.y < game_ctrl.street_y_top)
                        ? game_ctrl.street_y_top - 40
                        : game_ctrl.street_y_bottom + 40;
                    initiate_crossing(_dice_side_y);
                }
                // Move toward game
                var _dir = point_direction(x, y, _dice.x, _dice.y);
                var _dice_new_x = x + lengthdir_x(move_speed * 0.5, _dir);
                var _dice_new_y = y + lengthdir_y(move_speed * 0.5, _dir);
                apply_crosswalk_constraints(_dice_new_x, _dice_new_y);
            }

            // Occasionally leave the game
            if (random(1) < 0.0001) {
                state = "wander";
            }
        } else {
            state = "wander";
        }
        break;

    case "follow_worker":
        // Customer redirected to a worker - navigate to them
        if (target_worker != noone && instance_exists(target_worker)) {
            var _dist = point_distance(x, y, target_worker.x, target_worker.y);

            if (_dist > 35) {
                if (needs_to_cross(target_worker.y) && !is_in_crosswalk()) {
                    var _worker_side_y = (target_worker.y < game_ctrl.street_y_top)
                        ? game_ctrl.street_y_top - 40
                        : game_ctrl.street_y_bottom + 40;
                    initiate_crossing(_worker_side_y);
                }
                // Move toward worker
                var _dir = point_direction(x, y, target_worker.x, target_worker.y);
                var _worker_new_x = x + lengthdir_x(move_speed, _dir);
                var _worker_new_y = y + lengthdir_y(move_speed, _dir);
                apply_crosswalk_constraints(_worker_new_x, _worker_new_y);
            } else {
                // Close enough - trigger worker sale
                if (target_worker.state == "roaming" && target_worker.sale_timer <= 0) {
                    // Trigger the worker's sale
                    target_worker.state = "selling";
                    target_worker.target_customer = id;
                    target_worker.sale_timer = 180; // 3 second transaction
                    target_worker.status_color = c_purple;

                    // Set self to waiting
                    state = "waiting";
                    show_debug_message("Customer reached worker " + target_worker.worker_name + " - sale starting!");
                }
            }

            // If worker gets destroyed or too far, go back to wander
            if (_dist > detection_radius * 2) {
                state = "wander";
                target_worker = noone;
            }
        } else {
            // Worker disappeared
            state = "wander";
            target_worker = noone;
        }
        break;
}

// === COLLISION WITH PLAYER = SALE (or flee if snitch) ===
var _hit_player = instance_place(x, y, player1);
if (_hit_player != noone && _hit_player.sell_cooldown <= 0 && !_hit_player.is_jailed && state != "flee" && state != "waiting") {
    // Check if player is a snitch (only check once per player)
    if (_hit_player.is_snitch && checked_snitch != _hit_player) {
        checked_snitch = _hit_player;
        // Roll to see if we flee based on snitch level
        var _flee_chance = _hit_player.snitch_flee_chances[_hit_player.snitch_level];
        if (random(1) < _flee_chance) {
            // No sale! Flee faster than we came
            state = "flee";
            flee_target = _hit_player;
            target = noone;
            // Release chase slot when fleeing
            if (is_chasing) {
                is_chasing = false;
                if (game_ctrl.customer_chasing_player == id) {
                    game_ctrl.customer_chasing_player = noone;
                }
            }
        } else if (!has_asked) {
            // Snitch got lucky, make the sale (only ask once)
            // Keep chase slot held during sale - released when entering "leave" state
            has_asked = true;
            scr_make_sale(_hit_player, self);
        }
    } else if (!_hit_player.is_snitch && !has_asked) {
        // Normal sale - keep chase slot held during sale (only ask once)
        has_asked = true;
        scr_make_sale(_hit_player, self);
    }
}

// === DEPTH SORTING ===
depth = -y;

// === SPEECH BUBBLE TIMER ===
if (show_speech_bubble && speech_bubble_timer > 0) {
    speech_bubble_timer--;
    if (speech_bubble_timer <= 0) {
        show_speech_bubble = false;
    }
}

} // End of crosswalk navigation else block
