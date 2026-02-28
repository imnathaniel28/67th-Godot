// === TICK TIME ===
// Time always progresses regardless of game state
time_current++;

// === DEBUG TOGGLE ===
// Press F12 to toggle the on-screen debug overlay
if (keyboard_check_pressed(vk_f12)) {
    global.debug_mode = !global.debug_mode;
    show_debug_message("Debug overlay: " + string(global.debug_mode));
}

// === DEBUG TEST: Trigger promotion cutscene (F10) ===
if (keyboard_check_pressed(vk_f10)) {
    if (instance_number(obj_promotion_cutscene) == 0) {
        instance_create_depth(0, 0, -9999, obj_promotion_cutscene);
        show_debug_message("Debug: spawned promotion cutscene");
    }
}

// === DEBUG TEST: Force-jail player1 (F11) ===
if (keyboard_check_pressed(vk_f11)) {
    var _p = instance_find(player1, 0);
    if (_p != noone) {
        _p.is_jailed = true;
        // test jail: timer disabled
        jailed_player = _p;
        room_goto(rm_jail_lobby);
        with (_p) { x = 400; y = 500; }
        show_debug_message("Test: player1 jailed for 30s");
    } else {
        show_debug_message("Test jail: player1 instance not found");
    }
}

// Also allow 'J' key for quicker testing (some keyboards may not register F11)
if (keyboard_check_pressed(ord("J"))) {
    var _p2 = instance_find(player1, 0);
    if (_p2 != noone) {
        _p2.is_jailed = true;
        // test jail (J): timer disabled
        jailed_player = _p2;
        room_goto(rm_jail_lobby);
        with (_p2) { x = 400; y = 500; }
        show_debug_message("Test (J): player1 jailed for 30s");
    } else {
        show_debug_message("Test jail (J): player1 instance not found");
    }
}

// Calculate in-game time (24-hour format)
var time_progress = time_current / day_length; // 0 to 1
var total_minutes = time_progress * 1440; // Total minutes in 24 hours
time_hours = floor(total_minutes / 60) mod 24;
time_minutes = floor(total_minutes mod 60);

// Format time string (12-hour format with AM/PM)
var display_hour = time_hours;
var am_pm = "AM";

if (time_hours >= 12) {
    am_pm = "PM";
    if (time_hours > 12) {
        display_hour = time_hours - 12;
    }
}

// Handle midnight (0:00 -> 12:00 AM)
if (time_hours == 0) {
    display_hour = 12;
}

var hour_str = string(display_hour);
var min_str = (time_minutes < 10) ? "0" + string(time_minutes) : string(time_minutes);
time_string = hour_str + ":" + min_str + " " + am_pm;

// Determine if it's night time (10pm to 10am = 22:00 to 10:00)
is_night = (time_hours >= 22 || time_hours < 10);

// Smoothly transition night darkness
var target_alpha = is_night ? 0.4 : 0;
night_alpha = lerp(night_alpha, target_alpha, 0.02);

// === TRAFFIC SPAWNING (only in Room1 and during gameplay) ===
if (game_state == GAME_STATE.PLAYING && room == Seattle) {
    scr_traffic_spawner(time_current, day_length);
}

// === GUNFIRE-TRIGGERED COP RESPONSE (3 cop cars, 45-60 minutes after gunfire) ===
if (game_state == GAME_STATE.PLAYING && has_pending_gunfire_response && room == Seattle) {
    gunfire_cop_timer++;

    // Check if we've waited long enough for the first cop car to appear
    if (gunfire_cop_timer >= gunfire_cop_response_delay) {
        // Spawn a cop car if we haven't spawned all 3 yet
        if (gunfire_cop_cars_spawned < 3) {
            var _cop_car = instance_create_layer(room_width + 50, 358, "Instances", obj_car);
            _cop_car.dir = 180;
            _cop_car.spd = 2.5;
            _cop_car.x_vel = -_cop_car.spd;
            _cop_car.is_cop = true;
            _cop_car.car_type = "cop";
            _cop_car.sprite_index = spr_cop_car;
            _cop_car.car_color = $FFFFFF;

            gunfire_cop_cars_spawned++;

            // Reset timer for next car (spawn them back-to-back with ~10 second gaps)
            if (gunfire_cop_cars_spawned < 3) {
                gunfire_cop_timer = gunfire_cop_response_delay - 600; // 10 second gap at 60fps
            } else {
                // All 3 cars spawned, stop the response
                has_pending_gunfire_response = false;
            }
        }
    }
}

