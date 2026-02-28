// === DRAW PLAYER WITH CUSTOMIZATION ===

// Get skin tone color
var _skin_col = skin_tone_colors[global.player_skin_tone];

// Modify appearance if stunned (rotated/lying down)
var _draw_angle = image_angle;
var _draw_alpha = image_alpha;
if (is_stunned) {
    _draw_angle = 90; // Rotate player to lie on side
    _draw_alpha = 0.7; // Slightly transparent to show unconscious
}

// Draw player sprite with skin tone blend
draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, _draw_angle, _skin_col, _draw_alpha);

// Draw bandana on top (skip if stunned for simplicity)
if (!is_stunned) {
    var _bandana_col = bandana_colors[global.player_bandana_color];
    draw_set_color(_bandana_col);

    // Bandana position offset based on facing direction
    var _bx = x;
    var _by = y - 12; // Bandana sits on head

    // Draw simple bandana shape (rectangle with tail)
    // Adjust based on sprite origin and size
    draw_rectangle(_bx - 8, _by - 4, _bx + 8, _by + 2, false);

    // Bandana tail (only visible from side/back views)
    if (facing == "left") {
        draw_triangle(_bx + 6, _by - 1, _bx + 14, _by + 4, _bx + 8, _by + 6, false);
    } else if (facing == "right") {
        draw_triangle(_bx - 6, _by - 1, _bx - 14, _by + 4, _bx - 8, _by + 6, false);
    } else if (facing == "up") {
        // Tail hangs down back
        draw_triangle(_bx - 3, _by + 2, _bx + 3, _by + 2, _bx, _by + 10, false);
    }
}

// === DRAW GUN WHEN WEAPON DRAWN ===
if (weapon_drawn && weapon_type > 0 && !is_stunned) {
    var _gun_col = c_dkgray;
    var _gx = x;
    var _gy = y;

    // Map diagonal facings to cardinal for gun drawing
    var _gun_facing = facing;
    switch (facing) {
        case "up_right":   _gun_facing = "right"; break;
        case "up_left":    _gun_facing = "left";  break;
        case "down_right": _gun_facing = "right"; break;
        case "down_left":  _gun_facing = "left";  break;
    }

    // Offset gun position based on facing
    switch (_gun_facing) {
        case "right":
            _gx += 10; _gy += 2;
            // Barrel (horizontal)
            draw_set_color(_gun_col);
            draw_rectangle(_gx, _gy - 1, _gx + 6 + (weapon_type == 2 ? 3 : 0) + (weapon_type == 3 ? 2 : 0), _gy + 1, false);
            // Grip
            draw_rectangle(_gx - 1, _gy, _gx + 1, _gy + 4, false);
            break;
        case "left":
            _gx -= 10; _gy += 2;
            draw_set_color(_gun_col);
            draw_rectangle(_gx - 6 - (weapon_type == 2 ? 3 : 0) - (weapon_type == 3 ? 2 : 0), _gy - 1, _gx, _gy + 1, false);
            draw_rectangle(_gx - 1, _gy, _gx + 1, _gy + 4, false);
            break;
        case "up":
            _gx += 8; _gy -= 2;
            draw_set_color(_gun_col);
            draw_rectangle(_gx - 1, _gy - 6 - (weapon_type == 2 ? 3 : 0) - (weapon_type == 3 ? 2 : 0), _gx + 1, _gy, false);
            draw_rectangle(_gx, _gy - 1, _gx + 4, _gy + 1, false);
            break;
        case "down":
            _gx -= 8; _gy += 4;
            draw_set_color(_gun_col);
            draw_rectangle(_gx - 1, _gy, _gx + 1, _gy + 6 + (weapon_type == 2 ? 3 : 0) + (weapon_type == 3 ? 2 : 0), false);
            draw_rectangle(_gx - 4, _gy - 1, _gx, _gy + 1, false);
            break;
    }

    // SMG has a thicker body
    if (weapon_type == 2) {
        draw_set_color(c_gray);
        switch (_gun_facing) {
            case "right": draw_rectangle(_gx + 1, _gy - 2, _gx + 4, _gy + 2, false); break;
            case "left":  draw_rectangle(_gx - 4, _gy - 2, _gx - 1, _gy + 2, false); break;
            case "up":    draw_rectangle(_gx - 2, _gy - 4, _gx + 2, _gy - 1, false); break;
            case "down":  draw_rectangle(_gx - 2, _gy + 1, _gx + 2, _gy + 4, false); break;
        }
    }

    // Shotgun has a wider barrel end
    if (weapon_type == 3) {
        draw_set_color(c_gray);
        switch (_gun_facing) {
            case "right": draw_rectangle(_gx + 7, _gy - 2, _gx + 8, _gy + 2, false); break;
            case "left":  draw_rectangle(_gx - 8, _gy - 2, _gx - 7, _gy + 2, false); break;
            case "up":    draw_rectangle(_gx - 2, _gy - 8, _gx + 2, _gy - 7, false); break;
            case "down":  draw_rectangle(_gx - 2, _gy + 7, _gx + 2, _gy + 8, false); break;
        }
    }
}

// Draw "X_X" eyes if stunned
if (is_stunned) {
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_text(x, y - 8, "X_X");
    draw_set_halign(fa_left);
}
