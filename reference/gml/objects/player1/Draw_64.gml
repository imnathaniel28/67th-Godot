 // Player stats HUD
// === HEALTH BAR ===
var _bar_width = 200;
var _bar_height = 20;
var _bar_x = 10;
var _bar_y = 10;

// Background (black)
draw_set_color(c_black);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_width, _bar_y + _bar_height, false);

// Health fill (green to red gradient based on health)
// Handle negative health for jail melee
var _health_percent = clamp(health / max_health, 0, 1);
var _fill_width = _bar_width * _health_percent;

if (_health_percent > 0.5) {
    draw_set_color(c_lime); // High health = green
} else if (_health_percent > 0.25) {
    draw_set_color(c_yellow); // Medium health = yellow
} else if (_health_percent > 0.05) {
    draw_set_color(c_red); // Low health = red
} else {
    draw_set_color(c_maroon); // Critical/stunned = dark red
}
draw_rectangle(_bar_x, _bar_y, _bar_x + _fill_width, _bar_y + _bar_height, false);

// Border (white)
draw_set_color(c_white);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_width, _bar_y + _bar_height, true);

// Health text - show negative values in jail
draw_set_color(c_white);
draw_set_halign(fa_center);
if (is_jailed && health < 0) {
    draw_set_color(c_red);
    draw_text(_bar_x + _bar_width/2, _bar_y + 3, string(floor(health)) + " / " + string(max_health));
} else {
    draw_text(_bar_x + _bar_width/2, _bar_y + 3, string(floor(health)) + " / " + string(max_health));
}
draw_set_halign(fa_left);

// === MONEY ===
draw_set_color(c_lime);
draw_text(10, 40, "$" + string(money));

// === EQUIPPED WEAPON ===
if (weapon_drawn && weapon_type > 0) {
    draw_set_color(c_yellow);
    draw_text(_bar_x + _bar_width + 10, _bar_y + 3, weapon_stats[weapon_type].name);
} else if (!is_jailed) {
    draw_set_color(c_gray);
    draw_text(_bar_x + _bar_width + 10, _bar_y + 3, "[P] Weapon");
}

// === BLEEDING WARNING ===
if (is_bleeding) {
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    
    // Pulsing red vignette overlay
    var _pulse = 0.15 + sin(bleed_flash_timer * 0.08) * 0.1;
    draw_set_alpha(_pulse);
    draw_set_color(c_red);
    draw_rectangle(0, 0, _gui_w, _gui_h, false);
    draw_set_alpha(1);
    
    // Red border edges (thicker pulse)
    var _edge_alpha = 0.3 + sin(bleed_flash_timer * 0.1) * 0.2;
    draw_set_alpha(_edge_alpha);
    draw_set_color(c_red);
    // Top
    draw_rectangle(0, 0, _gui_w, 8, false);
    // Bottom
    draw_rectangle(0, _gui_h - 8, _gui_w, _gui_h, false);
    // Left
    draw_rectangle(0, 0, 8, _gui_h, false);
    // Right
    draw_rectangle(_gui_w - 8, 0, _gui_w, _gui_h, false);
    draw_set_alpha(1);
    
    // Blinking "BLEEDING" text near health bar
    if ((bleed_flash_timer div 20) mod 2 == 0) {
        draw_set_color(c_red);
        draw_text(_bar_x + _bar_width + 10, _bar_y + 3, "BLEEDING!");
    }
    
    // "Find Hospital" prompt at top center
    draw_set_halign(fa_center);
    draw_set_color(c_red);
    var _warn_alpha = 0.7 + sin(bleed_flash_timer * 0.06) * 0.3;
    draw_set_alpha(_warn_alpha);
    draw_text(_gui_w / 2, 35, "GET TO A HOSPITAL!");
    draw_set_alpha(1);
    draw_set_halign(fa_left);
}

