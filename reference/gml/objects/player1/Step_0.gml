// === HEALTH CHECK (DEATH) ===
if (health <= 0 && !is_jailed) {
    // Player died - respawn at default location
    health = max_health;
    x = 600;
    y = 500;

    // Penalties for dying
    money = max(0, money - 50); // Lose $50 (but can't go below 0)

    // Optional: lose some inventory
    inventory_weed = floor(inventory_weed * 0.5);
    inventory_cocaine = floor(inventory_cocaine * 0.5);
    inventory_heroin = floor(inventory_heroin * 0.5);
    inventory_meth = floor(inventory_meth * 0.5);
    inventory_pills = floor(inventory_pills * 0.5);

    show_debug_message("Player died and respawned!");
}

// === JAIL MELEE PERMADEATH CHECK ===
if (is_jailed && health <= -100) {
    // PERMADEATH - Complete reset
    show_debug_message("PERMADEATH! Player starts from scratch!");

    // Reset all stats
    health = max_health;
    money = 0;
    debt = 0;

    // Reset all inventory
    inventory_weed = 0;
    inventory_cocaine = 0;
    inventory_heroin = 0;
    inventory_meth = 0;
    inventory_pills = 0;

    // Reset territory
    has_territory = false;
    territory_x = -1;
    territory_y = -1;
    territory_name = "";

    // Reset jail/snitch status
    is_jailed = false;
    is_snitch = false;
    snitch_timer = 0;
    snitch_level = 0;
    is_stunned = false;

    // Respawn in main world
    room_goto(Seattle);
    x = 600;
    y = 500;
}

// === BLEED OUT SYSTEM ===
// If bleeding, player loses health continuously until they reach a hospital or die
if (is_bleeding && !is_jailed && !in_duel) {
    health -= bleed_rate;
    bleed_flash_timer++;
    
    // Periodic warnings
    if (bleed_flash_timer mod 180 == 0) {
        scr_notify("You're bleeding out! Find a hospital!", c_red);
    }
}

// === HEALTH REGENERATION ===
// No regen while bleeding - must reach hospital
if (health < max_health && !in_duel && !is_jailed && !is_bleeding) {
    health_regen_timer++;
    if (health_regen_timer >= health_regen_delay) {
        health = min(health + health_regen_rate, max_health);
        health_regen_timer = 0;
    }
} else {
    health_regen_timer = 0; // Reset timer if at full health or bleeding
}

// === STUNNED HEALTH REGENERATION (JAIL ONLY) ===
if (is_jailed && is_stunned) {
    stunned_regen_timer++;
    if (stunned_regen_timer >= 30) { // Every 0.5 seconds
        health = min(health + stunned_regen_rate, max_health);
        stunned_regen_timer = 0;

        // Wake up when fully healed
        if (health >= max_health) {
            is_stunned = false;
            show_debug_message("Player recovered from stun!");
        }
    }
}

// === HEAT DECAY ===
if (heat_level > 0 && !is_jailed) {
    var _hour_frames = game_ctrl.day_length / 24;
    heat_decay_timer++;
    if (heat_decay_timer >= _hour_frames) {
        heat_decay_timer = 0;
        // Only decay if no crime committed recently (last 2 in-game hours)
        if (game_ctrl.time_current - last_crime_time > _hour_frames * 2) {
            heat_level = max(0, heat_level - 1);
        }
    }
}

