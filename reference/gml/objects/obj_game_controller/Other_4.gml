// === RESTORE PLAYER DATA AFTER SEAMLESS TRAVEL ===
if (global.travel_active) {
    var _p1 = instance_find(player1, 0);
    if (_p1 != noone) {
        // Restore player position
        _p1.x = global.travel_dest_x;
        _p1.y = global.travel_dest_y;

        // Restore player stats
        _p1.money = global.travel_money;
        _p1.heat_level = global.travel_heat_level;
        _p1.owned_car = global.travel_owned_car;
        _p1.weapon_type = global.travel_weapon_type;
        _p1.has_gun = global.travel_has_gun;
        _p1.weapons_owned = global.travel_weapons_owned;

        // Restore inventory
        _p1.inventory_weed = global.travel_inv_weed;
        _p1.inventory_cocaine = global.travel_inv_cocaine;
        _p1.inventory_heroin = global.travel_inv_heroin;
        _p1.inventory_meth = global.travel_inv_meth;
        _p1.inventory_pills = global.travel_inv_pills;

        // Restore loan state
        _p1.has_active_loan = global.travel_has_active_loan;
        _p1.loan_amount = global.travel_loan_amount;
        _p1.loan_due_day = global.travel_loan_due_day;
        _p1.debt = global.travel_debt;

        // Restore territory
        _p1.has_territory = global.travel_has_territory;
        _p1.territory_x = global.travel_territory_x;
        _p1.territory_y = global.travel_territory_y;

        // Restore crew
        _p1.crew_unlocked = global.travel_crew_unlocked;
        _p1.total_crew_earnings = global.travel_total_crew_earnings;

        // Restore bleed state
        _p1.is_bleeding = global.travel_is_bleeding;
        _p1.bleed_source = global.travel_bleed_source;

        // Reset health separately (use 'with' to access as built-in var)
        with (_p1) { health = global.travel_health; }
    }
    global.travel_active = false;
}

// Room Start event - position players when entering duel room
if (room == rm_duel && game_state == GAME_STATE.DUEL) {
    if (instance_exists(duel_player1)) {
        duel_player1.x = room_width/2 - 100;
        duel_player1.y = room_height/2;
    }
    if (instance_exists(duel_player2)) {
        duel_player2.x = room_width/2 + 100;
        duel_player2.y = room_height/2;
    }
}

// Create city_exit objects for city travel rooms
if (!instance_exists(obj_city_exit)) {
    if (room == Seattle || room == i5 || room == i5_2 || room == i5_3 || room == i5_4 || room == LA) {
        instance_create_layer(room_width - 48, room_height/2, "Instances", obj_city_exit);
    }
}
