/// obj_dice_game - Step Event

// === DECREMENT TIMERS ===
if (message_timer > 0) message_timer--;
if (victory_timer > 0) victory_timer--;

// === POLICE BUST SCHEDULING CHECK ===
if (room == Seattle && busts_today < max_busts_per_day) {
    var _current_time = obj_game_controller.time_current;
    var _day_length = obj_game_controller.day_length;
    var _time_progress = _current_time / _day_length;
    var _total_minutes = _time_progress * 1440;
    var _current_hour = floor(_total_minutes / 60) mod 24;

    // Check for 2am bust (guaranteed daily bust for testing)
    var _bust_at_2am = (_current_hour == 2);

    // Check for random bust
    var _random_bust = (_current_time >= next_bust_time && next_bust_time > 0);

    if ((_bust_at_2am || _random_bust) && ds_list_size(players_in_game) > 0 && dice_state != DICE_STATE.POLICE_WARNING && dice_state != DICE_STATE.BUSTED) {
        // Trigger bust warning
        dice_state = DICE_STATE.POLICE_WARNING;
        warning_timer = warning_duration;
        game_message = "!! POLICE INCOMING - RUN !!";
        busts_today++;

        // Schedule next random bust if still allowed today
        if (busts_today < max_busts_per_day) {
            var _remaining = _day_length - _current_time;
            var _offset = irandom_range(floor(_remaining * 0.1), floor(_remaining * 0.9));
            next_bust_time = _current_time + _offset;
        }
    }
}

// === DAY ROLLOVER RESET ===
if (obj_game_controller.time_current == 0) {
    busts_today = 0;
    // Schedule next bust
    var _day_length = obj_game_controller.day_length;
    var _remaining = _day_length;
    var _offset = irandom_range(floor(_remaining * 0.1), floor(_remaining * 0.9));
    next_bust_time = _offset;
}

// === PROXIMITY DETECTION ===
var _player = instance_nearest(x, y, player1);
show_prompt = false;

if (_player != noone && !_player.is_jailed) {
    var _dist = point_distance(x, y, _player.x, _player.y);

    if (_dist < join_range) {
        show_prompt = true;

        // Press E to join/interact with dice game
        if (keyboard_check_pressed(ord("E"))) {
            // Check if player is already in game
            var _in_game = ds_list_find_index(players_in_game, _player) != -1;

            if (!_in_game && ds_list_size(players_in_game) < max_players) {
                // Join the game
                ds_list_add(players_in_game, _player);

                // If first player, they become shooter
                if (ds_list_size(players_in_game) == 1) {
                    current_shooter = _player;
                    current_shooter_index = 0;
                    dice_state = DICE_STATE.WAITING_BETS;
                }

                game_message = "Joined the dice game!";
                message_timer = 120;
            }
        }
    }
}

// === HANDLE NPC JOINS ===
// Check for nearby NPCs who might want to join
if (ds_list_size(players_in_game) < max_players) {
    with (obj_npc_customer) {
        if (other.dice_state != DICE_STATE.BUSTED && other.dice_state != DICE_STATE.POLICE_WARNING) {
            var _npc_dist = point_distance(x, y, other.x, other.y);
            if (_npc_dist < other.join_range && random(1) < 0.002) { // Low chance per frame
                var _already_in = ds_list_find_index(other.players_in_game, id) != -1;
                if (!_already_in) {
                    ds_list_add(other.players_in_game, id);
                    if (ds_list_size(other.players_in_game) == 1) {
                        other.current_shooter = id;
                        other.current_shooter_index = 0;
                        other.dice_state = DICE_STATE.WAITING_BETS;
                    }
                }
            }
        }
    }
}

