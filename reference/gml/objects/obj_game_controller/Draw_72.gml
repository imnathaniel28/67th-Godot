// === DRAW STREET AND ROAD MARKINGS (Draw Begin - draws behind everything) ===

// Only draw in main game room
if (room == Seattle) {
    // Draw asphalt over the lava
    draw_set_color(make_color_rgb(64, 64, 64));
    draw_rectangle(0, street_y_top, room_width, street_y_bottom, false);

    // Yellow center line (dashed)
    var _street_center_y = (street_y_top + street_y_bottom) / 2;
    draw_set_color(c_yellow);
    for (var _x = 0; _x < room_width; _x += 60) {
        draw_rectangle(_x, _street_center_y - 2, _x + 40, _street_center_y + 2, false);
    }

    // White edge lines
    draw_set_color(c_white);
    draw_rectangle(0, street_y_top, room_width, street_y_top + 3, false);
    draw_rectangle(0, street_y_bottom - 3, room_width, street_y_bottom, false);
}

    // Draw crosswalk stripes (white vertical lines)
    draw_set_color(c_white);
    for (var i = 0; i < array_length(crosswalk_zones); i++) {
        var _zone = crosswalk_zones[i];
        // Draw vertical white stripes across the street
        for (var _x = _zone.x_min; _x < _zone.x_max; _x += 10) {
            draw_rectangle(_x, street_y_top, _x + 6, street_y_bottom, false);
        }
    }
