// Draw rival dealer name tag and health
var _sx = x - camera_get_view_x(view_camera[0]);
var _sy = y - camera_get_view_y(view_camera[0]) - 30;

// Convert to GUI coordinates (account for viewport scaling)
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _view_w = camera_get_view_width(view_camera[0]);
var _view_h = camera_get_view_height(view_camera[0]);

// Actually, for Draw_64 we need GUI coords from world position
// Use simple scaling
var _cam_x = camera_get_view_x(view_camera[0]);
var _cam_y = camera_get_view_y(view_camera[0]);
var _gx = (x - _cam_x) / _view_w * _gui_w;
var _gy = (y - _cam_y) / _view_h * _gui_h;

// Only draw if on screen
if (_gx > 0 && _gx < _gui_w && _gy > 0 && _gy < _gui_h) {
    // Name tag
    draw_set_halign(fa_center);
    draw_set_color(c_red);
    draw_text(_gx, _gy - 40, rival_name);

    // Health bar (small)
    if (hp < max_hp) {
        var _bar_w = 30;
        var _bar_h = 4;
        var _bar_x = _gx - _bar_w/2;
        var _bar_y = _gy - 32;

        draw_set_color(c_black);
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
        draw_set_color(c_red);
        draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * (hp / max_hp), _bar_y + _bar_h, false);
    }

    // State indicator
    if (state == "selling") {
        draw_set_color(c_yellow);
        draw_text(_gx, _gy - 50, "$ Selling $");
    } else if (state == "fighting") {
        draw_set_color(c_red);
        draw_text(_gx, _gy - 50, "!! SHOOTING !!");
    }

    // Interaction prompts
    var _p = instance_nearest(x, y, player1);
    if (_p != noone) {
        var _pd = point_distance(x, y, _p.x, _p.y);
        if (_pd < 48 && state != "fighting" && state != "leaving") {
            draw_set_color(c_yellow);
            draw_text(_gx, _gy + 20, "[E] Intimidate  [F] Fight");
        }
    }

    draw_set_halign(fa_left);
}
