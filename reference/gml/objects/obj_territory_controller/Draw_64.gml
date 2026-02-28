// === TERRITORY CONTROLLER DRAW GUI EVENT ===

// Draw territory blocks on the map
draw_set_alpha(1);
for (var i = 0; i < blocks_wide; i++) {
    for (var j = 0; j < blocks_tall; j++) {
        var _block = territory_grid[i][j];
        var _x1 = neighborhood_x + (i * block_size);
        var _y1 = neighborhood_y + (j * block_size);
        var _x2 = _x1 + block_size;
        var _y2 = _y1 + block_size;

        // Convert world coordinates to screen coordinates
        var _screen_x1 = _x1 - camera_get_view_x(view_camera[0]);
        var _screen_y1 = _y1 - camera_get_view_y(view_camera[0]);
        var _screen_x2 = _x2 - camera_get_view_x(view_camera[0]);
        var _screen_y2 = _y2 - camera_get_view_y(view_camera[0]);

        // Draw block with owner's color
        if (_block.owner != noone) {
            draw_set_alpha(_block.alpha);
            draw_rectangle_color(_screen_x1, _screen_y1, _screen_x2, _screen_y2,
                               _block.color, _block.color, _block.color, _block.color, false);
            draw_set_alpha(1);
            draw_set_color(c_white);
            draw_rectangle(_screen_x1, _screen_y1, _screen_x2, _screen_y2, true);
        } else {
            // Unclaimed - no grid lines (removed)
        }

        // Highlight selected block
        if (showing_claim_ui || showing_relocate_ui) {
            if (i == selected_block_x && j == selected_block_y) {
                draw_set_color(c_yellow);
                draw_set_alpha(0.5);
                draw_rectangle(_screen_x1, _screen_y1, _screen_x2, _screen_y2, false);
                draw_set_alpha(1);
                draw_set_color(c_yellow);
                draw_rectangle(_screen_x1, _screen_y1, _screen_x2, _screen_y2, true);
                draw_line_width(_screen_x1, _screen_y1, _screen_x2, _screen_y2, 2);
                draw_line_width(_screen_x2, _screen_y1, _screen_x1, _screen_y2, 2);
            }
        }
    }
}

draw_set_alpha(1);
draw_set_color(c_white);

// Draw claiming UI
if (showing_claim_ui && claiming_player != noone) {
    var _ui_x = 20;
    var _ui_y = 20;

    // Background
    draw_set_alpha(0.8);
    draw_rectangle_color(_ui_x, _ui_y, _ui_x + 300, _ui_y + 250, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_rectangle_color(_ui_x, _ui_y, _ui_x + 300, _ui_y + 250, c_white, c_white, c_white, c_white, true);

    // Title
    draw_set_color(c_white);
    draw_text(_ui_x + 10, _ui_y + 10, "CLAIM TERRITORY");
    draw_text(_ui_x + 10, _ui_y + 30, "Click on any unclaimed block");

    // Color selection
    draw_text(_ui_x + 10, _ui_y + 60, "Choose Color (1-9):");
    for (var i = 0; i < min(9, array_length(available_colors)); i++) {
        var _color_x = _ui_x + 10 + (i % 3) * 90;
        var _color_y = _ui_y + 80 + floor(i / 3) * 30;

        draw_set_color(available_colors[i]);
        draw_rectangle(_color_x, _color_y, _color_x + 60, _color_y + 20, false);

        if (i == selected_color_index) {
            draw_set_color(c_yellow);
            draw_rectangle(_color_x - 2, _color_y - 2, _color_x + 62, _color_y + 22, true);
            draw_rectangle(_color_x - 3, _color_y - 3, _color_x + 63, _color_y + 23, true);
        }

        draw_set_color(c_white);
        draw_text(_color_x + 5, _color_y + 2, string(i + 1));
    }

    // Instructions
    draw_set_color(c_white);
    draw_text(_ui_x + 10, _ui_y + 190, "Territory is FREE in");
    draw_text(_ui_x + 10, _ui_y + 205, "low-income neighborhood!");
    draw_text(_ui_x + 10, _ui_y + 225, "Press T to close");
}

// Draw relocation UI
if (showing_relocate_ui && claiming_player != noone) {
    var _ui_x = 20;
    var _ui_y = 20;
    var _tax = floor(claiming_player.money * relocation_tax_rate);

    // Background
    draw_set_alpha(0.8);
    draw_rectangle_color(_ui_x, _ui_y, _ui_x + 300, _ui_y + 180, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);
    draw_rectangle_color(_ui_x, _ui_y, _ui_x + 300, _ui_y + 180, c_white, c_white, c_white, c_white, true);

    // Title
    draw_set_color(c_white);
    draw_text(_ui_x + 10, _ui_y + 10, "RELOCATE TERRITORY");
    draw_text(_ui_x + 10, _ui_y + 30, "Click new unclaimed location");

    // Current territory info
    if (variable_instance_exists(claiming_player, "territory_name")) {
        draw_text(_ui_x + 10, _ui_y + 60, "Current: " + claiming_player.territory_name);
    }

    // Tax info
    draw_text(_ui_x + 10, _ui_y + 90, "Relocation Tax: 10%");
    draw_text(_ui_x + 10, _ui_y + 105, "Cost: $" + string(_tax));
    draw_text(_ui_x + 10, _ui_y + 120, "Your Money: $" + string(claiming_player.money));

    // Insufficient funds warning
    if (claiming_player.money < _tax) {
        draw_set_color(c_red);
        draw_text(_ui_x + 10, _ui_y + 140, "Insufficient funds!");
    }

    draw_set_color(c_white);
    draw_text(_ui_x + 10, _ui_y + 160, "Press T to close");
}

// Draw territory info for players
var _player = instance_find(player1, 0);
if (_player != noone && variable_instance_exists(_player, "territory_x") && _player.territory_x != -1) {
    var _info_x = display_get_gui_width() - 200;
    var _info_y = 20;

    draw_set_alpha(0.7);
    draw_rectangle_color(_info_x, _info_y, _info_x + 180, _info_y + 80, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1);

    draw_set_color(c_white);
    draw_text(_info_x + 10, _info_y + 10, "MY TERRITORY");
    draw_text(_info_x + 10, _info_y + 30, _player.territory_name);

    // Draw color swatch
    draw_set_color(_player.territory_color);
    draw_rectangle(_info_x + 10, _info_y + 50, _info_x + 40, _info_y + 70, false);
    draw_set_color(c_white);
    draw_rectangle(_info_x + 10, _info_y + 50, _info_x + 40, _info_y + 70, true);

    draw_text(_info_x + 50, _info_y + 55, "Press T to relocate");
}

draw_set_alpha(1);
draw_set_color(c_white);
