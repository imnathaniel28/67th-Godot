/// @function _seamless_city_travel(dest_room, dest_x, dest_y)
/// @description Seamlessly transitions player to another city room at the given position
/// @param {Asset.GMRoom} dest_room  The room to travel to
/// @param {real} dest_x  X position to spawn at in the destination room
/// @param {real} dest_y  Y position to spawn at in the destination room

function _seamless_city_travel(_dest_room, _dest_x, _dest_y) {
    // === SAVE PLAYER STATE TO GLOBALS ===
    global.travel_active = true;
    
    global.travel_dest_x = _dest_x;
    global.travel_dest_y = _dest_y;
    
    global.travel_return_room = room;
    global.travel_return_x = x;
    global.travel_return_y = y;

    // Save essential player stats
    global.travel_money = money;
    global.travel_health = health;
    global.travel_heat_level = heat_level;
    global.travel_owned_car = owned_car;
    global.travel_weapon_type = weapon_type;
    global.travel_has_gun = has_gun;
    global.travel_weapons_owned = weapons_owned;

    // Save inventory
    global.travel_inv_weed = inventory_weed;
    global.travel_inv_cocaine = inventory_cocaine;
    global.travel_inv_heroin = inventory_heroin;
    global.travel_inv_meth = inventory_meth;
    global.travel_inv_pills = inventory_pills;

    // Save loan state
    global.travel_has_active_loan = has_active_loan;
    global.travel_loan_amount = loan_amount;
    global.travel_loan_due_day = loan_due_day;
    global.travel_debt = debt;

    // Save territory
    global.travel_has_territory = has_territory;
    global.travel_territory_x = territory_x;
    global.travel_territory_y = territory_y;

    // Save crew
    global.travel_crew_unlocked = crew_unlocked;
    global.travel_total_crew_earnings = total_crew_earnings;

    // Save bleed state
    global.travel_is_bleeding = is_bleeding;
    global.travel_bleed_source = bleed_source;

    // Save facing direction
    global.travel_facing = facing;

    // Get destination name for notification
    var _dest_name = "Unknown";
    if (_dest_room == Seattle) _dest_name = "Seattle";
    else if (_dest_room == i5) _dest_name = "Interstate 5";
    else if (_dest_room == i5_2) _dest_name = "Interstate 5 (Mile 200)";
    else if (_dest_room == i5_3) _dest_name = "Interstate 5 (Mile 400)";
    else if (_dest_room == i5_4) _dest_name = "Interstate 5 (Mile 600)";
    else if (_dest_room == LA) _dest_name = "Los Angeles";

    scr_notify("Entering " + _dest_name + "...", c_aqua);

    // Go to destination room
    room_goto(_dest_room);
}
