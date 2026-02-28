depth = -y;

// Lifetime
lifetime--;
if (lifetime <= 0 || hp <= 0) {
    if (hp <= 0) {
        // Drop money on death
        var _p = instance_nearest(x, y, player1);
        if (_p != noone) {
            _p.money += money;
            scr_notify("Took $" + string(money) + " from " + rival_name + "!", c_lime);
            // Add heat for fighting
            _p.heat_level = min(100, _p.heat_level + 10);
            _p.last_crime_time = game_ctrl.time_current;
        }
    }
    instance_destroy();
    exit;
}

// Melee cooldown
if (melee_cooldown > 0) melee_cooldown--;

// === PLAYER INTERACTION ===
var _player = instance_nearest(x, y, player1);
var _player_dist = (_player != noone) ? point_distance(x, y, _player.x, _player.y) : 9999;

// Player can intimidate [E] when close (unarmed)
if (_player != noone && _player_dist < 48 && state != "fighting" && state != "leaving") {
    if (keyboard_check_pressed(ord("E")) && !_player.weapon_drawn) {
        // Intimidate only works when weapon is holstered
        state = "leaving";
        scr_notify(rival_name + " backed off!", c_yellow);
    }
}

// === WEAPON ALERT: Rival reacts to player drawing weapon ===
// If player draws weapon within alert range, rival goes into fight mode
var _alert_range = 300;
if (_player != noone && _player_dist < _alert_range && state != "fighting" && state != "leaving") {
    if (variable_instance_exists(_player, "weapon_drawn") && _player.weapon_drawn) {
        state = "fighting";
        fight_timer = 1800; // 30 second fight
        scr_notify(rival_name + ": \"You pullin' on me?!\"", c_red);
    }
}

// === STATE MACHINE ===
switch (state) {
    case "roaming":
        // Wander around
        if (wander_pause_timer > 0) {
            wander_pause_timer--;
        } else {
            if (wander_timer > 0) {
                x += lengthdir_x(move_speed, wander_direction);
                y += lengthdir_y(move_speed, wander_direction);
                wander_timer--;
            } else {
                wander_pause_timer = irandom_range(30, 90);
                wander_direction = random(360);
                wander_timer = irandom_range(60, 180);
            }
        }

        // Try to steal customers
        var _cust = instance_nearest(x, y, obj_npc_customer);
        if (_cust != noone && _cust.state == "wander") {
            var _cust_dist = point_distance(x, y, _cust.x, _cust.y);
            if (_cust_dist < 60 && random(1) < 0.005) {
                // 50% chance customer goes to rival instead
                if (random(1) < 0.5) {
                    state = "selling";
                    target_customer = _cust;
                    sell_timer = 180; // 3 second sale
                    _cust.state = "waiting";
                }
            }
        }
        break;

    case "selling":
        // Stand still while selling
        sell_timer--;
        if (sell_timer <= 0) {
            // Completed sale - earn money
            money += irandom_range(20, 50);
            if (target_customer != noone && instance_exists(target_customer)) {
                target_customer.state = "leave";
                target_customer.leave_direction = random(360);
                target_customer.leave_speed = random_range(1.5, 2.0);
            }
            state = "roaming";
            target_customer = noone;
        }
        break;

    case "fighting":
        fight_timer--;
        if (fight_timer <= 0 || hp <= 0) {
            if (hp > 0) {
                state = "leaving";
            }
            break;
        }

        // Gun cooldown
        if (gun_cooldown > 0) gun_cooldown--;

        // Fight movement: maintain distance + strafe
        if (_player != noone && !_player.is_jailed) {
            var _dir_to_player = point_direction(x, y, _player.x, _player.y);
            var _fight_dist = point_distance(x, y, _player.x, _player.y);

            // Strafe timer - change strafe direction periodically
            fight_move_timer--;
            if (fight_move_timer <= 0) {
                fight_move_timer = irandom_range(60, 120);
                fight_move_dir = _dir_to_player + choose(-90, 90);
            }

            // Distance management
            var _move_x = 0;
            var _move_y = 0;

            if (_fight_dist > preferred_fight_dist + 40) {
                // Too far - move toward player
                _move_x = lengthdir_x(move_speed * 1.2, _dir_to_player);
                _move_y = lengthdir_y(move_speed * 1.2, _dir_to_player);
            } else if (_fight_dist < preferred_fight_dist - 30) {
                // Too close - back away
                _move_x = lengthdir_x(move_speed * 1.5, _dir_to_player + 180);
                _move_y = lengthdir_y(move_speed * 1.5, _dir_to_player + 180);
            } else {
                // Good distance - strafe sideways
                _move_x = lengthdir_x(move_speed * 0.8, fight_move_dir);
                _move_y = lengthdir_y(move_speed * 0.8, fight_move_dir);
            }

            x += _move_x;
            y += _move_y;

            // Shoot at player
            if (gun_cooldown <= 0 && _fight_dist <= gun_range) {
                gun_cooldown = gun_cooldown_max;

                // Aim at player with inaccuracy
                var _aim_dir = _dir_to_player + random_range(-gun_accuracy, gun_accuracy);

                var _bullet = instance_create_layer(x, y, "Instances", obj_street_bullet);
                _bullet.owner = id;
                _bullet.base_damage = gun_damage;
                _bullet.direction = _aim_dir;
                _bullet.speed = 7;
                _bullet.max_range = gun_range;
                _bullet.bullet_color = c_red;
                _bullet.start_x = x;
                _bullet.start_y = y;

                scr_trigger_gunshot_panic(x, y);
            }
        }
        break;

    case "leaving":
        // Move away from player
        if (_player != noone) {
            var _away_dir = point_direction(_player.x, _player.y, x, y);
            x += lengthdir_x(move_speed * 2, _away_dir);
            y += lengthdir_y(move_speed * 2, _away_dir);
        }
        if (x < -50 || x > room_width + 50 || y < -50 || y > room_height + 50) {
            instance_destroy();
        }
        break;
}

// Keep on screen (except when leaving)
if (state != "leaving") {
    x = clamp(x, 32, room_width - 32);
    y = clamp(y, 32, room_height - 32);
}
