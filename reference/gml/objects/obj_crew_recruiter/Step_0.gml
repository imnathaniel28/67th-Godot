// === DEPTH SORTING ===
depth = -y;

// === FIND TARGET PLAYER ===
if (target_player == noone || !instance_exists(target_player)) {
    target_player = instance_nearest(x, y, player1);
}

// === STATE MACHINE ===
switch (state) {
    case "approaching":
        if (target_player != noone && instance_exists(target_player)) {
            // Move toward player
            var _dist = point_distance(x, y, target_player.x, target_player.y);

            if (_dist > 50) {
                // Still approaching
                var _dir = point_direction(x, y, target_player.x, target_player.y);
                var _old_x = x;
                var _old_y = y;

                x += lengthdir_x(move_speed, _dir);
                y += lengthdir_y(move_speed, _dir);

                // Update facing direction
                var _hor = x - _old_x;
                var _ver = y - _old_y;
                if (abs(_hor) > abs(_ver)) {
                    facing = (_hor > 0) ? "right" : "left";
                } else if (abs(_ver) > 0.1) {
                    facing = (_ver > 0) ? "down" : "up";
                }
            } else {
                // Close enough - start talking
                state = "talking";
            }
        }
        break;

    case "talking":
        // Transition to waiting state immediately
        state = "waiting";
        show_debug_message("DEBUG: Recruiter state changed to WAITING - ready for input");

        // Face player
        if (target_player != noone && instance_exists(target_player)) {
            var _dir = point_direction(x, y, target_player.x, target_player.y);
            if (_dir >= 315 || _dir < 45) facing = "right";
            else if (_dir >= 45 && _dir < 135) facing = "down";
            else if (_dir >= 135 && _dir < 225) facing = "left";
            else facing = "up";
        }
        break;

    case "waiting":
        // Waiting for player response - keep facing player
        if (target_player != noone && instance_exists(target_player)) {
            var _dir = point_direction(x, y, target_player.x, target_player.y);
            if (_dir >= 315 || _dir < 45) facing = "right";
            else if (_dir >= 45 && _dir < 135) facing = "down";
            else if (_dir >= 135 && _dir < 225) facing = "left";
            else facing = "up";
        }
        break;

    case "leaving":
        // Walk away off-screen in a straight line
        x += lengthdir_x(move_speed * 1.5, leave_direction);
        y += lengthdir_y(move_speed * 1.5, leave_direction);

        // Destroy when off-screen
        if (x < -100 || x > room_width + 100 || y < -100 || y > room_height + 100) {
            instance_destroy();
        }
        break;
}

// === UPDATE SPRITE ===
var _moving = (state == "approaching" || state == "leaving");
switch (facing) {
    case "down":  sprite_index = _moving ? spr_player_walk_down : spr_player_idle_down; break;
    case "up":    sprite_index = _moving ? spr_player_walk_up : spr_player_idle_up; break;
    case "left":  sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
    case "right": sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
}