// === DUEL MODE ===
if (in_duel) {
    var _hor = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var _ver = keyboard_check(ord("S")) - keyboard_check(ord("W"));

    x += _hor * (move_speed * 2);
    y += _ver * (move_speed * 2);

    x = clamp(x, room_width/2 - 200, room_width/2 + 200);
    y = clamp(y, room_height/2 - 150, room_height/2 + 150);

    if (shoot_cooldown > 0) shoot_cooldown--;

    if ((keyboard_check_pressed(vk_space) || mouse_check_button_pressed(mb_left)) && shoot_cooldown <= 0) {
        shoot_cooldown = shoot_cooldown_max;

        if (weapon_type == 0) {
            // Fists: Melee attack - only hits if close enough
            var _dist = point_distance(x, y, duel_opponent.x, duel_opponent.y);
            if (_dist <= duel_attack_range) {
                duel_opponent.duel_health -= duel_damage;
            }
        } else if (weapon_type == 2) {
            // SMG: 3-round burst with spread
            for (var _b = 0; _b < 3; _b++) {
                var _bullet = instance_create_layer(x, y, "Instances", obj_duel_bullet);
                _bullet.owner = self;
                _bullet.target = duel_opponent;
                var _base_dir = point_direction(x, y, duel_opponent.x, duel_opponent.y);
                _bullet.direction = _base_dir + random_range(-8, 8);
                _bullet.speed = 8;
                _bullet.damage = duel_damage;
                _bullet.max_range = duel_attack_range;
            }
        } else if (weapon_type == 3) {
            // Shotgun: 5 pellets in wide spread, limited range
            for (var _b = 0; _b < 5; _b++) {
                var _bullet = instance_create_layer(x, y, "Instances", obj_duel_bullet);
                _bullet.owner = self;
                _bullet.target = duel_opponent;
                var _base_dir = point_direction(x, y, duel_opponent.x, duel_opponent.y);
                _bullet.direction = _base_dir + random_range(-15, 15);
                _bullet.speed = 7;
                _bullet.damage = duel_damage;
                _bullet.max_range = duel_attack_range;
            }
        } else {
            // Pistol: Single accurate shot
            var _bullet = instance_create_layer(x, y, "Instances", obj_duel_bullet);
            _bullet.owner = self;
            _bullet.target = duel_opponent;
            _bullet.direction = point_direction(x, y, duel_opponent.x, duel_opponent.y);
            _bullet.speed = 8;
            _bullet.damage = duel_damage;
            _bullet.max_range = duel_attack_range;
        }
    }

    if (duel_health <= 0) {
        scr_end_duel(duel_opponent, self);
    }

    exit;
}

// === STREET COMBAT (NON-DUEL SHOOTING) ===
// Player can shoot in the overworld if they have a gun drawn (press [P] first)
if (!is_jailed && has_gun && weapon_drawn && !phone_active && !typing_active) {
    if (shoot_cooldown > 0) shoot_cooldown--;

    if ((keyboard_check_pressed(vk_space) || mouse_check_button_pressed(mb_left)) && shoot_cooldown <= 0) {
        shoot_cooldown = shoot_cooldown_max;

        // Auto-aim at closest rival dealer within range
        var _target_rival = noone;
        var _closest_dist = 999999;
        var _auto_aim_range = 300; // Max range for auto-aim

        with (obj_rival_dealer) {
            var _dist = point_distance(other.x, other.y, x, y);
            if (_dist < _closest_dist && _dist <= _auto_aim_range && state != "leaving") {
                _closest_dist = _dist;
                _target_rival = id;
            }
        }

        // Direction based on auto-aim or facing
        var _shoot_dir;
        if (_target_rival != noone) {
            // Auto-aim at rival
            _shoot_dir = point_direction(x, y, _target_rival.x, _target_rival.y);
        } else {
            // Fall back to facing direction (cardinal + diagonal)
            switch (facing) {
                case "up":         _shoot_dir = 90;  break;
                case "down":       _shoot_dir = 270; break;
                case "left":       _shoot_dir = 180; break;
                case "right":      _shoot_dir = 0;   break;
                case "up_right":   _shoot_dir = 45;  break;
                case "up_left":    _shoot_dir = 135; break;
                case "down_right": _shoot_dir = 315; break;
                case "down_left":  _shoot_dir = 225; break;
            }
        }

        if (weapon_type == 0) {
            // Fists: No ranged attack in street combat
        } else if (weapon_type == 2) {
            // SMG: 3-round burst with spread
            for (var _b = 0; _b < 3; _b++) {
                var _bullet = instance_create_layer(x, y, "Instances", obj_street_bullet);
                _bullet.owner = id;
                _bullet.base_damage = duel_damage;
                _bullet.direction = _shoot_dir + random_range(-8, 8);
                _bullet.speed = 8;
                _bullet.max_range = duel_attack_range;
                _bullet.bullet_color = c_yellow;
                _bullet.start_x = x;
                _bullet.start_y = y;
            }
            heat_level = min(100, heat_level + 5);
            last_crime_time = game_ctrl.time_current;
            scr_trigger_gunshot_panic(x, y);
        } else if (weapon_type == 3) {
            // Shotgun: 5 pellets in wide spread, limited range
            for (var _b = 0; _b < 5; _b++) {
                var _bullet = instance_create_layer(x, y, "Instances", obj_street_bullet);
                _bullet.owner = id;
                _bullet.base_damage = duel_damage;
                _bullet.direction = _shoot_dir + random_range(-15, 15);
                _bullet.speed = 7;
                _bullet.max_range = duel_attack_range;
                _bullet.bullet_color = c_yellow;
                _bullet.start_x = x;
                _bullet.start_y = y;
            }
            heat_level = min(100, heat_level + 5);
            last_crime_time = game_ctrl.time_current;
            scr_trigger_gunshot_panic(x, y);
        } else {
            // Pistol: Single accurate shot
            var _bullet = instance_create_layer(x, y, "Instances", obj_street_bullet);
            _bullet.owner = id;
            _bullet.base_damage = duel_damage;
            _bullet.direction = _shoot_dir;
            _bullet.speed = 8;
            _bullet.max_range = duel_attack_range;
            _bullet.bullet_color = c_yellow;
            _bullet.start_x = x;
            _bullet.start_y = y;
            heat_level = min(100, heat_level + 5);
            last_crime_time = game_ctrl.time_current;
            scr_trigger_gunshot_panic(x, y);
        }
    }
}

