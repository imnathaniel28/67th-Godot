// Step Event - obj_cop
// Roaming cop that chases and arrests player, can be stunned by input combo

// Depth sorting for proper rendering
depth = -y;

// Lifetime countdown - despawn after a while (but not if returning to car)
if (state != "returning") {
    lifetime--;
    if (lifetime <= 0) {
        // If cop has a car, return to it instead of just despawning
        if (car_parent != noone && instance_exists(car_parent)) {
            state = "returning";
            target = noone;
        } else {
            instance_destroy();
            exit;
        }
    }
}

// Reset state once stun expires
if (stunned_timer <= 0 && state == "stunned") {
    state = "roaming";
    target = noone;
}

// Stunned cops do nothing for the duration
if (stunned_timer > 0) {
    stunned_timer--;
    sprite_index = (facing == 1) ? spr_idle_right : spr_idle_left;
    x = clamp(x, 32, room_width - 32);
    y = clamp(y, 32, room_height - 32);
    exit;
}

// Dynamic detection range based on player heat level
if (instance_exists(player1)) {
    var _p1 = instance_nearest(x, y, player1);
    if (_p1 != noone && variable_instance_exists(_p1, "heat_level")) {
        detection_range = base_detection_range + _p1.heat_level; // 100-200px
    }
}

// Player detection (track the nearest living player instance)
var _player = noone;
if (instance_exists(player1)) {
    var _p = instance_nearest(x, y, player1);
    if (_p != noone && !_p.is_jailed) {
        _player = _p;
    }
}

// Cops ignore players who are working at the city dump (legal employment)
if (_player != noone && instance_exists(obj_city_dump)) {
    if (obj_city_dump.work_mode_active) {
        _player = noone;
        // Also drop any existing chase if player just started working
        if (state == "chasing") {
            state = "roaming";
            target = noone;
        }
    }
}

var _dist = (_player != noone) ? point_distance(x, y, _player.x, _player.y) : -1;

// Acquire chase when the player enters detection range
if (_player != noone && state == "roaming" && _dist <= detection_range) {
    state = "chasing";
    target = _player.id; // store instance id so player-side stun check can match
    lost_sight_timer = chase_forget_time;
}

// Maintain or drop chase if the player gets away
if (state == "chasing") {
    chase_timer++;
    // Resolve current target instance
    var _target_inst = noone;
    if (target != noone && instance_exists(target)) {
        _target_inst = target;
    }

    if (_target_inst == noone || _target_inst.is_jailed) {
        // Target gone or jailed - return to car if we have one
        if (car_parent != noone && instance_exists(car_parent)) {
            state = "returning";
            target = noone;
            show_debug_message("COP: Target gone/jailed, returning to car");
        } else {
            state = "roaming";
            target = noone;
        }
    } else {
        // Refresh distance with the actual target instance
        _dist = point_distance(x, y, _target_inst.x, _target_inst.y);

        if (_dist <= detection_range) {
            lost_sight_timer = chase_forget_time;
        } else {
            lost_sight_timer--;
            if (lost_sight_timer <= 0) {
                // Lost sight of player - return to car if we have one
                if (car_parent != noone && instance_exists(car_parent)) {
                    state = "returning";
                    target = noone;
                    show_debug_message("COP: Lost player, returning to car");
                } else {
                    state = "roaming";
                    target = noone;
                }
            }
        }

        // Time out the chase and return to car if linked
        if (car_parent != noone && chase_timer >= chase_timeout) {
            state = "returning";
            target = noone;
        }
    }
}

// Return-to-car behavior after failed chase
if (state == "returning") {
    chase_timer = 0;

    if (car_parent == noone || !instance_exists(car_parent)) {
        instance_destroy();
        exit;
    }

    var _dir_back = point_direction(x, y, car_parent.x, car_parent.y);
    var _ret_spd = chase_speed;
    var _rx = lengthdir_x(_ret_spd, _dir_back);
    var _ry = lengthdir_y(_ret_spd, _dir_back);

    x += _rx;
    y += _ry;
    facing = (_rx >= 0) ? 1 : -1;

    // Arrived at car: release car and despawn
    if (point_distance(x, y, car_parent.x, car_parent.y) <= 16) {
        show_debug_message("COP: Reached car, getting back in - car will drive off");
        with (car_parent) {
            has_target = false; // Let the cop car drive off
            block_cop_spawned = false; // Reset so car can spawn cop again if blocked
        }
        instance_destroy();
        exit;
    }

    // Clamp on screen and show running sprite while returning
    x = clamp(x, 32, room_width - 32);
    y = clamp(y, 32, room_height - 32);
    sprite_index = (facing == 1) ? spr_run_right : spr_run_left;
    exit;
}

// Check if player is within arrest range
if (_player != noone && _dist != -1 && _dist <= arrest_range) {
    var _player_ref = _player;
    show_debug_message("COP: Arresting player! Distance was: " + string(_dist));

    // Send player directly to jail
    _player_ref.is_jailed = true;

    // Confiscate all drugs
    _player_ref.inventory_weed = 0;
    _player_ref.inventory_cocaine = 0;
    _player_ref.inventory_heroin = 0;
    _player_ref.inventory_meth = 0;
    _player_ref.inventory_pills = 0;

    // Give player commissary food when entering jail (1-3 items)
    _player_ref.commissary_food = irandom_range(1, 3);

    // Update game controller
    if (instance_exists(obj_game_controller)) {
        obj_game_controller.jailed_player = _player_ref;
        obj_game_controller.jailed_player_scan_needed = false;
        obj_game_controller.game_state = GAME_STATE.JAIL;
    }

    // Teleport player to jail lobby
    room_goto(rm_jail_lobby);
    with (_player_ref) {
        x = 400;
        y = 500;
    }
    exit;
}

// Decide movement based on state
var _move_x = 0;
var _move_y = 0;

if (state == "chasing" && target != noone && instance_exists(target)) {
    var _dir = point_direction(x, y, target.x, target.y);
    _move_x = lengthdir_x(chase_speed, _dir);
    _move_y = lengthdir_y(chase_speed, _dir);
    facing = (_move_x >= 0) ? 1 : -1;
} else {
    // Roaming behavior
    roam_timer++;
    if (roam_timer >= roam_change_time) {
        roam_timer = 0;
        roam_dir_x = choose(-1, 0, 1);
        roam_dir_y = choose(-1, 0, 1);
        roam_change_time = irandom_range(60, 180);
    }

    _move_x = roam_dir_x * move_speed;
    _move_y = roam_dir_y * move_speed;

    // Update facing direction based on movement
    if (roam_dir_x != 0) {
        facing = roam_dir_x;
    }
}

// Apply movement
x += _move_x;
y += _move_y;

// Keep cop on screen
x = clamp(x, 32, room_width - 32);
y = clamp(y, 32, room_height - 32);

// Set sprite based on movement and facing
var _moving = (_move_x != 0 || _move_y != 0);
if (_moving) {
    sprite_index = (facing == 1) ? spr_run_right : spr_run_left;
} else {
    sprite_index = (facing == 1) ? spr_idle_right : spr_idle_left;
}
