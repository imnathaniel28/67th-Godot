// === TERRITORY CONTROLLER STEP EVENT ===

// Handle player input for claiming/relocating territory
var _player = instance_find(player1, 0);
if (_player != noone && !_player.is_jailed && !_player.in_duel) {

    // Check if player presses T key to open territory menu
    if (keyboard_check_pressed(ord("T"))) {
        if (!showing_claim_ui && !showing_relocate_ui) {
            // Check if player has a territory
            if (variable_instance_exists(_player, "territory_x") && _player.territory_x != -1) {
                // Player has territory, show relocate menu
                showing_relocate_ui = true;
                claiming_player = _player;
            } else {
                // Player doesn't have territory, show claim menu
                showing_claim_ui = true;
                claiming_player = _player;
                selected_color_index = 0;
            }
        } else {
            // Close menus
            showing_claim_ui = false;
            showing_relocate_ui = false;
            claiming_player = noone;
        }
    }

    // Handle territory claiming UI
    if (showing_claim_ui && claiming_player != noone) {
        // Get mouse position in world coordinates
        var _mx = mouse_x;
        var _my = mouse_y;

        // Convert to block coordinates
        var _block_x = floor((_mx - neighborhood_x) / block_size);
        var _block_y = floor((_my - neighborhood_y) / block_size);

        // Check if mouse is within bounds
        if (_block_x >= 0 && _block_x < blocks_wide &&
            _block_y >= 0 && _block_y < blocks_tall) {
            selected_block_x = _block_x;
            selected_block_y = _block_y;

            // Check if block is unclaimed and player clicks
            if (mouse_check_button_pressed(mb_left)) {
                if (territory_grid[_block_x][_block_y].owner == noone) {
                    // Claim this territory
                    scr_claim_territory(claiming_player, _block_x, _block_y,
                                       available_colors[selected_color_index]);
                    showing_claim_ui = false;
                    claiming_player = noone;
                }
            }
        }

        // Color selection with number keys 1-9
        for (var i = 1; i <= 9; i++) {
            if (keyboard_check_pressed(ord(string(i)))) {
                if (i - 1 < array_length(available_colors)) {
                    selected_color_index = i - 1;
                }
            }
        }
    }

    // Handle territory relocation UI
    if (showing_relocate_ui && claiming_player != noone) {
        // Get mouse position
        var _mx = mouse_x;
        var _my = mouse_y;

        // Convert to block coordinates
        var _block_x = floor((_mx - neighborhood_x) / block_size);
        var _block_y = floor((_my - neighborhood_y) / block_size);

        // Check if mouse is within bounds
        if (_block_x >= 0 && _block_x < blocks_wide &&
            _block_y >= 0 && _block_y < blocks_tall) {
            selected_block_x = _block_x;
            selected_block_y = _block_y;

            // Check if block is unclaimed and player clicks
            if (mouse_check_button_pressed(mb_left)) {
                if (territory_grid[_block_x][_block_y].owner == noone) {
                    // Calculate relocation tax
                    var _tax = floor(claiming_player.money * relocation_tax_rate);

                    if (claiming_player.money >= _tax) {
                        // Pay tax and relocate
                        claiming_player.money -= _tax;
                        scr_relocate_territory(claiming_player, _block_x, _block_y);
                        showing_relocate_ui = false;
                        claiming_player = noone;
                    }
                }
            }
        }
    }
}
