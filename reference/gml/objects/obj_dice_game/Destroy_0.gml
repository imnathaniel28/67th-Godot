/// obj_dice_game - Destroy Event

// Clean up all data structures
if (ds_exists(players_in_game, ds_type_list)) {
    ds_list_destroy(players_in_game);
}

if (ds_exists(bets, ds_type_map)) {
    ds_map_destroy(bets);
}

if (ds_exists(bet_types, ds_type_map)) {
    ds_map_destroy(bet_types);
}

if (ds_exists(ground_money_objects, ds_type_list)) {
    // Destroy all ground money objects
    for (var i = 0; i < ds_list_size(ground_money_objects); i++) {
        var _obj = ground_money_objects[| i];
        if (instance_exists(_obj)) {
            instance_destroy(_obj);
        }
    }
    ds_list_destroy(ground_money_objects);
}
