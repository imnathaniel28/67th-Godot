// === LOAN SHARK - Draw GUI ===
if (player_nearby) {
    var _p1 = instance_find(player1, 0);
    var _cx = display_get_gui_width() / 2;
    var _cy = display_get_gui_height() / 2;

    if (!menu_open) {
        // Simple prompt when nearby but menu closed
        var _prompt_y = display_get_gui_height() - 100;
        draw_set_halign(fa_center);
        draw_set_color(c_black);
        draw_set_alpha(0.7);
        draw_rectangle(_cx - 120, _prompt_y - 20, _cx + 120, _prompt_y + 20, false);
        draw_set_alpha(1);
        draw_set_color(c_lime);
        draw_text(_cx, _prompt_y - 10, "[E] Loan Shark");
        draw_set_halign(fa_left);
    } else {
        // Full loan menu
        var _menu_w = 320;
        var _menu_h = 300;

        // Background
        draw_set_color(c_black);
        draw_set_alpha(0.85);
        draw_rectangle(_cx - _menu_w/2, _cy - _menu_h/2, _cx + _menu_w/2, _cy + _menu_h/2, false);
        draw_set_alpha(1);

        // Border
        draw_set_color(c_yellow);
        draw_rectangle(_cx - _menu_w/2, _cy - _menu_h/2, _cx + _menu_w/2, _cy + _menu_h/2, true);

        // Title
        draw_set_halign(fa_center);
        draw_set_color(c_yellow);
        draw_text(_cx, _cy - _menu_h/2 + 10, "=== LOAN SHARK ===");

        // Interest rate info
        draw_set_color(c_red);
        draw_text(_cx, _cy - _menu_h/2 + 30, "Interest: " + string(interest_rate * 100) + "% | Repay in " + string(loan_duration_days) + " days");

        // Player money display
        if (_p1 != noone) {
            draw_set_color(c_lime);
            draw_text(_cx, _cy - _menu_h/2 + 50, "Your Cash: $" + string(_p1.money));
        }

        // Current debt status
        if (_p1 != noone && _p1.has_active_loan) {
            draw_set_color(c_red);
            draw_text(_cx, _cy - _menu_h/2 + 70, "ACTIVE LOAN: $" + string(_p1.loan_amount));
            draw_set_color(c_orange);
            draw_text(_cx, _cy - _menu_h/2 + 88, "Due by Day " + string(_p1.loan_due_day));
        }

        // Loan options list
        var _start_y = _cy - 30;
        draw_set_halign(fa_center);

        if (_p1 != noone && _p1.has_active_loan) {
            // Show repay option instead of loan list
            draw_set_color(c_yellow);
            draw_text(_cx, _start_y, "You have an active loan.");
            draw_set_color(c_aqua);
            draw_text(_cx, _start_y + 24, "Debt: $" + string(_p1.loan_amount));

            if (_p1.money >= _p1.loan_amount) {
                draw_set_color(c_lime);
                draw_text(_cx, _start_y + 52, "[R] Repay Loan ($" + string(_p1.loan_amount) + ")");
            } else {
                draw_set_color(c_red);
                draw_text(_cx, _start_y + 52, "Need $" + string(_p1.loan_amount) + " to repay");
            }
        } else {
            // Show loan options
            draw_set_color(c_white);
            draw_text(_cx, _start_y - 20, "Select a loan amount:");

            for (var _i = 0; _i < array_length(loan_options); _i++) {
                var _amount = loan_options[_i];
                var _owed = _amount + (_amount * interest_rate);
                var _is_selected = (selected_loan == _i);
                var _item_y = _start_y + (_i * 36);

                // Selection highlight
                if (_is_selected) {
                    draw_set_color(c_yellow);
                    draw_set_alpha(0.3);
                    draw_rectangle(_cx - _menu_w/2 + 10, _item_y - 2, _cx + _menu_w/2 - 10, _item_y + 30, false);
                    draw_set_alpha(1);
                }

                // Loan amount and repayment
                draw_set_halign(fa_left);
                draw_set_color(_is_selected ? c_white : c_silver);
                draw_text(_cx - _menu_w/2 + 20, _item_y, "Borrow: $" + string(_amount));
                draw_set_color(_is_selected ? c_red : c_maroon);
                draw_text(_cx - _menu_w/2 + 20, _item_y + 14, "Repay:  $" + string(_owed));
            }
        }

        // Controls at bottom
        draw_set_halign(fa_center);
        draw_set_color(c_gray);
        if (_p1 != noone && _p1.has_active_loan) {
            draw_text(_cx, _cy + _menu_h/2 - 20, "[R] Repay  [Q] Close");
        } else {
            draw_text(_cx, _cy + _menu_h/2 - 20, "[W/S] Select  [E] Borrow  [Q] Close");
        }

        draw_set_halign(fa_left);
    }
}