// === JAIL CHECK ===
if (is_jailed) {

    // === JAIL MELEE COMBAT ===
    if (room == rm_jail_lobby) {
        // Check for stun state based on health
        if (health <= 5 && !is_stunned) {
            is_stunned = true;
            show_debug_message("Player stunned! Fallen to the ground!");
        }

        // Melee cooldown
        if (melee_cooldown > 0) melee_cooldown--;

        // Melee attack - F key, only if not stunned
        if (!is_stunned && keyboard_check_pressed(ord("F")) && melee_cooldown <= 0) {
            melee_cooldown = melee_cooldown_max;

            // Find all players within range and damage them
            var _hit_count = 0;
            with (player1) {
                if (id != other.id) { // Don't hit self
                    var _dist = point_distance(x, y, other.x, other.y);
                    if (_dist <= other.melee_attack_range) {
                        // Deal damage
                        health -= other.melee_damage;
                        _hit_count++;
                        show_debug_message("Player hit for " + string(other.melee_damage) + " damage! Health: " + string(health));

                        // Check if this hit causes stun
                        if (health <= 5 && health > -100) {
                            is_stunned = true;
                            show_debug_message("Player knocked down!");
                        }
                    }
                }
            }

            // Also check FakePlayer1 instances
            with (FakePlayer1) {
                var _dist = point_distance(x, y, other.x, other.y);
                if (_dist <= other.melee_attack_range) {
                    health -= other.melee_damage;
                    _hit_count++;
                    show_debug_message("FakePlayer hit for " + string(other.melee_damage) + " damage! Health: " + string(health));
                }
            }

            if (_hit_count > 0) {
                show_debug_message("Melee attack hit " + string(_hit_count) + " target(s)!");
            } else {
                show_debug_message("Melee attack missed!");
            }
        }

        // Stunned players can't move - exit early if stunned
        if (is_stunned) {
            exit;
        }
    }

    // Timer countdown continues, but exit is handled centrally by obj_game_controller
    // Player must walk to exit door when timer reaches 0 (only if not stunned)
    exit;
}

// === SNITCH TIMER ===
if (is_snitch) {
    snitch_timer--;
    if (snitch_timer <= 0) {
        is_snitch = false;
        snitch_level = 0;
        snitch_level_timer = 0;
    }

    // Progress through snitch levels (reputation improves over time)
    if (snitch_level < 3) {
        snitch_level_timer++;
        if (snitch_level_timer >= snitch_level_duration) {
            snitch_level++;
            snitch_level_timer = 0;
        }
    }
}