// === GAME WORLD UPDATES (only during gameplay) ===
if (game_state == GAME_STATE.PLAYING) {

    // Initialize dealer network once
    if (!dealer_network_initialized && room == Seattle) {
        var high_dealers = [];
        var mid_dealers = [];
        var low_dealers = [];

        // Collect all dealers by level
        with (obj_dealer_stashHouse_high) array_push(high_dealers, id);
        with (obj_dealer_stashHouse_mid) array_push(mid_dealers, id);
        with (obj_dealer_stashHouse_low) array_push(low_dealers, id);

        // Link mid-level dealers to high-level
        if (array_length(high_dealers) > 0 && array_length(mid_dealers) > 0) {
            var druglord = high_dealers[0];
            for (var i = 0; i < array_length(mid_dealers); i++) {
                array_push(druglord.supply_network, mid_dealers[i]);
                mid_dealers[i].supplier = druglord;
            }
        }

        // Link low-level dealers to mid-level
        if (array_length(mid_dealers) > 0 && array_length(low_dealers) > 0) {
            for (var i = 0; i < array_length(low_dealers); i++) {
                var mid_dealer = mid_dealers[i mod array_length(mid_dealers)];
                array_push(mid_dealer.supply_network, low_dealers[i]);
                low_dealers[i].supplier = mid_dealer;
            }
        }

        dealer_network_initialized = true;
    }

    // Check shipment schedule
    for (var i = 0; i < array_length(shipment_schedule); i++) {
        var shipment = shipment_schedule[i];

        if (!shipment.completed && time_current >= shipment.time) {
            // Spawn shipment
            var spawn_x = -50;
            var spawn_y = room_height / 2;
            var origin_obj = noone;
            var dest_obj = noone;

            // Determine origin and destination
            if (shipment.from == "external") {
                spawn_x = -50;
                spawn_y = random_range(100, room_height - 100);
            } else if (shipment.from == "high") {
                var high_dealer = instance_find(obj_dealer_stashHouse_high, 0);
                if (instance_exists(high_dealer)) {
                    origin_obj = high_dealer;
                    spawn_x = high_dealer.x;
                    spawn_y = high_dealer.y;
                }
            } else if (shipment.from == "mid") {
                var mid_dealer = instance_find(obj_dealer_stashHouse_mid, 0);
                if (instance_exists(mid_dealer)) {
                    origin_obj = mid_dealer;
                    spawn_x = mid_dealer.x;
                    spawn_y = mid_dealer.y;
                }
            }

            if (shipment.to == "high") {
                dest_obj = instance_find(obj_dealer_stashHouse_high, 0);
            } else if (shipment.to == "mid") {
                dest_obj = instance_find(obj_dealer_stashHouse_mid, 0);
            } else if (shipment.to == "low") {
                dest_obj = instance_find(obj_dealer_stashHouse_low, 0);
            }

            // Create shipment vehicle
            if (instance_exists(dest_obj)) {
                var vehicle = noone;

                if (shipment.vehicle == "car") {
                    vehicle = instance_create_depth(spawn_x, spawn_y, -1000, obj_shipment_car);
                } else if (shipment.vehicle == "walk") {
                    vehicle = instance_create_depth(spawn_x, spawn_y, -1000, obj_shipment_walker);
                }

                if (instance_exists(vehicle)) {
                    vehicle.drug_amount = shipment.amount;
                    vehicle.origin = origin_obj;
                    vehicle.destination = dest_obj;
                    vehicle.route_type = shipment.from + "_to_" + shipment.to;

                    // Deduct from origin if not external
                    if (shipment.from != "external" && instance_exists(origin_obj)) {
                        origin_obj.stash_amount = max(0, origin_obj.stash_amount - shipment.amount);
                    }
                }
            }

            shipment.completed = true;
        }
    }
}

// === UPDATE NOTIFICATIONS ===
for (var _n = array_length(notification_queue) - 1; _n >= 0; _n--) {
    var _toast = notification_queue[_n];
    _toast.timer--;

    // Fade in (first 30 frames)
    if (_toast.timer > 150) {
        _toast.alpha = lerp(_toast.alpha, 1.0, 0.15);
        _toast.y_offset = lerp(_toast.y_offset, 0, 0.2);
    }
    // Fade out (last 30 frames)
    else if (_toast.timer < 30) {
        _toast.alpha = lerp(_toast.alpha, 0, 0.1);
    }

    // Remove expired
    if (_toast.timer <= 0) {
        array_delete(notification_queue, _n, 1);
    }
}

