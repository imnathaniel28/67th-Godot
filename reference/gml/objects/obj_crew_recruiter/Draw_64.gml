// === RECRUITMENT DIALOG ===
if (state == "talking" || state == "waiting") {
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
    draw_text(_box_x + _box_width/2, _box_y + 20, "RECRUITMENT OPPORTUNITY");

    // Recruiter intro
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    var _text_x = _box_x + 30;
    var _text_y = _box_y + 60;

    draw_text(_text_x, _text_y, "Yo, I heard you getting money.");
    draw_text(_text_x, _text_y + 30, "Name's " + recruiter_name + ". Let me work for you.");

    // Stats display
    draw_set_color(c_aqua);
    draw_text(_text_x, _text_y + 80, "STATS:");
    draw_set_color(c_white);
    draw_text(_text_x + 20, _text_y + 110, "Sales Skill:      " + string(sales_skill) + "/10");
    draw_text(_text_x + 20, _text_y + 135, "Heat Management:  " + string(heat_management) + "/10");
    draw_text(_text_x + 20, _text_y + 160, "Loyalty:          " + string(loyalty) + "/10");
    draw_text(_text_x + 20, _text_y + 185, "Stamina:          " + string(stamina) + "/10");

    // Daily wage calculation
    var _wage = 200 + (sales_skill * 30);
    draw_set_color(c_lime);
    draw_text(_text_x, _text_y + 220, "Daily Wage: $" + string(_wage));

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
    if (state == "waiting") {
        // DEBUG: Show that we're checking for input
        draw_set_color(c_lime);
        draw_text(_box_x + 10, _box_y + _box_height - 20, "State: WAITING (press 1/2/3)");

        // Check for key press
        if (keyboard_check_pressed(ord("1"))) {
            show_debug_message("DEBUG: Key [1] pressed!");
            // HIRE NOW
            if (target_player != noone && target_player.money >= 500) {
                target_player.money -= 500;

                // Create crew member
                var _new_worker = instance_create_layer(x, y, "Instances", obj_crew_member);
                _new_worker.owner = target_player;
                _new_worker.worker_name = recruiter_name;
                _new_worker.sales_skill = sales_skill;
                _new_worker.heat_management = heat_management;
                _new_worker.loyalty = loyalty;
                _new_worker.stamina = stamina;
                _new_worker.appearance_skin = appearance_skin;
                _new_worker.appearance_bandana = appearance_bandana;
                _new_worker.is_test_run = false;
                _new_worker.territory_x = target_player.x;
                _new_worker.territory_y = target_player.y;

                // Add to player's crew array
                array_push(target_player.crew_members, _new_worker);

                show_debug_message("Hired " + recruiter_name + " for $500!");

                // Leave in random direction
                leave_direction = random(360);
                state = "leaving";
            } else {
                show_debug_message("Not enough money to hire! Need $500");
            }
        } else if (keyboard_check_pressed(ord("2"))) {
            show_debug_message("DEBUG: Key [2] pressed!");
            // TEST RUN
            // Create crew member with test run flag
            var _new_worker = instance_create_layer(x, y, "Instances", obj_crew_member);
            _new_worker.owner = target_player;
            _new_worker.worker_name = recruiter_name;
            _new_worker.sales_skill = sales_skill;
            _new_worker.heat_management = heat_management;
            _new_worker.loyalty = loyalty;
            _new_worker.stamina = stamina;
            _new_worker.appearance_skin = appearance_skin;
            _new_worker.appearance_bandana = appearance_bandana;
            _new_worker.is_test_run = true;
            _new_worker.test_run_end_time = game_ctrl.time_current + game_ctrl.day_length; // 1 day from now
            _new_worker.territory_x = target_player.x;
            _new_worker.territory_y = target_player.y;

            // Add to player's crew array
            array_push(target_player.crew_members, _new_worker);

            show_debug_message(recruiter_name + " started test run! Ends in 1 in-game day.");

            // Leave in random direction
            leave_direction = random(360);
            state = "leaving";
        } else if (keyboard_check_pressed(ord("3"))) {
            show_debug_message("DEBUG: Key [3] pressed!");
            // REJECT
            show_debug_message("Rejected " + recruiter_name);
            leave_direction = random(360);
            state = "leaving";
        }
    }
}
