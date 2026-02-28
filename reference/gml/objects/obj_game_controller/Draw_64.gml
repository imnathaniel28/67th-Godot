// === HUD ===
draw_set_color(c_white);
draw_set_font(-1);

// Digital Clock Display (Top Right)
var _gui_width = display_get_gui_width();
draw_set_halign(fa_right);
draw_set_color(c_black);
draw_rectangle(_gui_width - 110, 5, _gui_width - 5, 35, false);
draw_set_color(is_night ? c_aqua : c_yellow);
draw_rectangle(_gui_width - 110, 5, _gui_width - 5, 35, true);
draw_set_color(is_night ? c_aqua : c_white);
draw_text(_gui_width - 15, 10, time_string);
draw_set_halign(fa_left);

// Day/Week counter (Top Left)
draw_set_color(c_white);
draw_text(10, 10, "Day " + string(day_current) + " | Week " + string(week_current));
// Show debt if player owes money
if (instance_exists(player1) && player1.debt > 0) {
    draw_set_color(c_red);
    draw_text(10, 70, "DEBT: $" + string(player1.debt));
    // Warning if approaching auto-jail threshold
    if (player1.debt >= 450) {
        draw_set_color(c_yellow);
        draw_text(10, 90, "! WARNING: Near $500 limit !");
    }
    draw_set_color(c_white);
}

// === JAIL OFFER UI ===
if (game_state == GAME_STATE.JAIL && showing_snitch_offer) {        
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    draw_set_color(c_dkgray);
    draw_rectangle(_cx - 200, _cy - 100, _cx + 200, _cy + 100, false);
    draw_set_color(c_white);
    draw_rectangle(_cx - 200, _cy - 100, _cx + 200, _cy + 100, true);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 80, "YOU'VE BEEN ARRESTED!");
    draw_text(_cx, _cy - 50, "Lost: $" + string(confiscated_money));

    draw_set_color(c_yellow);
    draw_text(_cx, _cy - 10, "Become a SNITCH?");
    draw_text(_cx, _cy + 30, "But wear the title for 1 WEEK");      

    draw_set_color(c_lime);
    draw_text(_cx, _cy + 70, "[Y] Accept     [N] Do the time");     
    draw_set_halign(fa_left);
}
// Jail countdown display removed (timer disabled)
// === DEBUG OVERLAY (show jailed_player.jail_timer and last_dt) ===
if (global.debug_mode) {
    var _x = 10;
    var _y = display_get_gui_height() - 70;
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(_x - 6, _y - 6, _x + 320, _y + 60, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_text(_x, _y, "DEBUG: jailed_player: " + string(jailed_player));
    // jail timer display disabled
    draw_text(_x, _y + 16, "jail_timer (s): <disabled>");
    draw_text(_x, _y + 32, "last_dt (s): " + string(last_dt));
    // Also show quick scan info for player1 instances
    var _pcount = instance_number(player1);
    draw_text(_x, _y + 48, "player1 count: " + string(_pcount));
    if (_pcount > 0) {
        var _first = instance_find(player1, 0);
        if (_first != noone) draw_text(_x + 140, _y + 48, "p1[0].is_jailed: " + string(_first.is_jailed));
    }
}
// === JAYWALKING FINE UI ===
if (game_state == GAME_STATE.JAIL && showing_fine_popup) {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
    draw_set_color(c_dkgray);
    draw_rectangle(_cx - 250, _cy - 120, _cx + 250, _cy + 120, false);
    draw_set_color(c_white);
    draw_rectangle(_cx - 250, _cy - 120, _cx + 250, _cy + 120, true);
    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text(_cx, _cy - 90, "JAYWALKING VIOLATION!");
    draw_set_color(c_white);
    draw_text(_cx, _cy - 60, "You crossed outside the crosswalk");
    draw_text(_cx, _cy - 30, "Fine: $" + string(fine_amount));
    var _can_pay = (fined_player.money >= fine_amount);

    draw_set_color(_can_pay ? c_lime : c_gray);
    draw_text(_cx, _cy + 10, "[1] Pay $" + string(fine_amount));

    draw_set_color(c_yellow);
    draw_text(_cx, _cy + 40, "[2] Go to Jail (1 day)");

    draw_set_color(c_orange);
    draw_text(_cx, _cy + 70, "[3] Go into Debt");

    draw_set_halign(fa_left);
}

// === POLICE ROBBERY UI ===
if (showing_robbery_popup) {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    draw_set_color(c_dkgray);
    draw_rectangle(_cx - 280, _cy - 140, _cx + 280, _cy + 100, false);
    draw_set_color(c_red);
    draw_rectangle(_cx - 280, _cy - 140, _cx + 280, _cy + 100, true);

    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text(_cx, _cy - 110, "!! CORRUPT POLICE !!");

    draw_set_color(c_white);
    draw_text(_cx, _cy - 70, "You were caught with drugs AND cash.");
    draw_text(_cx, _cy - 40, "The cops robbed and beat you up!");

    draw_set_color(c_yellow);
    draw_text(_cx, _cy - 5, "Money Stolen: $" + string(robbery_money_lost));
    draw_text(_cx, _cy + 25, "Health Lost: 50 HP");
    draw_text(_cx, _cy + 55, "All drugs confiscated");

    draw_set_color(c_lime);
    draw_text(_cx, _cy + 85, "[Press any key to continue]");

    draw_set_halign(fa_left);
}

// === PVP CHOICE UI ===
if (game_state == GAME_STATE.PVP_CHOICE) {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_cx, _cy - 100, "ENCOUNTER!");

    draw_set_color(pvp_choice1 == PVP_CHOICE.NONE ? c_yellow : c_gray);
    draw_text(_cx - 150, _cy - 50, "Player 1");
    draw_text(_cx - 150, _cy - 20, "[C] Collaborate");
    draw_text(_cx - 150, _cy + 10, "[R] Rob");
    if (pvp_choice1 != PVP_CHOICE.NONE) {
        draw_set_color(c_lime);
        draw_text(_cx - 150, _cy + 50, "LOCKED IN");
    }

    draw_set_color(pvp_choice2 == PVP_CHOICE.NONE ? c_yellow : c_gray);
    draw_text(_cx + 150, _cy - 50, "Player 2");
    draw_text(_cx + 150, _cy - 20, "[P] Collaborate");
    draw_text(_cx + 150, _cy + 10, "[L] Rob");
    if (pvp_choice2 != PVP_CHOICE.NONE) {
        draw_set_color(c_lime);
        draw_text(_cx + 150, _cy + 50, "LOCKED IN");
    }

    draw_set_halign(fa_left);
}

