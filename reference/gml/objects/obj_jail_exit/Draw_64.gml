var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

// === INTERCOM ANNOUNCEMENT ===
if (intercom_timer > 0 && intercom_message != "") {
    var _intercom_x = _gui_w / 2;
    var _intercom_y = 60;

    // Draw intercom background (static effect)
    var _msg_width = string_width(intercom_message) + 40;
    var _msg_height = 40;

    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(_intercom_x - _msg_width/2, _intercom_y - _msg_height/2,
                   _intercom_x + _msg_width/2, _intercom_y + _msg_height/2, false);
    draw_set_alpha(1);

    // Border with flashing effect
    var _flash = (intercom_timer mod 20) < 10;
    draw_set_color(_flash ? c_yellow : c_orange);
    draw_rectangle(_intercom_x - _msg_width/2, _intercom_y - _msg_height/2,
                   _intercom_x + _msg_width/2, _intercom_y + _msg_height/2, true);

    // Draw speaker icon text
    draw_set_color(c_gray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_intercom_x - _msg_width/2 + 20, _intercom_y, "[*]");

    // Draw intercom message
    draw_set_color(c_yellow);
    draw_text(_intercom_x + 10, _intercom_y, intercom_message);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// EXIT sign removed (timer disabled)

// === PROMPT TO EXIT ===
if (show_prompt) {
    // Draw at bottom center of screen
    var _text = "[E] Exit Jail";
    var _width = string_width(_text);
    var _height = string_height(_text);

    var _x = _gui_w / 2;
    var _y = _gui_h - 100;

    // Draw background box
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(_x - _width/2 - 10, _y - 10, _x + _width/2 + 10, _y + _height + 10, false);

    // Draw text
    draw_set_alpha(1);
    draw_set_color(c_lime);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(_x, _y, _text);

    // Reset draw settings
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// Real-time jail countdown removed (timer disabled)
