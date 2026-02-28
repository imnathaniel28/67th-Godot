/// scr_traffic_spawner - Spawn cars based on time of day
/// Called from obj_game_controller Step event

function scr_traffic_spawner(_current_time, _day_length) {
    // Convert frame time to in-game hour (0-23)
    var _hour = (_current_time / _day_length) * 24;

    // Determine traffic density based on time
    // Peak traffic: 9am-10am and 6pm-7pm
    var _traffic_chance = 0.005; // 0.5% base chance per frame to spawn a car

    if ((_hour >= 9 && _hour < 10) || (_hour >= 18 && _hour < 19)) {
        _traffic_chance = 0.01; // 1% chance during rush hour
    } else if ((_hour >= 7 && _hour < 9) || (_hour >= 17 && _hour < 18) || (_hour >= 19 && _hour < 20)) {
        _traffic_chance = 0.0075; // 0.75% chance before/after rush hour
    } else if (_hour >= 0 && _hour < 6) {
        _traffic_chance = 0.0025; // Very rare at night
    }

    // === CIVILIAN CAR SPEED (pixels/frame @ 60fps) ===
    var _speed_min = 2.5; // ~30 MPH feel
    var _speed_max = 5.0; // ~60 MPH feel

    // Spawn civilian cars (eastbound lane - between y=360 and y=380)
    if (random(1) < _traffic_chance) {
        var _car = instance_create_layer(-50, 370, "Instances", obj_car); // Center of lane (360+380)/2 = 370
        _car.dir = 0;
        // 1-in-8 chance of a speeder (~80-90 MPH feel)
        if (irandom(7) == 0) {
            _car.spd = random_range(6.5, 7.5);
        } else {
            _car.spd = random_range(_speed_min, _speed_max);
        }
        _car.x_vel = _car.spd;
        _car.is_cop = false;
        _car.car_type = "civilian";
    }

    // === HEAT & NIGHT MODIFIERS ===
    var _heat_mult = 1.0;
    var _night_civ_mult = 1.0;
    var _night_cop_mult = 1.0;

    // Heat increases cop spawn rate (doubles at max heat)
    if (instance_exists(player1) && variable_instance_exists(player1, "heat_level")) {
        _heat_mult = 1 + (player1.heat_level / 100);
    }

    // Night: fewer cops (0.6x) and fewer civilian cars (0.5x)
    if (instance_exists(obj_game_controller) && obj_game_controller.is_night) {
        _night_cop_mult = 0.6;
        _night_civ_mult = 0.5;
    }

    // === COP CAR SPAWNING - Random interval 120-180 game minutes ===
    // Initialize cop spawn timer and next spawn time if they don't exist
    if (!variable_instance_exists(obj_game_controller, "cop_spawn_timer")) {
        obj_game_controller.cop_spawn_timer = 0;
        var _game_minute = _day_length / 1440;
        obj_game_controller.cop_spawn_next = irandom_range(floor(120 * _game_minute), floor(180 * _game_minute));
    }

    obj_game_controller.cop_spawn_timer++;

    // Spawn cop car when timer reaches random interval
    if (obj_game_controller.cop_spawn_timer >= obj_game_controller.cop_spawn_next) {
        var _cop = instance_create_layer(room_width + 50, 358, "Instances", obj_car);
        _cop.dir = 180;
        _cop.spd = 2.5;
        _cop.x_vel = -_cop.spd;
        _cop.is_cop = true;
        _cop.car_type = "cop";
        _cop.sprite_index = spr_cop_car;

        // Reset timer and pick new random interval (120-180 game minutes)
        obj_game_controller.cop_spawn_timer = 0;
        var _game_minute = _day_length / 1440;
        obj_game_controller.cop_spawn_next = irandom_range(floor(120 * _game_minute), floor(180 * _game_minute));
    }
}

/// scr_spawn_cop_from_car - Spawns a cop from the nearest cop car
/// If no cop car exists, spawns one first, then the cop exits it
/// @param {real} _near_x  X position to find nearest cop car to
/// @param {real} _near_y  Y position to find nearest cop car to
/// @returns {Id.Instance} The spawned cop instance (or noone)
function scr_spawn_cop_from_car(_near_x, _near_y) {
    var _cop_car = noone;
    var _best_dist = 999999;

    // Find the nearest existing cop car
    with (obj_car) {
        if (is_cop) {
            var _d = point_distance(x, y, _near_x, _near_y);
            if (_d < _best_dist) {
                _best_dist = _d;
                _cop_car = id;
            }
        }
    }

    // No cop car found — spawn one and place it near the action
    if (_cop_car == noone || !instance_exists(_cop_car)) {
        var _car_dir, _car_xvel;
        if (_near_x < room_width / 2) {
            _car_dir = 0;
            _car_xvel = 2.5;
        } else {
            _car_dir = 180;
            _car_xvel = -2.5;
        }

        _cop_car = instance_create_layer(
            clamp(_near_x + choose(-120, 120), 50, room_width - 50),
            358, "Instances", obj_car
        );
        _cop_car.dir = _car_dir;
        _cop_car.spd = 2.5;
        _cop_car.x_vel = 0; // Stopped — officers are exiting
        _cop_car.is_cop = true;
        _cop_car.car_type = "cop";
        _cop_car.sprite_index = spr_cop_car;
    }

    // Spawn cop stepping out of the car
    var _spawned_cop = instance_create_layer(_cop_car.x, _cop_car.y + 20, "Instances", obj_cop);
    if (_spawned_cop != noone && instance_exists(_spawned_cop)) {
        var _chase_target = instance_nearest(_near_x, _near_y, player1);
        if (_chase_target != noone && !_chase_target.is_jailed) {
            _spawned_cop.state = "chasing";
            _spawned_cop.target = _chase_target.id;
            _spawned_cop.lost_sight_timer = _spawned_cop.chase_forget_time;
        }
        _spawned_cop.car_parent = _cop_car;
    }

    return _spawned_cop;
}