// === DUEL UI ===
if (game_state == GAME_STATE.DUEL) {
    var _cx = display_get_gui_width() / 2;

    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text(_cx, 20, "!! DUEL !!");

    if (instance_exists(duel_player1)) {
        draw_set_color(c_red);
        draw_rectangle(50, 50, 250, 70, false);
        draw_set_color(c_lime);
        var _hp1_width = (duel_player1.duel_health / 100) * 200;    
        draw_rectangle(50, 50, 50 + _hp1_width, 70, false);
        draw_set_color(c_white);
        draw_text(150, 55, "P1");
    }

    if (instance_exists(duel_player2)) {
        var _right = display_get_gui_width();
        draw_set_color(c_red);
        draw_rectangle(_right - 250, 50, _right - 50, 70, false);   
        draw_set_color(c_lime);
        var _hp2_width = (duel_player2.duel_health / 100) * 200;    
        draw_rectangle(_right - 50 - _hp2_width, 50, _right - 50, 70, false);
        draw_set_color(c_white);
        draw_text(_right - 150, 55, "P2");
    }

    draw_set_halign(fa_left);
}

// === BACKDOOR MESSAGE ===
if (show_backdoor_msg) {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text(_cx, _cy - 20, "YOU'VE BEEN BACKDOORED");
    draw_set_color(c_white);
    draw_text(_cx, _cy + 10, "Your money was stolen!");
    draw_set_halign(fa_left);
}

// === TOAST NOTIFICATIONS ===
var _toast_x = display_get_gui_width() - 20;
var _toast_base_y = 45;
var _visible_count = min(array_length(notification_queue), max_visible_toasts);

for (var _n = 0; _n < _visible_count; _n++) {
    var _toast = notification_queue[_n];
    var _ty = _toast_base_y + (_n * toast_spacing) + _toast.y_offset;

    // Background
    draw_set_alpha(_toast.alpha * 0.7);
    draw_set_color(c_black);
    draw_set_halign(fa_right);
    draw_rectangle(_toast_x - 260, _ty - 2, _toast_x + 5, _ty + 20, false);

    // Text
    draw_set_alpha(_toast.alpha);
    draw_set_color(_toast.color);
    draw_text(_toast_x - 5, _ty, _toast.text);
}
draw_set_alpha(1);
draw_set_halign(fa_left);

// === NIGHT DIMMING OVERLAY (10pm-10am) ===
// Draw this LAST so it dims everything including UI
if (night_alpha > 0.01 && room == Seattle) {
    draw_set_alpha(night_alpha);
    draw_set_color(make_color_rgb(10, 10, 40)); // Dark blue tint for night
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);
}