// === SALES MODE CHECKBOXES ===
if (!is_jailed && room == Seattle) {
    var _cb_y = 58;
    var _cb_size = 10;
    var _labels = ["Yes", "Homie", "No"];
    var _colors = [c_lime, c_aqua, c_red];
    var _cb_positions = [72, 115, 170]; // x positions for each checkbox
    var _label_positions = [85, 128, 183]; // x positions for each label

    draw_set_color(c_white);
    draw_text(10, 57, "Sales:");

    for (var _s = 0; _s < 3; _s++) {
        var _bx = _cb_positions[_s];
        var _by = _cb_y;

        if (auto_sale_mode == _s) {
            // Selected: filled box
            draw_set_color(_colors[_s]);
            draw_rectangle(_bx, _by, _bx + _cb_size, _by + _cb_size, false);
            draw_set_color(c_white);
            draw_rectangle(_bx, _by, _bx + _cb_size, _by + _cb_size, true);
            // Checkmark
            draw_set_color(c_white);
            draw_text(_bx + 1, _by - 2, "x");
        } else {
            // Unselected: outline only
            draw_set_color(c_gray);
            draw_rectangle(_bx, _by, _bx + _cb_size, _by + _cb_size, true);
        }

        // Label
        draw_set_color(_colors[_s]);
        draw_text(_label_positions[_s], 57, _labels[_s]);
    }
}

// === HEAT BAR ===
if (!is_jailed && room == Seattle) {
    var _heat_y = 75;
    var _heat_bar_w = 100;
    var _heat_bar_h = 10;

    // Background
    draw_set_color(c_black);
    draw_rectangle(10, _heat_y, 10 + _heat_bar_w, _heat_y + _heat_bar_h, false);

    // Fill (yellow -> orange -> red)
    var _heat_pct = heat_level / 100;
    var _fill_w = _heat_bar_w * _heat_pct;
    if (_heat_pct > 0.6) draw_set_color(c_red);
    else if (_heat_pct > 0.3) draw_set_color(c_orange);
    else draw_set_color(c_yellow);
    if (_fill_w > 0) draw_rectangle(10, _heat_y, 10 + _fill_w, _heat_y + _heat_bar_h, false);

    // Border
    draw_set_color(c_white);
    draw_rectangle(10, _heat_y, 10 + _heat_bar_w, _heat_y + _heat_bar_h, true);

    // Label
    draw_set_color(c_orange);
    draw_text(115, _heat_y - 1, "HEAT: " + string(floor(heat_level)));
}

// === CREW EARNINGS ===
if (crew_unlocked && array_length(crew_members) > 0) {
    // Calculate total daily earnings from all workers
    var _daily_total = 0;
    var _active_workers = 0;

    for (var i = 0; i < array_length(crew_members); i++) {
        var _worker = crew_members[i];
        if (instance_exists(_worker) && _worker.is_hired) {
            _daily_total += _worker.daily_earnings;
            _active_workers++;
        }
    }

    // Display crew info
    draw_set_color(c_aqua);
    draw_text(10, 60, "Crew: " + string(_active_workers) + "/" + string(max_crew_size));

    if (_daily_total > 0) {
        draw_set_color(c_yellow);
        draw_text(10, 75, "Today: +$" + string(_daily_total));
    }
}

if (collab_bonus_active) {
    draw_set_color(c_aqua);
    draw_text(10, 80, "+ $" + string(collab_bonus_amount) + " (collab)");
}

if (is_snitch) {
    draw_set_color(c_red);
    var _snitch_mins = floor((snitch_timer / 60) / 60);
    draw_text(10, 100, "SNITCH (" + string(_snitch_mins) + "m left)");
}

// (Removed: top-left jail countdown display)

