// Draw the NPC sprite normally
draw_self();

// === DRAW SPEECH BUBBLE ===
if (show_speech_bubble && speech_bubble_timer > 0) {
    // Speech bubble position (above the NPC's head)
    var _bubble_x = x;
    var _bubble_y = y - sprite_height - 20;

    // Bubble dimensions - show what drug they want
    var _text = speech_text + " $" + string(payment_amount);
    var _text_width = string_width(_text);
    var _text_height = string_height(_text);
    var _padding = 6;
    var _bubble_width = _text_width + _padding * 2;
    var _bubble_height = _text_height + _padding * 2;

    // Draw bubble background (rounded rectangle with tail)
    draw_set_color(c_white);
    draw_set_alpha(0.95);
    draw_roundrect(_bubble_x - _bubble_width/2, _bubble_y - _bubble_height,
                   _bubble_x + _bubble_width/2, _bubble_y, false);

    // Draw speech bubble tail (triangle pointing down to NPC)
    draw_triangle(_bubble_x - 6, _bubble_y,
                  _bubble_x + 6, _bubble_y,
                  _bubble_x, _bubble_y + 8, false);

    // Draw bubble border
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_bubble_x - _bubble_width/2, _bubble_y - _bubble_height,
                   _bubble_x + _bubble_width/2, _bubble_y, true);

    // Draw speech bubble tail border
    draw_triangle(_bubble_x - 6, _bubble_y,
                  _bubble_x + 6, _bubble_y,
                  _bubble_x, _bubble_y + 8, true);

    // Draw the text (colored by drug type)
    draw_set_color(drug_get_color(wanted_drug));
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_bubble_x, _bubble_y - _bubble_height/2, _text);

    // Reset draw settings
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
}