// === COP STUN ESCAPE COMBO ===
if (!is_jailed && !in_duel) {
    // Safety: ensure buffers/timers exist (covers legacy saves)
    if (!is_array(stun_input_buffer)) stun_input_buffer = [];
    if (!is_real(stun_input_timer)) stun_input_timer = 0;
    if (!is_real(stun_combo_cooldown)) stun_combo_cooldown = 0;

    stun_input_timer++;
    if (stun_combo_cooldown > 0) stun_combo_cooldown--;

    // Capture rapid directional presses (arrow keys or WASD)
    var _pressed_dir = "";
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        _pressed_dir = "up";
    } else if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        _pressed_dir = "down";
    } else if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
        _pressed_dir = "left";
    } else if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
        _pressed_dir = "right";
    }

    if (_pressed_dir != "") {
        array_push(stun_input_buffer, { dir: _pressed_dir, t: stun_input_timer });
    }

    // Remove stale inputs outside the window
    while (array_length(stun_input_buffer) > 0 && stun_input_timer - stun_input_buffer[0].t > stun_combo_window) {
        stun_input_buffer = array_delete(stun_input_buffer, 0, 1);
    }

    // Check for the required 3-key patterns within the window
    var _combo_ready = false;
    if (array_length(stun_input_buffer) >= 3 && stun_combo_cooldown <= 0) {
        var _len = array_length(stun_input_buffer);
        var _a = stun_input_buffer[_len - 3];
        var _b = stun_input_buffer[_len - 2];
        var _c = stun_input_buffer[_len - 1];

        var _span = _c.t - _a.t;
        if (_span <= stun_combo_window) {
            _combo_ready = (
                (_a.dir == "up" && _b.dir == "down" && _c.dir == "up") ||
                (_a.dir == "down" && _b.dir == "up" && _c.dir == "down") ||
                (_a.dir == "left" && _b.dir == "right" && _c.dir == "left") ||
                (_a.dir == "right" && _b.dir == "left" && _c.dir == "right")
            );
        }
    }

    if (_combo_ready) {
        var _stun_target = noone;
        var _nearest = stun_escape_range;

        // Find the closest cop that is actively chasing this player
        var _cop_count = instance_number(obj_cop);
        for (var _i = 0; _i < _cop_count; _i++) {
            var _cop = instance_find(obj_cop, _i);
            if (_cop.state == "chasing" && _cop.stunned_timer <= 0 && _cop.target == id) {
                var _d = point_distance(x, y, _cop.x, _cop.y);
                if (_d < _nearest) {
                    _nearest = _d;
                    _stun_target = _cop;
                }
            }
        }

        if (_stun_target != noone) {
            with (_stun_target) {
                stunned_timer = 90; // 1.5 seconds of stun
                state = "stunned";
                target = noone;
            }

            stun_combo_cooldown = stun_combo_window;
            stun_input_buffer = [];
            show_debug_message("Player stunned a chasing cop!");
        }
    }
}

// === MINIMAP TOGGLE ===
if (keyboard_check_pressed(ord("M")) && !is_jailed && !in_duel) {
    minimap_visible = !minimap_visible;
}

// === SALES MODE INPUT ===
// Keys [1][2][3] or left-click on the checkboxes
if (!is_jailed && !in_duel) {
    if (keyboard_check_pressed(ord("1"))) auto_sale_mode = 0; // Yes
    if (keyboard_check_pressed(ord("2"))) auto_sale_mode = 1; // Homie
    if (keyboard_check_pressed(ord("3"))) auto_sale_mode = 2; // No

    // Mouse click on checkboxes (GUI space)
    if (mouse_check_button_pressed(mb_left)) {
        var _mx = device_mouse_x_to_gui(0);
        var _my = device_mouse_y_to_gui(0);
        var _cb_y = 58;
        var _cb_size = 10;
        var _cb_positions = [72, 115, 170];
        for (var _s = 0; _s < 3; _s++) {
            var _bx = _cb_positions[_s];
            if (_mx >= _bx && _mx <= _bx + _cb_size + 30 && _my >= _cb_y - 2 && _my <= _cb_y + _cb_size + 2) {
                auto_sale_mode = _s;
                break;
            }
        }
    }
}

