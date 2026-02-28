// === DECREMENT INTERCOM TIMER ===
if (intercom_timer > 0) intercom_timer--;

// === CHECK FOR PLAYER ===
var _player = instance_nearest(x, y, player1);
show_prompt = false;

if (_player != noone && _player.is_jailed) {
    var _dist = point_distance(x, y, _player.x, _player.y);

    if (_dist < 48) { // Player within 48 pixels
        show_prompt = true;

        // Press E to exit jail (timer removed; exit allowed by interaction)
        if (keyboard_check_pressed(ord("E"))) {
            // Release from jail
            _player.is_jailed = false;

            // Reset announcement state
            announcement_played = false;
            intercom_message = "";
            intercom_timer = 0;

            // Return to main world
            room_goto(Seattle);

            // Position player at default spawn point
            with (player1) {
                x = 600;
                y = 500;
            }

            // Reset game state
            if (instance_exists(obj_game_controller)) {
                obj_game_controller.game_state = GAME_STATE.PLAYING;
            }
        }
    }
}

// Reset announcement flag if player is no longer jailed (edge case)
if (_player != noone && !_player.is_jailed) {
    announcement_played = false;
}
