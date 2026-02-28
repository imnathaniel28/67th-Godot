// === ROBBERY PROMPT ===
if (can_be_robbed && !robbed && !arrived) {
    var _player = instance_nearest(x, y, player1);

    if (_player != noone) {
        var _dist = point_distance(x, y, _player.x, _player.y);

        // Player is close enough to see prompt
        if (_dist < 48) {
            draw_set_color(c_red);
            draw_set_alpha(0.9);
            draw_set_halign(fa_center);
            draw_text(x, y - 30, "[R] Rob Courier");
            draw_set_color(c_yellow);
            draw_text(x, y - 45, "$" + string(drug_amount * 50));
            draw_set_alpha(1);
            draw_set_color(c_white);
            draw_set_halign(fa_left);
        }
    }
}

// Debug info (optional - can be removed)
if (global.debug_mode || true) {
    draw_set_color(c_lime);
    draw_set_alpha(0.8);
    draw_text(x, y - 20, "Walker: " + string(drug_amount) + " units");
    draw_set_alpha(1);
    draw_set_color(c_white);
}
