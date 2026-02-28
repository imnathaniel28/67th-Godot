/// scr_notify(message, color)
/// Adds a toast notification to the on-screen queue
function scr_notify(_message, _color) {
    if (!instance_exists(obj_game_controller)) return;

    var _toast = {
        text: _message,
        color: _color,
        timer: 180,        // 3 seconds at 60fps
        alpha: 0,          // Start invisible (fade in)
        y_offset: 20       // Start offset (slide in)
    };
    array_push(game_ctrl.notification_queue, _toast);
}

/// phone_add_message(from, text)
/// Adds a message to the phone inbox
function phone_add_message(_from, _text) {
    var _phone = instance_find(obj_phone_controller, 0);
    if (_phone == noone) return;

    var _time_str = "Day " + string(game_ctrl.day_current);
    array_insert(_phone.messages, 0, {from: _from, text: _text, time: _time_str});
    _phone.unread_count++;

    // Cap messages at 20
    if (array_length(_phone.messages) > 20) {
        array_delete(_phone.messages, 20, array_length(_phone.messages) - 20);
    }
}
