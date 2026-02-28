// Draw the crew member sprite (with customization colors like player)
// For now, just draw normally - we can add skin tone/bandana blending later

// Draw sprite
draw_self();

// === RECRUITING INDICATOR (yellow exclamation) ===
if (state == "recruiting_approach") {
    var _indicator_x = x;
    var _indicator_y = y - sprite_height - 20;

    // Draw glowing yellow circle
    draw_set_alpha(0.7);
    draw_circle_color(_indicator_x, _indicator_y, 12, c_yellow, c_orange, false);
    draw_set_alpha(1);

    // Draw exclamation mark
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_indicator_x, _indicator_y, "!");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// === STATUS INDICATOR (colored dot above head) - only when hired ===
if (is_hired) {
    var _indicator_x = x;
    var _indicator_y = y - sprite_height - 10;
    draw_circle_color(_indicator_x, _indicator_y, 4, status_color, status_color, false);
}

// === NAME TAG ===
if (show_status || !is_hired) {
    var _name_y = y - sprite_height - 20;

    // Draw background box for name
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    var _name_width = string_width(worker_name) + 8;
    var _name_height = string_height(worker_name) + 4;
    draw_rectangle(x - _name_width/2, _name_y - _name_height/2,
                   x + _name_width/2, _name_y + _name_height/2, false);

    // Draw name text
    draw_set_color(c_white);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    // Show worker name
    draw_set_color(!is_hired ? c_yellow : c_white);
    draw_text(x, _name_y, worker_name);

    // Draw state below name (debug) - only when hired
    if (is_hired && (global.debug_mode || true)) { // Always show for now
        draw_set_color(c_yellow);
        var _state_text = "";
        switch(state) {
            case "roaming": _state_text = "Roaming"; break;
            case "selling": _state_text = "Selling!"; break;
            case "break": _state_text = "Break"; break;
        }
        draw_text(x, _name_y + 15, _state_text);

        // Show daily earnings if > 0
        if (daily_earnings > 0) {
            draw_set_color(c_lime);
            draw_text(x, _name_y + 30, "$" + string(daily_earnings));
        }
    }

    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
