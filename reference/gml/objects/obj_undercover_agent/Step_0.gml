chase_timer--;
if (chase_timer <= 0) {
    instance_destroy();
    exit;
}

if (target == noone || !instance_exists(target) || target.is_jailed) {
    target = instance_nearest(x, y, player1);
    if (target != noone && target.is_jailed) {
        target = noone;
    }
}

if (target != noone && instance_exists(target)) {
    var _old_x = x;
    var _old_y = y;
    var _dir = point_direction(x, y, target.x, target.y);

    x += lengthdir_x(move_speed, _dir);
    y += lengthdir_y(move_speed, _dir);

    // Check collision with other moving objects (except target players)
    // Don't check for player collision - we need to reach them for arrests
    var _collision = instance_place(x, y, obj_npc_customer) ||
                     instance_place(x, y, obj_cop);

    if (_collision) {
        x = _old_x;
        y = _old_y;
    }

    if (place_meeting(x, y, target)) {
        scr_arrest_player(target);
        instance_destroy();
    }
}

// === DEPTH SORTING ===
depth = -y;