if (is_jailed) {
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    // Show stunned status prominently if stunned
    if (is_stunned) {
        draw_set_halign(fa_center);
        draw_set_color(c_red);
        draw_text(_cx, _cy - 80, "=== KNOCKED DOWN ===");

        draw_set_color(c_yellow);
        draw_text(_cx, _cy - 50, "Recovering... (" + string(floor(health)) + " / 100 HP)");

        if (health < -50) {
            draw_set_color(c_red);
            draw_text(_cx, _cy - 20, "CRITICAL! Near permadeath!");
        }

        draw_set_color(c_white);
        draw_text(_cx, _cy + 10, "Press [F] to attack while down");

        draw_set_halign(fa_left);
    } else {
        // Normal jail UI (no timer display)
        draw_set_halign(fa_center);
        draw_set_color(c_red);
        draw_text(_cx, _cy - 40, "== JAILED ==");

        draw_set_color(c_aqua);
        draw_text(_cx, _cy + 30, "[F] Melee Attack");

        draw_set_halign(fa_left);
    }
}

// Show commissary food count when in jail
if (room == rm_jail_lobby && commissary_food > 0) {
    draw_set_color(c_orange);
    draw_text(10, 60, "Food: " + string(commissary_food));
}

if (in_danger_zone) {
    draw_set_color(c_yellow);
    draw_text(10, 120, "! DANGER ZONE !");
}

// === MINIMAP ===
if (minimap_visible && !is_jailed && (room == Seattle || room == LA)) {
    var _map_w = 150;
    var _map_h = 100;
    var _map_x = display_get_gui_width() - _map_w - 10;
    var _map_y = display_get_gui_height() - _map_h - 10;
    var _scale_x = _map_w / room_width;
    var _scale_y = _map_h / room_height;

    // Background
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(_map_x, _map_y, _map_x + _map_w, _map_y + _map_h, false);
    draw_set_alpha(1);

    // Border
    draw_set_color(c_white);
    draw_rectangle(_map_x, _map_y, _map_x + _map_w, _map_y + _map_h, true);

    // Player dot (white)
    var _px = _map_x + x * _scale_x;
    var _py = _map_y + y * _scale_y;
    draw_set_color(c_white);
    draw_circle(_px, _py, 3, false);

    // Cop cars (red dots)
    draw_set_color(c_red);
    with (obj_car) {
        if (is_cop) {
            var _cx = _map_x + x * _scale_x;
            var _cy = _map_y + y * _scale_y;
            draw_circle(_cx, _cy, 2, false);
        }
    }

    // Cops on foot (red smaller dots)
    draw_set_color(c_red);
    with (obj_cop) {
        var _cx = _map_x + x * _scale_x;
        var _cy = _map_y + y * _scale_y;
        draw_circle(_cx, _cy, 1.5, false);
    }

    // Crew members (blue dots)
    draw_set_color(c_aqua);
    with (obj_crew_member) {
        if (is_hired) {
            var _cx = _map_x + x * _scale_x;
            var _cy = _map_y + y * _scale_y;
            draw_circle(_cx, _cy, 2, false);
        }
    }

    // NPC customers (green dots)
    draw_set_color(c_lime);
    with (obj_npc_customer) {
        var _cx = _map_x + x * _scale_x;
        var _cy = _map_y + y * _scale_y;
        draw_circle(_cx, _cy, 1, false);
    }

    // Street indicator (dark gray line)
    draw_set_color(c_dkgray);
    var _street_top = _map_y + game_ctrl.street_y_top * _scale_y;
    var _street_bot = _map_y + game_ctrl.street_y_bottom * _scale_y;
    draw_rectangle(_map_x, _street_top, _map_x + _map_w, _street_bot, false);

    // Hospital (white cross, blinks red when bleeding)
    with (obj_hospital) {
        var _hx = _map_x + x * _scale_x;
        var _hy = _map_y + y * _scale_y;
        if (other.is_bleeding && (other.bleed_flash_timer div 15) mod 2 == 0) {
            draw_set_color(c_red);
        } else {
            draw_set_color(c_white);
        }
        draw_rectangle(_hx - 3, _hy - 1, _hx + 3, _hy + 1, false); // Horizontal
        draw_rectangle(_hx - 1, _hy - 3, _hx + 1, _hy + 3, false); // Vertical
    }

    // Label
    draw_set_color(c_gray);
    draw_text(_map_x + 2, _map_y - 14, "[M] Map");
}

// (Removed: top-center mm:ss countdown)
