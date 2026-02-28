// Draw the recruiter sprite
draw_self();

// === RECRUITER INDICATOR (Yellow exclamation mark above head) ===
if (state == "approaching") {
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

// === NAME TAG (when talking) ===
if (state == "talking" || state == "waiting") {
    var _name_y = y - sprite_height - 35;

    // Draw background box for name
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    var _name_width = string_width(recruiter_name + " (Recruiter)") + 8;
    var _name_height = string_height(recruiter_name) + 4;
    draw_rectangle(x - _name_width/2, _name_y - _name_height/2,
                   x + _name_width/2, _name_y + _name_height/2, false);

    // Draw name text
    draw_set_color(c_yellow);
    draw_set_alpha(1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x, _name_y, recruiter_name + " (Recruiter)");

    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
