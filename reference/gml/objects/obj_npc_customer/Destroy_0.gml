// Clean up chase slot if we were chasing when destroyed
if (is_chasing && game_ctrl.customer_chasing_player == id) {
    game_ctrl.customer_chasing_player = noone;
}
