/// obj_dice_game - Draw Event (world space)

// Color constants (using hex to avoid built-in issues)
var _col_white = $FFFFFF;
var _col_black = $000000;
var _col_gray = $808080;

// Draw visual marker for the dice game location
draw_set_color(_col_gray);
draw_circle(x, y, 40, true);

// Draw dice when rolling or after roll
if (is_rolling || dice_total > 0) {
    var _die_size = 24;
    var _die1_x = x - 30;
    var _die2_x = x + 10;
    var _die_y = y - 20;
    var _pip_size = 3;

    // Draw die 1 background
    draw_set_color(_col_white);
    draw_rectangle(_die1_x, _die_y, _die1_x + _die_size, _die_y + _die_size, false);
    draw_set_color(_col_black);
    draw_rectangle(_die1_x, _die_y, _die1_x + _die_size, _die_y + _die_size, true);

    // Draw die 2 background
    draw_set_color(_col_white);
    draw_rectangle(_die2_x, _die_y, _die2_x + _die_size, _die_y + _die_size, false);
    draw_set_color(_col_black);
    draw_rectangle(_die2_x, _die_y, _die2_x + _die_size, _die_y + _die_size, true);

    // Determine which numbers to draw
    var _num1 = is_rolling ? irandom_range(1, 6) : die1;
    var _num2 = is_rolling ? irandom_range(1, 6) : die2;

    // Draw pips for die 1
    draw_set_color(_col_black);
    var _cx = _die1_x + _die_size / 2;
    var _cy = _die_y + _die_size / 2;
    var _offset = _die_size / 6;

    switch (_num1) {
        case 1:
            draw_circle(_cx, _cy, _pip_size, false);
            break;
        case 2:
            draw_circle(_die1_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 3:
            draw_circle(_die1_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_cx, _cy, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 4:
            draw_circle(_die1_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 5:
            draw_circle(_die1_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_cx, _cy, _pip_size, false);
            draw_circle(_die1_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 6:
            draw_circle(_die1_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _offset, _cy, _pip_size, false);
            draw_circle(_die1_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _cy, _pip_size, false);
            draw_circle(_die1_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
    }

    // Draw pips for die 2
    _cx = _die2_x + _die_size / 2;
    _cy = _die_y + _die_size / 2;

    switch (_num2) {
        case 1:
            draw_circle(_cx, _cy, _pip_size, false);
            break;
        case 2:
            draw_circle(_die2_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 3:
            draw_circle(_die2_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_cx, _cy, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 4:
            draw_circle(_die2_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 5:
            draw_circle(_die2_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_cx, _cy, _pip_size, false);
            draw_circle(_die2_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
        case 6:
            draw_circle(_die2_x + _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _offset, _cy, _pip_size, false);
            draw_circle(_die2_x + _offset, _die_y + _die_size - _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _offset, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _cy, _pip_size, false);
            draw_circle(_die2_x + _die_size - _offset, _die_y + _die_size - _offset, _pip_size, false);
            break;
    }
}

// Reset draw color
draw_set_color(_col_white);
