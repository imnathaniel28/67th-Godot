// Script: scr_arrest_player
// Description: Handles police stop and search with three scenarios
function scr_arrest_player(target) {
    if (!instance_exists(target)) return;
    if (target.is_jailed) return; // Already in jail

    // Calculate total drugs in inventory
    var _total_drugs = target.inventory_weed +
                       target.inventory_cocaine +
                       target.inventory_heroin +
                       target.inventory_meth +
                       target.inventory_pills;

    // SCENARIO 1: No drugs - Fine only
    if (_total_drugs <= 0) {
        var _fine = 100;
        target.money = max(0, target.money - _fine);
        target.debt += max(0, _fine - target.money); // Add to debt if can't afford

        show_debug_message("Player stopped: No drugs found. Fined $" + string(_fine));

        // Show popup notification (will be created in game controller)
        if (instance_exists(obj_game_controller)) {
            obj_game_controller.showing_fine_popup = true;
            obj_game_controller.fine_amount = _fine;
            obj_game_controller.fined_player = target;
        }
        return;
    }

    // SCENARIO 2: Has drugs but less than $1000 - Jail for 1 week
    if (target.money < 1000) {
        // Confiscate all drugs
        var _confiscated_value = (_total_drugs * 50); // Rough value estimate
        target.inventory_weed = 0;
        target.inventory_cocaine = 0;
        target.inventory_heroin = 0;
        target.inventory_meth = 0;
        target.inventory_pills = 0;

        // Send to jail for 1 week (7 in-game days) - timer handling removed
        target.is_jailed = true;

        // Give player commissary food when entering jail (1-3 items)
        target.commissary_food = irandom_range(1, 3);

        show_debug_message("Player arrested: Drugs found. Going to jail for 1 week. Drugs confiscated worth $" + string(_confiscated_value));

        // Update game controller jail UI
        if (instance_exists(obj_game_controller)) {
            obj_game_controller.jailed_player = target;
            obj_game_controller.jailed_player_scan_needed = false; // Don't need to scan, we just set it
            obj_game_controller.confiscated_money = _confiscated_value;
            obj_game_controller.game_state = GAME_STATE.JAIL;
            show_debug_message("obj_game_controller: jailed_player set in scr_arrest_player -> " + string(target));
        }

        // Teleport player to jail lobby
        room_goto(rm_jail_lobby);
        with (target) {
            x = 400; // Center of jail lobby entrance
            y = 500; // Near bottom (entrance area)
        }

        return;
    }

    // SCENARIO 3: Has drugs AND $1000+ - Rob and beat up, then release
    if (target.money >= 1000 && _total_drugs > 0) {
        // Take all money
        var _stolen_money = target.money;
        target.money = 0;

        // Beat up (reduce health significantly)
        target.health = max(10, target.health - 50); // Take 50 damage, but leave at least 10 HP

        // Confiscate all drugs
        target.inventory_weed = 0;
        target.inventory_cocaine = 0;
        target.inventory_heroin = 0;
        target.inventory_meth = 0;
        target.inventory_pills = 0;

        show_debug_message("Player robbed by corrupt cops: Lost $" + string(_stolen_money) + ", took 50 damage, drugs confiscated. Released.");

        // Show robbery popup (will create this UI element)
        if (instance_exists(obj_game_controller)) {
            obj_game_controller.showing_robbery_popup = true;
            obj_game_controller.robbery_money_lost = _stolen_money;
            obj_game_controller.robbery_victim = target;
        }
        return;
    }
}