// === WEAPON DRAW / CYCLE [P] ===
if (keyboard_check_pressed(ord("P")) && !is_jailed && !in_duel && !phone_active) {
    // Build list of owned guns (skip fists at index 0)
    var _owned_guns = [];
    for (var _w = 1; _w <= 3; _w++) {
        if (weapons_owned[_w]) array_push(_owned_guns, _w);
    }

    if (array_length(_owned_guns) > 0) {
        if (!weapon_drawn) {
            // Draw first owned gun
            weapon_drawn = true;
            weapon_type = _owned_guns[0];
            has_gun = true;
        } else {
            // Find current weapon in owned list and cycle to next
            var _cur_idx = -1;
            for (var _w = 0; _w < array_length(_owned_guns); _w++) {
                if (_owned_guns[_w] == weapon_type) { _cur_idx = _w; break; }
            }
            var _next_idx = (_cur_idx + 1) % (array_length(_owned_guns) + 1); // +1 for holster slot
            if (_next_idx >= array_length(_owned_guns)) {
                // Holster weapon
                weapon_drawn = false;
                weapon_type = 0;
                has_gun = false;
                scr_notify("Weapon holstered", c_gray);
            } else {
                weapon_type = _owned_guns[_next_idx];
            }
        }

        // Update derived combat stats
        if (weapon_type > 0) {
            var _wep = weapon_stats[weapon_type];
            duel_damage = _wep.damage;
            duel_attack_range = _wep.range;
            shoot_cooldown_max = _wep.cooldown;
            scr_notify("Equipped: " + _wep.name, c_yellow);
        }
    } else {
        scr_notify("No weapons! Visit the Gun Store", c_red);
    }
}

// === PHONE INPUT ===
// Press O to toggle phone (only when not jailed, not in duel)
if (keyboard_check_pressed(ord("O")) && !phone_active && !is_jailed && !in_duel) {
    // Create phone controller if it doesn't exist
    var _phone = instance_find(obj_phone_controller, 0);
    if (_phone == noone) {
        _phone = instance_create_depth(0, 0, -10000, obj_phone_controller);
    }

    // Trigger phone opening animation
    if (_phone.phone_state == PHONE_STATE.CLOSED) {
        _phone.phone_state = PHONE_STATE.OPENING;
        _phone.calling_player = id;
        _phone.phone_scale_target = 1.0;
        _phone.phone_alpha_target = 1.0;
        phone_active = true;
    }
}

// === MOVEMENT ===
// Don't allow movement if typing in chat OR using phone
if ((typing_active && at_chat_table != noone) || phone_active) {
    var _hor = 0;
    var _ver = 0;
} else {
    var _hor = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var _ver = keyboard_check(ord("S")) - keyboard_check(ord("W"));
}

if (_hor != 0 || _ver != 0) {
    // Store old position
    var _old_x = x;
    var _old_y = y;

    // Try to move with tilemap collision
    move_and_collide(_hor * move_speed, _ver * move_speed, tilemap);

    // Check collision with other moving objects and buildings at new position
    // Don't check NPCs - they can overlap us to make sales
    var _collision = instance_place(x, y, FakePlayer1) ||
                     instance_place(x, y, obj_cop) ||
                     instance_place(x, y, obj_undercover_agent) ||
                     instance_place(x, y, obj_building_parent) ||
                     instance_place(x, y, obj_car);

    // If colliding with another moving object or building, revert position
    if (_collision) {
        x = _old_x;
        y = _old_y;
    }

    if (_hor != 0 && _ver != 0) {
        // Diagonal facing
        if (_hor > 0 && _ver < 0) facing = "up_right";
        else if (_hor < 0 && _ver < 0) facing = "up_left";
        else if (_hor > 0 && _ver > 0) facing = "down_right";
        else if (_hor < 0 && _ver > 0) facing = "down_left";
    } else if (_hor != 0) {
        facing = (_hor > 0) ? "right" : "left";
    } else {
        facing = (_ver > 0) ? "down" : "up";
    }
}

// === UPDATE SPRITE ===
var _moving = (_hor != 0 || _ver != 0);
switch (facing) {
    case "down":       sprite_index = _moving ? spr_player_walk_down : spr_player_idle_down; break;
    case "up":         sprite_index = _moving ? spr_player_walk_up : spr_player_idle_up; break;
    case "left":       sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
    case "right":      sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
    case "up_right":   sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
    case "up_left":    sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
    case "down_right": sprite_index = _moving ? spr_player_walk_L : spr_player_idle_L; break;
    case "down_left":  sprite_index = _moving ? spr_player_walk_R : spr_player_idle_R; break;
}

