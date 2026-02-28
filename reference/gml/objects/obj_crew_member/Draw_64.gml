// === RECRUITMENT DIALOG ===
if (state == "recruiting_waiting") {
    // Draw dialog box in center of screen
    var _box_width = 600;
    var _box_height = 400;
    var _box_x = (display_get_gui_width() - _box_width) / 2;
    var _box_y = (display_get_gui_height() - _box_height) / 2;

    // Background
    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(_box_x, _box_y, _box_x + _box_width, _box_y + _box_height, false);

    // Border
    draw_set_color(c_yellow);
    draw_set_alpha(1);
    draw_rectangle(_box_x, _box_y, _box_x + _box_width, _box_y + _box_height, true);
    draw_rectangle(_box_x + 2, _box_y + 2, _box_x + _box_width - 2, _box_y + _box_height - 2, true);

    // Title
    draw_set_color(c_yellow);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(_box_x + _box_width/2, _box_y + 20, "HUSTLER ASKING FOR WORK");

    // Worker intro
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    var _text_x = _box_x + 30;
    var _text_y = _box_y + 60;

    draw_text(_text_x, _text_y, "Yo, I heard you getting money.");
    draw_text(_text_x, _text_y + 30, "Name's " + worker_name + ". Let me work for you.");

    // Stats display
    draw_set_color(c_aqua);
    draw_text(_text_x, _text_y + 80, "STATS:");
    draw_set_color(c_white);
    draw_text(_text_x + 20, _text_y + 110, "Sales Skill:      " + string(sales_skill) + "/10");
    draw_text(_text_x + 20, _text_y + 135, "Heat Management:  " + string(heat_management) + "/10");
    draw_text(_text_x + 20, _text_y + 160, "Loyalty:          " + string(loyalty) + "/10");
    draw_text(_text_x + 20, _text_y + 185, "Stamina:          " + string(stamina) + "/10");

    // Daily wage calculation
    draw_set_color(c_lime);
    draw_text(_text_x, _text_y + 220, "Daily Wage: $" + string(daily_wage));

    // Options
    draw_set_color(c_yellow);
    draw_text(_text_x, _text_y + 260, "CHOOSE:");

    draw_set_color(c_white);
    draw_text(_text_x + 20, _text_y + 290, "[1] Hire Now ($500 signing bonus)");
    draw_text(_text_x + 20, _text_y + 315, "[2] Test Run (1 day trial - FREE)");
    draw_text(_text_x + 20, _text_y + 340, "[3] Reject");

    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);

    // === HANDLE INPUT ===
    // Check for key press
    if (keyboard_check_pressed(ord("1"))) {
        // HIRE NOW
        if (target_player != noone && target_player.money >= 500) {
            target_player.money -= 500;

            // Transition to hired state
            owner = target_player;
            is_hired = true;
            is_test_run = false;
            territory_x = target_player.x;
            territory_y = target_player.y;
            state = "roaming";
            status_color = c_lime;

            // Add to player's crew array
            array_push(target_player.crew_members, id);

            show_debug_message("Hired " + worker_name + " for $500!");
        } else {
            show_debug_message("Not enough money to hire! Need $500");
        }
    } else if (keyboard_check_pressed(ord("2"))) {
        // TEST RUN
        // Transition to hired state with test flag
        owner = target_player;
        is_hired = true;
        is_test_run = true;
        test_run_end_time = game_ctrl.time_current + game_ctrl.day_length; // 1 day from now
        territory_x = target_player.x;
        territory_y = target_player.y;
        state = "roaming";
        status_color = c_lime;

        // Add to player's crew array
        array_push(target_player.crew_members, id);

        show_debug_message(worker_name + " started test run! Ends in 1 in-game day.");
    } else if (keyboard_check_pressed(ord("3"))) {
        // REJECT
        show_debug_message("Rejected " + worker_name);
        leave_direction = random(360);
        state = "rejected";
    }
}
