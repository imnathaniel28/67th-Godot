/// scr_random_events - Random event system
/// Called periodically from obj_game_controller Step

enum EVENT_TYPE {
    DRIVE_BY = 0,
    POLICE_RAID = 1,
    SNITCH_SPOTTED = 2,
    BIG_BUYER = 3,
    TURF_WAR = 4,
    SUPPLY_DROP = 5
}

/// Triggers a random event based on time of day
function scr_trigger_random_event() {
    if (!instance_exists(player1)) return;
    var _p = instance_find(player1, 0);
    if (_p.is_jailed) return;

    // Build weighted event pool based on time of day
    var _is_night = obj_game_controller.is_night;
    var _events = [];
    var _weights = [];

    // DRIVE_BY: More common at night
    array_push(_events, EVENT_TYPE.DRIVE_BY);
    array_push(_weights, _is_night ? 25 : 10);

    // POLICE_RAID: More common during day
    array_push(_events, EVENT_TYPE.POLICE_RAID);
    array_push(_weights, _is_night ? 10 : 25);

    // SNITCH_SPOTTED: Equal chance
    array_push(_events, EVENT_TYPE.SNITCH_SPOTTED);
    array_push(_weights, 15);

    // BIG_BUYER: Equal chance
    array_push(_events, EVENT_TYPE.BIG_BUYER);
    array_push(_weights, 15);

    // TURF_WAR: More common at night
    array_push(_events, EVENT_TYPE.TURF_WAR);
    array_push(_weights, _is_night ? 20 : 10);

    // SUPPLY_DROP: Equal chance
    array_push(_events, EVENT_TYPE.SUPPLY_DROP);
    array_push(_weights, 15);

    // Weighted random selection
    var _total_weight = 0;
    for (var i = 0; i < array_length(_weights); i++) {
        _total_weight += _weights[i];
    }

    var _roll = random(_total_weight);
    var _cumulative = 0;
    var _selected = 0;

    for (var i = 0; i < array_length(_weights); i++) {
        _cumulative += _weights[i];
        if (_roll < _cumulative) {
            _selected = _events[i];
            break;
        }
    }

    // Execute the selected event
    switch (_selected) {
        case EVENT_TYPE.DRIVE_BY:
            scr_event_drive_by(_p);
            break;
        case EVENT_TYPE.POLICE_RAID:
            scr_event_police_raid(_p);
            break;
        case EVENT_TYPE.SNITCH_SPOTTED:
            scr_event_snitch_spotted(_p);
            break;
        case EVENT_TYPE.BIG_BUYER:
            scr_event_big_buyer(_p);
            break;
        case EVENT_TYPE.TURF_WAR:
            scr_event_turf_war(_p);
            break;
        case EVENT_TYPE.SUPPLY_DROP:
            scr_event_supply_drop(_p);
            break;
    }
}

/// DRIVE-BY: Spawn a hostile car that stops and shoots at the player
function scr_event_drive_by(_player) {
    scr_notify("!! DRIVE-BY !!", c_red);

    // Determine spawn side and direction
    var _spawn_from_left = (_player.x > room_width / 2);
    var _car_dir, _spawn_x, _lane_y;

    if (_spawn_from_left) {
        // Car comes from the left, drives right
        _car_dir = 0;
        _spawn_x = -60;
        _lane_y = 370; // Eastbound lane
    } else {
        // Car comes from the right, drives left
        _car_dir = 180;
        _spawn_x = room_width + 60;
        _lane_y = 358; // Westbound lane
    }

    var _car = instance_create_layer(_spawn_x, _lane_y, "Instances", obj_driveby_car);
    if (_car != noone && instance_exists(_car)) {
        _car.target = _player;
        _car.dir = _car_dir;
        _car.stop_x = _player.x; // Stop near where the player is now
        _car.x_vel = (_car_dir == 0) ? _car.spd : -_car.spd;

        // Pull street boundaries from game controller
        if (instance_exists(obj_game_controller)) {
            _car.street_y_top = obj_game_controller.street_y_top;
            _car.street_y_bottom = obj_game_controller.street_y_bottom;
        }
    }

    _player.heat_level = min(100, _player.heat_level + 5);
    _player.last_crime_time = game_ctrl.time_current;
}

/// POLICE RAID: Multiple cops spawn from nearest cop cars
function scr_event_police_raid(_player) {
    scr_notify("!! POLICE RAID !!", c_red);
    phone_add_message("Partner", "Cops are raiding the area! Stay low!");
    var _cop_count = irandom_range(2, 3);
    for (var i = 0; i < _cop_count; i++) {
        scr_spawn_cop_from_car(_player.x, _player.y);
    }
    _player.heat_level = min(100, _player.heat_level + 15);
}

/// SNITCH SPOTTED: Warning that someone snitched, +heat
function scr_event_snitch_spotted(_player) {
    scr_notify("Someone snitched on you!", c_orange);
    _player.heat_level = min(100, _player.heat_level + 10);
    _player.last_crime_time = game_ctrl.time_current;
    // Spawn a cop from the nearest cop car
    scr_spawn_cop_from_car(_player.x, _player.y);
}