// === ROOM BOUNDARY CHECKS ===
// Prevent the player from walking outside certain room bounds
// For city rooms, allow seamless transitions at connecting edges

if (room == rm_jail_lobby) {
    var _padding = 48;
    x = clamp(x, _padding, room_width - _padding);
    y = clamp(y, _padding, room_height - _padding);
}

// === SEAMLESS CITY TRANSITIONS (via Highway Chain) ===
// Seattle → i5 → i5_2 → i5_3 → i5_4 → LA (and reverse)
var _edge_padding = 8; // How close to edge before transition triggers
var _boundary_padding = 48; // Normal boundary padding for non-exit edges

if (room == Seattle) {
    // Right edge → travel to i5
    if (x >= room_width - _edge_padding) {
        _seamless_city_travel(i5, _boundary_padding, y);
    } else {
        // Clamp other 3 edges normally
        x = clamp(x, _boundary_padding, room_width); // don't clamp right (exit edge)
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
} else if (room == i5) {
    // Right edge → travel to i5_2, Left edge → back to Seattle
    if (x >= room_width - _edge_padding) {
        _seamless_city_travel(i5_2, _boundary_padding, y);
    } else if (x <= _edge_padding) {
        _seamless_city_travel(Seattle, room_width - _boundary_padding, y);
    } else {
        x = clamp(x, 0, room_width); // Allow movement on both sides
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
} else if (room == i5_2) {
    // Right edge → travel to i5_3, Left edge → back to i5
    if (x >= room_width - _edge_padding) {
        _seamless_city_travel(i5_3, _boundary_padding, y);
    } else if (x <= _edge_padding) {
        _seamless_city_travel(i5, room_width - _boundary_padding, y);
    } else {
        x = clamp(x, 0, room_width); // Allow movement on both sides
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
} else if (room == i5_3) {
    // Right edge → travel to i5_4, Left edge → back to i5_2
    if (x >= room_width - _edge_padding) {
        _seamless_city_travel(i5_4, _boundary_padding, y);
    } else if (x <= _edge_padding) {
        _seamless_city_travel(i5_2, room_width - _boundary_padding, y);
    } else {
        x = clamp(x, 0, room_width); // Allow movement on both sides
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
} else if (room == i5_4) {
    // Right edge → travel to LA, Left edge → back to i5_3
    if (x >= room_width - _edge_padding) {
        _seamless_city_travel(LA, _boundary_padding, y);
    } else if (x <= _edge_padding) {
        _seamless_city_travel(i5_3, room_width - _boundary_padding, y);
    } else {
        x = clamp(x, 0, room_width); // Allow movement on both sides
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
} else if (room == LA) {
    // Left edge → travel back to i5_4
    if (x <= _edge_padding) {
        _seamless_city_travel(i5_4, room_width - _boundary_padding, y);
    } else {
        // Clamp other 3 edges normally
        x = clamp(x, 0, room_width - _boundary_padding); // don't clamp left (exit edge)
        y = clamp(y, _boundary_padding, room_height - _boundary_padding);
    }
}

// === DEPTH SORTING ===
// Objects with lower Y values (higher on screen) appear behind objects with higher Y values
depth = -y;

// === DANGER ZONE DETECTION ===
var _gc = game_ctrl;
in_danger_zone = (room == Seattle) && (y >= _gc.street_y_top - _gc.danger_zone_margin) &&
                 (y <= _gc.street_y_bottom + _gc.danger_zone_margin);

// === SELL COOLDOWN ===
if (sell_cooldown > 0) sell_cooldown--;

// === PVP COLLISION CHECK ===
if (game_ctrl.game_state == GAME_STATE.PLAYING) {
    var _other_player = instance_place(x, y, player1);
    if (_other_player != noone && _other_player != self) {
        if (!_other_player.is_jailed && !is_jailed) {
            scr_start_pvp_encounter(self, _other_player);
        }
    }
}

// === START PVP ENCOUNTER (Press T) ===
if (keyboard_check_pressed(ord("T")) && game_ctrl.game_state == GAME_STATE.PLAYING) {
    var _fake = instance_find(FakePlayer1, 0);
    if (_fake != noone && !_fake.in_duel) {
        scr_start_pvp_encounter(self, _fake);
    }
}

// === JAYWALKING DETECTION ===
// Nothing happens unless a cop car is within 300 pixels - then a cop spawns and heat increases
if (!is_jailed && _gc.game_state == GAME_STATE.PLAYING && room == Seattle) {
    var _in_street = (y >= _gc.street_y_top && y <= _gc.street_y_bottom);

    // Detect when player exits street on opposite side (completed crossing)
    if (was_in_street && !_in_street) {
        var _crossed_to_other_side = (abs(y - street_entry_y) > 50);

        if (_crossed_to_other_side) {
            // Check if player crossed within a crosswalk
            var _in_crosswalk = false;
            for (var i = 0; i < array_length(_gc.crosswalk_zones); i++) {
                var _zone = _gc.crosswalk_zones[i];
                if ((street_entry_x >= _zone.x_min && street_entry_x <= _zone.x_max) ||
                    (x >= _zone.x_min && x <= _zone.x_max)) {
                    _in_crosswalk = true;
                    break;
                }
            }

            // If not in crosswalk: check for nearby cop car
            if (!_in_crosswalk) {
                var _nearest_cop_car = noone;
                var _nearest_dist = 9999;

                with (obj_car) {
                    if (is_cop && !block_cop_spawned) {
                        var _dist = point_distance(x, y, other.x, other.y);
                        if (_dist < 300 && _dist < _nearest_dist) {
                            _nearest_cop_car = id;
                            _nearest_dist = _dist;
                        }
                    }
                }

                // Spawn cops from nearest cop car to chase player
                // At high heat, spawn 2 cops; otherwise spawn 1
                if (_nearest_cop_car != noone && instance_exists(_nearest_cop_car)) {
                    // Spawn 2 cops at high heat, 1 cop at low heat
                    var _cop_count = (heat_level > 50) ? 2 : 1;

                    for (var _i = 0; _i < _cop_count; _i++) {
                        var _spawned_cop = instance_create_layer(_nearest_cop_car.x + (_i * 30), _nearest_cop_car.y, "Instances", obj_cop);
                        if (_spawned_cop != noone && instance_exists(_spawned_cop)) {
                            _spawned_cop.state = "chasing";
                            _spawned_cop.target = id;
                            _spawned_cop.lost_sight_timer = _spawned_cop.chase_forget_time;
                            _spawned_cop.car_parent = _nearest_cop_car;

                            // Increase chase speed based on heat level
                            _spawned_cop.chase_speed = 1.1 + (heat_level / 200);
                        }
                    }
                    _nearest_cop_car.has_target = true;
                    _nearest_cop_car.block_cop_spawned = true;

                    // Add heat for jaywalking near cop
                    heat_level = min(100, heat_level + 10);
                    last_crime_time = game_ctrl.time_current;
                    scr_notify("Jaywalking near a cop!", c_orange);
                }
            }
        }
    }

    // Track when entering street
    if (_in_street && !was_in_street) {
        street_entry_y = y;
        street_entry_x = x;
    }

    was_in_street = _in_street;
}

// === CREW RECRUITMENT SYSTEM ===
// Unlock crew system at $100,000 milestone
if (!crew_unlocked && money >= 100000) {
    crew_unlocked = true;
    scr_notify("CREW SYSTEM UNLOCKED!", c_lime);
    scr_notify("Hire workers to sell for you", c_aqua);
}

// Spawn recruiters periodically after unlocking
if (crew_unlocked && !is_jailed && room == Seattle) {
    // Check if enough time has passed since last recruiter
    var _time_since_last = game_ctrl.time_current - last_recruitment_time;

    // Spawn worker recruiter if cooldown elapsed and not at max crew
    if (_time_since_last >= recruitment_cooldown && array_length(crew_members) < max_crew_size) {
        // Check if there's already a recruiter nearby
        var _existing_recruiter = instance_nearest(x, y, obj_crew_member);
        var _is_recruiting = false;
        if (_existing_recruiter != noone && instance_exists(_existing_recruiter) && !_existing_recruiter.is_hired) {
            _is_recruiting = true;
        }

        if (!_is_recruiting) {
            // Spawn worker in recruiting mode near player (but not too close)
            var _spawn_angle = random(360);
            var _spawn_dist = 200; // Spawn 200 pixels away

            var _spawn_x = x + lengthdir_x(_spawn_dist, _spawn_angle);
            var _spawn_y = y + lengthdir_y(_spawn_dist, _spawn_angle);

            // Clamp to room bounds
            _spawn_x = clamp(_spawn_x, 50, room_width - 50);
            _spawn_y = clamp(_spawn_y, 50, room_height - 50);

            var _worker = instance_create_layer(_spawn_x, _spawn_y, "Instances", obj_crew_member);
            _worker.target_player = id;
            _worker.is_hired = false;
            _worker.state = "recruiting_approach";

            last_recruitment_time = game_ctrl.time_current;
            show_debug_message(_worker.worker_name + " is approaching to ask for work...");
        }
    }
}

// === COLLECT CREW EARNINGS ===
// Press [C] near a crew member to collect their daily earnings
if (crew_unlocked && keyboard_check_pressed(ord("C")) && !is_jailed) {
    // Find nearest crew member
    var _nearest_worker = instance_nearest(x, y, obj_crew_member);

    if (_nearest_worker != noone && instance_exists(_nearest_worker)) {
        var _dist = point_distance(x, y, _nearest_worker.x, _nearest_worker.y);

        // Must be within 60 pixels and must be hired (not recruiting)
        if (_dist <= 60 && _nearest_worker.owner == id && _nearest_worker.is_hired) {
            if (_nearest_worker.daily_earnings > 0) {
                // Collect earnings
                money += _nearest_worker.daily_earnings;
                show_debug_message("Collected $" + string(_nearest_worker.daily_earnings) + " from " + _nearest_worker.worker_name);
                _nearest_worker.daily_earnings = 0; // Reset their daily counter
            } else {
                show_debug_message(_nearest_worker.worker_name + " has no earnings to collect yet.");
            }
        }
    }
}

// === DEBUG: MANUAL WORKER RECRUITER SPAWN ===
// Press [H] to instantly spawn a worker recruiter for testing (only when crew unlocked)
if (crew_unlocked && keyboard_check_pressed(ord("H")) && !is_jailed && room == Seattle) {
    // Check if recruiter already exists
    var _existing_recruiter = instance_nearest(x, y, obj_crew_member);
    var _is_recruiting = false;
    if (_existing_recruiter != noone && instance_exists(_existing_recruiter) && !_existing_recruiter.is_hired) {
        _is_recruiting = true;
    }

    if (!_is_recruiting) {
        // Spawn worker in recruiting mode near player
        var _spawn_angle = random(360);
        var _spawn_dist = 200;

        var _spawn_x = x + lengthdir_x(_spawn_dist, _spawn_angle);
        var _spawn_y = y + lengthdir_y(_spawn_dist, _spawn_angle);

        _spawn_x = clamp(_spawn_x, 50, room_width - 50);
        _spawn_y = clamp(_spawn_y, 50, room_height - 50);

        var _worker = instance_create_layer(_spawn_x, _spawn_y, "Instances", obj_crew_member);
        _worker.target_player = id;
        _worker.is_hired = false;
        _worker.state = "recruiting_approach";

        show_debug_message("DEBUG: Manually spawned worker recruiter with [H] key - " + _worker.worker_name);
    } else {
        show_debug_message("DEBUG: Worker recruiter already exists!");
    }
}

// === DEBUG: TEST BLEED OUT SYSTEM ===
// Press [B] to trigger driveby attack and test bleeding mechanics
if (keyboard_check_pressed(ord("B")) && !is_jailed && !in_duel) {
    scr_event_drive_by(id);
    show_debug_message("DEBUG: Triggered driveby with [B] key - Testing bleed out!");
}

// === DEBUG: SPAWN RIVAL DEALER ===
// Press [V] to spawn a rival dealer nearby
if (keyboard_check_pressed(ord("V")) && !is_jailed && !in_duel) {
    var _sx = x + choose(-100, 100);
    var _sy = y + random_range(-50, 50);
    _sx = clamp(_sx, 50, room_width - 50);
    _sy = clamp(_sy, 50, room_height - 50);
    var _rival = instance_create_layer(_sx, _sy, "Instances", obj_rival_dealer);
    show_debug_message("DEBUG: Spawned rival dealer at " + string(_sx) + ", " + string(_sy));
    scr_notify("Rival spawned nearby!", c_red);
}
