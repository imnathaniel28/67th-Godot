// === LOAN SHARK - Step ===
var _p1 = instance_find(player1, 0);
player_nearby = false;

if (_p1 != noone) {
    var _dist = point_distance(x, y, _p1.x, _p1.y);
    if (_dist < 64) {
        player_nearby = true;

        if (!menu_open) {
            // Press E to open loan menu
            if (keyboard_check_pressed(ord("E")) && game_ctrl.game_state == GAME_STATE.PLAYING) {
                menu_open = true;
                selected_loan = 0;
            }
        } else {
            // Menu is open - navigate loan options with W/S
            if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
                selected_loan = max(0, selected_loan - 1);
            }
            if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
                selected_loan = min(array_length(loan_options) - 1, selected_loan + 1);
            }

            // E to take out a loan
            if (keyboard_check_pressed(ord("E"))) {
                if (!_p1.has_active_loan) {
                    var _amount = loan_options[selected_loan];
                    var _owed = _amount + (_amount * interest_rate);

                    // Give the player the loan money
                    _p1.money += _amount;
                    _p1.loan_amount = _owed;
                    _p1.loan_due_day = game_ctrl.day_current + loan_duration_days;
                    _p1.has_active_loan = true;

                    scr_notify("Borrowed $" + string(_amount) + "! Owe $" + string(_owed) + " in " + string(loan_duration_days) + " days", c_yellow);
                    menu_open = false;
                } else {
                    scr_notify("You already have an active loan! Pay it off first.", c_red);
                }
            }

            // R to repay loan while menu is open
            if (keyboard_check_pressed(ord("R"))) {
                if (_p1.has_active_loan) {
                    if (_p1.money >= _p1.loan_amount) {
                        _p1.money -= _p1.loan_amount;
                        scr_notify("Loan repaid! ($" + string(_p1.loan_amount) + ")", c_lime);
                        _p1.loan_amount = 0;
                        _p1.loan_due_day = 0;
                        _p1.has_active_loan = false;
                        menu_open = false;
                    } else {
                        scr_notify("Not enough money! Need $" + string(_p1.loan_amount), c_red);
                    }
                } else {
                    scr_notify("You don't have an active loan.", c_gray);
                }
            }

            // Q or Escape to close menu
            if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("Q"))) {
                menu_open = false;
            }
        }
    } else {
        menu_open = false;
    }
}
