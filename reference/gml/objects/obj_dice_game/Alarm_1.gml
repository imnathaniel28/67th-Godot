/// obj_dice_game - Alarm 1 (Reset after bust)

// Reset the game after police bust
dice_state = DICE_STATE.IDLE;
ds_list_clear(players_in_game);
current_shooter = noone;
