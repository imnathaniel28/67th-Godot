/// obj_dice_game - Draw GUI Event

// Only show UI if player is nearby or in game
var _player = instance_nearest(x, y, player1);
if (_player == noone) exit;

var _dist = point_distance(x, y, _player.x, _player.y);
var _in_game = ds_list_find_index(players_in_game, _player) != -1;

if (_dist > join_range && !_in_game) exit;

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _cx = _gui_w / 2;

// === PROMPT ===
if (show_prompt && !_in_game && dice_state != DICE_STATE.BUSTED) {
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(_cx, _gui_h - 60, "[E] Join Dice Game");
}

// === GAME UI (if in game) ===
if (_in_game) {
    // Background panel
    var _panel_x = _cx - 200;
    var _panel_y = 10;
    var _panel_w = 400;
    var _panel_h = 150;

    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true);

    // Title
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(_cx, _panel_y + 10, "== STREET CRAPS ==");

    // Current state
    draw_set_color(c_white);
    var _state_text = "";
    switch (dice_state) {
        case DICE_STATE.IDLE: _state_text = "Waiting for players..."; break;
        case DICE_STATE.WAITING_BETS: _state_text = "Place your bets!"; break;
        case DICE_STATE.ROLLING: _state_text = "Rolling..."; break;
        case DICE_STATE.COME_OUT: _state_text = "Come Out Roll"; break;
        case DICE_STATE.POINT_PHASE: _state_text = "Point: " + string(point_value); break;
        case DICE_STATE.POLICE_WARNING: _state_text = "!! RUN !! (" + string(ceil(warning_timer / 60)) + "s)"; break;
        case DICE_STATE.BUSTED: _state_text = "BUSTED!"; break;
    }
    draw_text(_cx, _panel_y + 35, _state_text);

    // Pot total
    draw_set_color(c_lime);
    draw_text(_cx, _panel_y + 55, "Pot: $" + string(pot_total));

    // Player's current bet
    if (ds_map_exists(bets, _player)) {
        var _my_bet = bets[? _player];
        var _my_type = bet_types[? _player];
        draw_set_color(c_aqua);
        draw_text(_cx, _panel_y + 75, "Your bet: $" + string(_my_bet) + " (" + string(_my_type) + ")");
    } else {
        draw_set_color(c_gray);
        draw_text(_cx, _panel_y + 75, "No bet placed");
    }

    // Shooter indicator
    var _shooter_text = (current_shooter == _player) ? "YOU ARE THE SHOOTER" : "Shooter: " + string(current_shooter_index + 1);
    draw_set_color(current_shooter == _player ? c_orange : c_white);
    draw_text(_cx, _panel_y + 95, _shooter_text);

    // Controls
    draw_set_color(c_ltgray);
    draw_set_halign(fa_left);
    draw_text(_panel_x + 10, _panel_y + 120, "[1-9] Bet | [P/D] Pass/Don't | [SPACE] Roll | [ESC] Leave");

    if (_player.has_gun) {
        draw_set_color(c_red);
        draw_text(_panel_x + 10, _panel_y + 135, "[R] Rob the game");
    }
}

// === GAME MESSAGE ===
if (message_timer > 0 && game_message != "") {
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    draw_text(_cx, _gui_h / 2, game_message);
}

// === POLICE WARNING ===
if (dice_state == DICE_STATE.POLICE_WARNING) {
    // Flashing red border
    var _flash = (warning_timer mod 30) < 15;
    if (_flash) {
        draw_set_color(c_red);
        draw_set_alpha(0.3);
        draw_rectangle(0, 0, _gui_w, _gui_h, false);
        draw_set_alpha(1);
    }

    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text_transformed(_cx, _gui_h / 2 - 50, "!! POLICE INCOMING !!", 2, 2, 0);
    draw_set_color(c_white);
    draw_text(_cx, _gui_h / 2, "RUN AWAY TO ESCAPE!");
    draw_text(_cx, _gui_h / 2 + 30, string(ceil(warning_timer / 60)) + " seconds remaining!");
}

// Reset draw settings
draw_set_halign(fa_left);
draw_set_color(c_white);
draw_set_alpha(1);