// === DAY ROLLOVER (always happens regardless of game state) ===
if (time_current >= day_length) {
    time_current = 0;
    day_current++;

    // Reset shipment schedule for new day
    for (var i = 0; i < array_length(shipment_schedule); i++) {
        shipment_schedule[i].completed = false;
    }

    with (player1) {
        event_user(0);
    }

    if (day_current > 7) {
        day_current = 1;
        week_current++;
    }

    // === LOAN SHARK: DEBT COLLECTOR SPAWN ===
    if (instance_exists(player1)) {
        var _p = instance_find(player1, 0);
        if (_p.has_active_loan && day_current > _p.loan_due_day && !_p.is_jailed && room == Seattle) {
            // Spawn debt collector if loan is overdue
            var _spawn_x = _p.x + choose(-200, 200);
            var _spawn_y = _p.y + random_range(-50, 50);
            _spawn_x = clamp(_spawn_x, 50, room_width - 50);
            _spawn_y = clamp(_spawn_y, 50, room_height - 50);
            instance_create_depth(_spawn_x, _spawn_y, 0, obj_debt_collector);
            scr_notify("Debt collector is after you!", c_red);
        }
    }
}

// === RANDOM EVENTS ===
if (room == Seattle && game_state == GAME_STATE.PLAYING) {
    event_timer++;
    if (event_timer >= next_event_time) {
        event_timer = 0;
        next_event_time = irandom_range(floor(event_interval_min), floor(event_interval_max));
        scr_trigger_random_event();
    }
}

// === PEDESTRIAN SPAWNING ===
if (room == Seattle && game_state == GAME_STATE.PLAYING) {
    if (instance_number(obj_pedestrian) < max_pedestrians && random(1) < 0.005) {
        var _sx = irandom_range(50, room_width - 50);
        var _sy = choose(irandom_range(50, game_ctrl.street_y_top - 30),
                         irandom_range(game_ctrl.street_y_bottom + 30, room_height - 50));
        instance_create_depth(_sx, _sy, 0, obj_pedestrian);
    }
}

// === CUSTOMER SPAWNING (1 every 60-90 game minutes, walk in from off-map) ===
if (room == Seattle && game_state == GAME_STATE.PLAYING) {
    customer_spawn_timer--;
    if (customer_spawn_timer <= 0 && instance_number(obj_npc_customer) < max_customers) {
        // Pick a random edge to spawn from (0=left, 1=right, 2=top, 3=bottom)
        var _edge = irandom(3);
        var _sx, _sy, _dir;
        switch (_edge) {
            case 0: // Left edge
                _sx = -30;
                _sy = choose(irandom_range(50, street_y_top - 30),
                             irandom_range(street_y_bottom + 30, room_height - 50));
                _dir = random_range(-45, 45); // Walk rightward
                break;
            case 1: // Right edge
                _sx = room_width + 30;
                _sy = choose(irandom_range(50, street_y_top - 30),
                             irandom_range(street_y_bottom + 30, room_height - 50));
                _dir = random_range(135, 225); // Walk leftward
                break;
            case 2: // Top edge
                _sx = irandom_range(50, room_width - 50);
                _sy = -30;
                _dir = random_range(225, 315); // Walk downward
                break;
            case 3: // Bottom edge
                _sx = irandom_range(50, room_width - 50);
                _sy = room_height + 30;
                _dir = random_range(45, 135); // Walk upward
                break;
        }
        var _cust = instance_create_depth(_sx, _sy, 0, obj_npc_customer);
        _cust.wander_direction = _dir;
        _cust.wander_timer = irandom_range(180, 360); // Walk inward for 3-6 seconds before changing direction
        // Reset timer for next spawn
        customer_spawn_timer = irandom_range(customer_spawn_min, customer_spawn_max);
    }
    // If at cap, just reset the timer so it checks again next interval
    if (customer_spawn_timer <= 0) {
        customer_spawn_timer = irandom_range(customer_spawn_min, customer_spawn_max);
    }
}