// === STATE MACHINE ===
switch (dice_state) {
    case DICE_STATE.IDLE:
        // Waiting for players to join
        break;

    case DICE_STATE.WAITING_BETS:
        // Handle bet placement (inline)
        // Verify current shooter still exists
        if (!instance_exists(current_shooter)) {
            // Current shooter was destroyed, find next valid player or reset
            current_shooter = noone;
            for (var j = 0; j < ds_list_size(players_in_game); j++) {
                var _potential = players_in_game[| j];
                if (instance_exists(_potential)) {
                    current_shooter = _potential;
                    current_shooter_index = j;
                    break;
                }
            }
            // If no valid players left, go back to idle
            if (current_shooter == noone) {
                dice_state = DICE_STATE.IDLE;
                break;
            }
        }

        // Check if current shooter has placed a bet
        var _shooter_has_bet = ds_map_exists(bets, current_shooter);

        // Only allow betting if we have players
        if (ds_list_size(players_in_game) > 0) {
            // Bet amounts for keys 1-9
            var _bet_amounts = [100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000];

            // Check number keys 1-9 for bet placement
            for (var i = 0; i < 9; i++) {
                if (keyboard_check_pressed(ord("1") + i)) {
                    var _bet = _bet_amounts[i];
                    var _player_money = current_shooter.money;

                    if (_player_money >= _bet) {
                        // Place bet
                        current_shooter.money -= _bet;
                        bets[? current_shooter] = _bet;
                        // Default to "pass" bet if not already set
                        if (!ds_map_exists(bet_types, current_shooter)) {
                            bet_types[? current_shooter] = "pass";
                        }
                        game_message = "Bet placed: $" + string(_bet) + " (Pass)";
                        message_timer = 60;
                        pot_total += _bet;

                        // Create ground money object to show bet visually
                        var _money_obj = instance_create_layer(x + irandom_range(-30, 30), y + irandom_range(-30, 30), "Instances", obj_ground_money);
                        _money_obj.amount = _bet;
                        _money_obj.visual_scale = 0.8 + (_bet / 10000); // Scale based on amount
                        ds_list_add(ground_money_objects, _money_obj);
                    } else {
                        game_message = "Not enough money!";
                        message_timer = 60;
                    }
                }
            }

            // Toggle Pass/Don't Pass with P/D keys
            if (keyboard_check_pressed(ord("P"))) {
                bet_types[? current_shooter] = "pass";
                game_message = "Pass bet selected";
                message_timer = 60;
            }
            if (keyboard_check_pressed(ord("D"))) {
                bet_types[? current_shooter] = "dont_pass";
                game_message = "Don't Pass bet selected";
                message_timer = 60;
            }

            // Roll dice when shooter presses SPACE and has placed a bet
            if (keyboard_check_pressed(vk_space) && _shooter_has_bet) {
                dice_state = DICE_STATE.ROLLING;
                is_rolling = true;
                roll_timer = roll_duration;
                dice_anim_frame = 0;
            }
        }
        break;

    case DICE_STATE.ROLLING:
        // Dice rolling animation
        roll_timer--;
        dice_anim_frame = (dice_anim_frame + 1) mod 6;

        if (roll_timer <= 0) {
            is_rolling = false;

            // Roll the dice
            die1 = irandom_range(1, 6);
            die2 = irandom_range(1, 6);
            dice_total = die1 + die2;

            // Determine outcome based on phase
            if (point_value == 0) {
                // COME OUT ROLL
                game_message = "Rolled: " + string(dice_total);
                message_timer = 120;

                if (dice_total == 7 || dice_total == 11) {
                    // Natural - shooter wins!
                    game_message = "NATURAL! Shooter wins!";
                    dice_state = DICE_STATE.PAYOUT;
                } else if (dice_total == 2 || dice_total == 3 || dice_total == 12) {
                    // Craps - shooter loses
                    game_message = "CRAPS! Shooter loses!";
                    dice_state = DICE_STATE.PAYOUT;
                } else {
                    // Point established
                    point_value = dice_total;
                    game_message = "Point: " + string(point_value);
                    dice_state = DICE_STATE.WAITING_BETS;
                }
            } else {
                // POINT PHASE ROLL
                game_message = "Rolled: " + string(dice_total);
                message_timer = 120;

                if (dice_total == point_value) {
                    // Hit the point - shooter wins!
                    game_message = "Made the point! Shooter wins!";
                    dice_state = DICE_STATE.PAYOUT;
                } else if (dice_total == 7) {
                    // Seven out - shooter loses
                    game_message = "Seven out! Shooter loses!";
                    dice_state = DICE_STATE.PAYOUT;
                } else {
                    // Roll again
                    game_message = "Rolling again...";
                    dice_state = DICE_STATE.WAITING_BETS;
                }
            }
        }
        break;

    case DICE_STATE.COME_OUT:
    case DICE_STATE.POINT_PHASE:
        // Already processed in ROLLING state, transition handled there
        break;

    case DICE_STATE.PAYOUT:
        // Distribute winnings (inline)
        var _shooter_won = false;

        // Determine if shooter won based on what triggered payout
        if (point_value == 0) {
            // Come out roll - shooter won on 7 or 11
            if (dice_total == 7 || dice_total == 11) {
                _shooter_won = true;
            }
        } else {
            // Point phase - shooter won by hitting point
            if (dice_total == point_value) {
                _shooter_won = true;
            }
        }

        // Clear all ground money (pick it up)
        for (var i = 0; i < ds_list_size(ground_money_objects); i++) {
            var _money = ground_money_objects[| i];
            if (instance_exists(_money)) {
                instance_destroy(_money);
            }
        }
        ds_list_clear(ground_money_objects);

        // Pay out winnings
        for (var i = 0; i < ds_list_size(players_in_game); i++) {
            var _p = players_in_game[| i];
            if (instance_exists(_p) && ds_map_exists(bets, _p)) {
                var _bet_amount = bets[? _p];
                var _bet_type = bet_types[? _p];

                // Determine if this player won
                var _player_won = false;
                if (_bet_type == "pass") {
                    _player_won = _shooter_won;
                } else if (_bet_type == "dont_pass") {
                    _player_won = !_shooter_won;
                }

                // Pay out 1:1 if won, lose bet if lost
                if (_player_won) {
                    var _payout = _bet_amount * 2; // Return original bet + winnings
                    _p.money += _payout;

                    // If player1 won, show victory speech bubble
                    if (_p.object_index == player1) {
                        victory_message = victory_phrases[irandom(array_length(victory_phrases) - 1)];
                        victory_timer = 120; // Show for 2 seconds
                    }
                }

                // Clear this player's bet
                ds_map_delete(bets, _p);
                ds_map_delete(bet_types, _p);
            }
        }

        // Reset for next round
        point_value = 0;
        pot_total = 0;
        dice_state = DICE_STATE.WAITING_BETS;
        game_message = "Next round ready!";
        message_timer = 120;
        break;

    case DICE_STATE.POLICE_WARNING:
        warning_timer--;

        // Players can escape during warning
        // Remove players who have moved far enough away
        for (var i = ds_list_size(players_in_game) - 1; i >= 0; i--) {
            var _p = players_in_game[| i];
            if (instance_exists(_p)) {
                var _escape_dist = point_distance(x, y, _p.x, _p.y);
                if (_escape_dist > 200) {
                    // Player escaped!
                    ds_list_delete(players_in_game, i);
                    // Refund their bet if any
                    if (ds_map_exists(bets, _p)) {
                        _p.money += bets[? _p];
                        ds_map_delete(bets, _p);
                        ds_map_delete(bet_types, _p);
                    }
                }
            }
        }

        if (warning_timer <= 0) {
            dice_state = DICE_STATE.BUSTED;
            // Execute police bust (TODO: implement inline)
            // scr_dice_police_bust();
        }
        break;

    case DICE_STATE.BUSTED:
        // Find and arrest player1 if still in game
        for (var i = ds_list_size(players_in_game) - 1; i >= 0; i--) {
            var _p = players_in_game[| i];
            if (instance_exists(_p) && _p.object_index == player1) {
                // Send player1 to jail for gambling (1 week sentence) - use real seconds
                _p.is_jailed = true;

                // Give player commissary food when entering jail
                _p.commissary_food = irandom_range(1, 3);

                // Confiscate any bet they had placed (lost to police)
                if (ds_map_exists(bets, _p)) {
                    ds_map_delete(bets, _p);
                    ds_map_delete(bet_types, _p);
                }

                // Update game controller for jail state
                if (instance_exists(obj_game_controller)) {
                    obj_game_controller.jailed_player = _p;
                    obj_game_controller.jailed_player_scan_needed = false; // Don't need to scan, we just set it
                    obj_game_controller.confiscated_money = 0;
                    obj_game_controller.game_state = GAME_STATE.JAIL;
                    obj_game_controller.last_real_time = get_timer();
                    show_debug_message("obj_game_controller: jailed_player set in obj_dice_game -> " + string(_p));
                }

                // Teleport player to jail lobby
                room_goto(rm_jail_lobby);
                with (_p) {
                    x = 400;
                    y = 500;
                }

                ds_list_delete(players_in_game, i);
                break;
            }
        }

        // Reset game state after bust
        dice_state = DICE_STATE.IDLE;
        point_value = 0;
        pot_total = 0;

        // Clear remaining players and bets
        ds_list_clear(players_in_game);
        ds_map_clear(bets);
        ds_map_clear(bet_types);

        // Clear ground money
        for (var i = 0; i < ds_list_size(ground_money_objects); i++) {
            var _money = ground_money_objects[| i];
            if (instance_exists(_money)) {
                instance_destroy(_money);
            }
        }
        ds_list_clear(ground_money_objects);

        game_message = "Dice game busted by police!";
        message_timer = 180;
        break;
}

// === LEAVE GAME (ESC) ===
if (_player != noone && ds_list_find_index(players_in_game, _player) != -1) {
    if (keyboard_check_pressed(vk_escape)) {
        // Leave the game, forfeit bet
        var _idx = ds_list_find_index(players_in_game, _player);
        if (_idx != -1) {
            ds_list_delete(players_in_game, _idx);
            ds_map_delete(bets, _player);
            ds_map_delete(bet_types, _player);
        }

        // If shooter left, advance to next
        if (current_shooter == _player) {
            // Advance to next shooter (TODO: implement inline)
            // scr_dice_next_shooter();
        }
    }
}

// === ROBBERY DETECTION ===
// Check if an armed player is threatening
if (_player != noone && _player.has_gun && dice_state != DICE_STATE.BUSTED) {
    var _dist = point_distance(x, y, _player.x, _player.y);
    if (_dist < interaction_range) {
        if (keyboard_check_pressed(ord("R"))) {
            // Rob the dice game (TODO: implement inline)
            // scr_dice_robbery(_player);
        }
    }
}
