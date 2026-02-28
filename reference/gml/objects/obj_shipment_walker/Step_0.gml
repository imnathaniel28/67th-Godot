// === DEPTH SORTING (same as player) ===
depth = -y;

// === ROBBERY/INTERCEPT CHECK ===
if (can_be_robbed && !robbed && !arrived) {
    var _player = instance_nearest(x, y, player1);

    if (_player != noone) {
        var _dist = point_distance(x, y, _player.x, _player.y);

        // Player is close enough to see prompt
        if (_dist < 48) {
            // Show robbery prompt
            if (keyboard_check_pressed(ord("R"))) {
                // Attempt to rob the walker
                robbed = true;
                can_be_robbed = false;

                // Player gets the drugs
                if (instance_exists(_player)) {
                    // Add drugs to player inventory (assuming player has drug inventory)
                    // For now, convert to money value (simplified)
                    var _stolen_value = drug_amount * 50; // $50 per unit
                    _player.money += _stolen_value;

                    // Increase wanted level / heat
                    if (variable_instance_exists(_player, "heat_level")) {
                        _player.heat_level = min(100, _player.heat_level + 20);
                        _player.last_crime_time = game_ctrl.time_current;
                        scr_notify("Robbed courier! +$" + string(_stolen_value), c_lime);
                        if (_player.heat_level >= 50) {
                            scr_notify("HEAT rising! Cops are watching!", c_red);
                        }
                    }
                }

                // Walker runs away or disappears
                instance_destroy();
            }
        }
    }
}

// === MOVEMENT ===
if (!arrived && !robbed && instance_exists(destination)) {
    target_x = destination.x;
    target_y = destination.y;

    // Move toward target
    var dist = point_distance(x, y, target_x, target_y);
    if (dist > move_speed) {
        var dir = point_direction(x, y, target_x, target_y);
        x += lengthdir_x(move_speed, dir);
        y += lengthdir_y(move_speed, dir);
    } else {
        // Arrived at destination
        x = target_x;
        y = target_y;
        arrived = true;

        // Deliver drugs to destination
        if (instance_exists(destination) && !robbed) {
            if (variable_instance_exists(destination, "stash_amount")) {
                destination.stash_amount += drug_amount;
            }
        }

        // Destroy shipment after delivery
        instance_destroy();
    }
}