/// BIG BUYER: A customer with 3-5x normal payment approaches
function scr_event_big_buyer(_player) {
    scr_notify("Big buyer in the area! $$$", c_lime);
    phone_add_message("Contact", "Big buyer looking for you. $$$ ready.");
    // Spawn a high-paying customer
    var _sx = _player.x + choose(-100, 100);
    var _sy = _player.y + random_range(-50, 50);
    _sx = clamp(_sx, 50, room_width - 50);
    _sy = clamp(_sy, 50, room_height - 50);
    var _buyer = instance_create_depth(_sx, _sy, 0, obj_npc_customer);
    // Boost their payment 3-5x
    _buyer.payment_amount = _buyer.payment_amount * irandom_range(3, 5);
    _buyer.speech_text = "BIG ORDER!";
}

/// TURF WAR: Rival dealer spawns (if obj_rival_dealer exists)
function scr_event_turf_war(_player) {
    scr_notify("Rival dealer on your turf!", c_red);
    var _sx = _player.x + choose(-150, 150);
    var _sy = _player.y + random_range(-60, 60);
    _sx = clamp(_sx, 50, room_width - 50);
    _sy = clamp(_sy, 50, room_height - 50);
    if (object_exists(obj_rival_dealer)) {
        instance_create_depth(_sx, _sy, 0, obj_rival_dealer);
    }
    _player.heat_level = min(100, _player.heat_level + 3);
}

/// GUNSHOT PANIC: Trigger NPCs, cars, and cops to respond when gunshots occur
function scr_trigger_gunshot_panic(_x, _y) {
    // Make all NPCs flee
    with (obj_npc_customer) {
        if (state != "leave") { // Only if not already leaving
            // Set flee mode with 1-hour cooldown
            state = "leave";
            leave_speed = 2.5; // Fast flight
            leave_direction = point_direction(_x, _y, x, y); // Run away from gunshot
            flee_until_time = game_ctrl.time_current + (game_ctrl.day_length / 24); // 1 in-game hour
            has_fled = true;
        }
    }

    // Make all civilian cars drive away faster
    with (obj_car) {
        if (!is_cop && car_type == "civilian") {
            // Increase speed dramatically
            spd = 5; // Double speed
            base_spd = 5; // Update base speed too
        }
    }

    // Immediate cop response: spawn from existing cop cars if available
    // Otherwise, schedule delayed response (3 cars) after 45-60 minutes
    if (instance_exists(obj_game_controller) && instance_exists(player1)) {
        var _p = instance_find(player1, 0);
        if (_p != noone && !_p.is_jailed) {
            var _nearest_cop_car = noone;
            var _nearest_dist = 9999;

            // Find nearest cop car within 400 pixels
            with (obj_car) {
                if (is_cop && !block_cop_spawned) {
                    var _d = point_distance(x, y, _x, _y);
                    if (_d < 400 && _d < _nearest_dist) {
                        _nearest_cop_car = id;
                        _nearest_dist = _d;
                    }
                }
            }

            // If cop car exists nearby, spawn cops from it immediately
            if (_nearest_cop_car != noone && instance_exists(_nearest_cop_car)) {
                var _heat_level = _p.heat_level;
                var _cop_count = (_heat_level > 50) ? 2 : 1;

                for (var _i = 0; _i < _cop_count; _i++) {
                    var _spawned_cop = instance_create_layer(_nearest_cop_car.x + (_i * 30), _nearest_cop_car.y, "Instances", obj_cop);
                    if (_spawned_cop != noone && instance_exists(_spawned_cop)) {
                        _spawned_cop.state = "chasing";
                        _spawned_cop.target = _p.id;
                        _spawned_cop.lost_sight_timer = _spawned_cop.chase_forget_time;
                        _spawned_cop.car_parent = _nearest_cop_car;
                        _spawned_cop.chase_speed = 1.1 + (_heat_level / 200);
                    }
                }
                _nearest_cop_car.has_target = true;
                _nearest_cop_car.block_cop_spawned = true;
            } else {
                // No cop car nearby - schedule delayed response (3 cars)
                var _game_minute = obj_game_controller.day_length / 1440;
                obj_game_controller.gunfire_cop_timer = 0; // Reset timer
                obj_game_controller.gunfire_cop_response_delay = irandom_range(floor(45 * _game_minute), floor(60 * _game_minute));
                obj_game_controller.gunfire_cop_cars_spawned = 0; // Track how many cop cars we've spawned
                obj_game_controller.has_pending_gunfire_response = true;
            }
        }
    }
}

/// SUPPLY DROP: Free drugs appear near player
function scr_event_supply_drop(_player) {
    scr_notify("Supply drop nearby!", c_aqua);
    phone_add_message("Dealer", "Left a package for you nearby.");
    // Give player random drugs
    var _drug = irandom(4);
    var _amount = irandom_range(5, 15);
    switch (_drug) {
        case DRUG_TYPE.WEED:    _player.inventory_weed += _amount; break;
        case DRUG_TYPE.PILLS:   _player.inventory_pills += _amount; break;
        case DRUG_TYPE.COCAINE: _player.inventory_cocaine += _amount; break;
        case DRUG_TYPE.HEROIN:  _player.inventory_heroin += _amount; break;
        case DRUG_TYPE.METH:    _player.inventory_meth += _amount; break;
    }
    scr_notify("+" + string(_amount) + " " + drug_get_name(_drug) + "!", c_lime);
}