// === RIVAL DEALER SPAWNING (1-2 per day) ===
if (room == Seattle && game_state == GAME_STATE.PLAYING) {
    if (instance_number(obj_rival_dealer) < 2 && random(1) < 0.0005) {
        var _sx = irandom_range(100, room_width - 100);
        var _sy = choose(irandom_range(50, game_ctrl.street_y_top - 30),
                         irandom_range(game_ctrl.street_y_bottom + 30, room_height - 50));
        instance_create_depth(_sx, _sy, 0, obj_rival_dealer);
    }
}

// === JAIL UI INPUT ===
if (game_state == GAME_STATE.JAIL && showing_snitch_offer) {
    if (keyboard_check_pressed(ord("Y"))) {
        jailed_player.is_snitch = true;
        jailed_player.snitch_timer = jailed_player.snitch_duration;
        jailed_player.is_jailed = false;
        jailed_player.x = 600;
        jailed_player.y = 500;
        jailed_player = noone; // Clear reference, will rescan if needed on room recreation
        jailed_player_scan_needed = true; // Flag to scan next frame if player recreated

        showing_snitch_offer = false;
        game_state = GAME_STATE.PLAYING;
    }

    if (keyboard_check_pressed(ord("N"))) {
        showing_snitch_offer = false;
        game_state = GAME_STATE.PLAYING;
    }
}
// === JAIL TIMER MANAGEMENT DISABLED ===
// Central real-time jail timer removed; alternate system to be implemented.
last_dt = 0;

// Scan for jailed player only if flagged as needed (prevents expensive loop every frame)
if (jailed_player_scan_needed) {
    jailed_player_scan_needed = false; // Reset flag
    
    if (jailed_player == noone || !instance_exists(jailed_player)) {
        var _count = instance_number(player1);

        for (var _i = 0; _i < _count; _i++) {
            var _p = instance_find(player1, _i);
            if (_p == noone) continue;
            if (_p.is_jailed) {
                jailed_player = _p;
                last_real_time = get_timer();
                last_dt = 0;
                break;
            }
        }
    }
}
// === JAYWALKING FINE INPUT ===
if (game_state == GAME_STATE.JAIL && showing_fine_popup) {
    // Option 1: Pay the fine
    if (keyboard_check_pressed(ord("1")) && fined_player.money >= fine_amount) {
        fined_player.money -= fine_amount;
        showing_fine_popup = false;
        game_state = GAME_STATE.PLAYING;
    }

    // Option 2: Go to jail
    if (keyboard_check_pressed(ord("2"))) {
        fined_player.is_jailed = true;
        // jail duration handling removed; mark player jailed
        showing_fine_popup = false;
        game_state = GAME_STATE.PLAYING;
        room_goto(rm_jail_lobby);
    }

    // Option 3: Go into debt
    if (keyboard_check_pressed(ord("3"))) {
        fined_player.debt += fine_amount;
        showing_fine_popup = false;
        game_state = GAME_STATE.PLAYING;
    }
}

// === POLICE ROBBERY INPUT ===
if (showing_robbery_popup) {
    // Press any key to dismiss
    if (keyboard_check_pressed(vk_anykey)) {
        showing_robbery_popup = false;
    }
}

// === BACKDOOR MESSAGE TIMER ===
if (show_backdoor_msg) {
    backdoor_msg_timer--;
    if (backdoor_msg_timer <= 0) {
        show_backdoor_msg = false;
    }
}

// === PVP CHOICE INPUT ===
if (game_state == GAME_STATE.PVP_CHOICE && !pvp_choices_locked) {
    if (pvp_choice1 == PVP_CHOICE.NONE) {
        if (keyboard_check_pressed(ord("C"))) pvp_choice1 = PVP_CHOICE.COLLABORATE;
        if (keyboard_check_pressed(ord("R"))) pvp_choice1 = PVP_CHOICE.ROB;
    }

    if (pvp_choice2 == PVP_CHOICE.NONE) {
        if (keyboard_check_pressed(ord("P"))) pvp_choice2 = PVP_CHOICE.COLLABORATE;
        if (keyboard_check_pressed(ord("L"))) pvp_choice2 = PVP_CHOICE.ROB;
    }

    if (pvp_choice1 != PVP_CHOICE.NONE && pvp_choice2 != PVP_CHOICE.NONE) {
        pvp_choices_locked = true;
        alarm[0] = 60;
    }
}
