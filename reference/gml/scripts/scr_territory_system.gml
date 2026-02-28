// === TERRITORY SYSTEM SCRIPTS ===

/// @function scr_claim_territory(player, block_x, block_y, color)
/// @description Claims a territory block for a player (free in low-income area)
/// @param {instance} player - The player instance claiming the territory
/// @param {real} block_x - The x coordinate of the block in the grid
/// @param {real} block_y - The y coordinate of the block in the grid
/// @param {constant} color - The color to assign to this territory
function scr_claim_territory(_player, _block_x, _block_y, _color) {
    if (!instance_exists(territory_ctrl)) {
        show_debug_message("Territory controller not found!");
        return false;
    }

    // Check if block is unclaimed
    if (territory_ctrl.territory_grid[_block_x][_block_y].owner != noone) {
        return false;
    }

    // Prompt for territory name
    var _territory_name = get_string("Name your territory:", "My Block");
    if (_territory_name == "") {
        _territory_name = "Block " + string(_block_x) + "-" + string(_block_y);
    }

    // Claim the territory
    territory_ctrl.territory_grid[_block_x][_block_y].owner = _player;
    territory_ctrl.territory_grid[_block_x][_block_y].color = _color;
    territory_ctrl.territory_grid[_block_x][_block_y].name = _territory_name;
    territory_ctrl.territory_grid[_block_x][_block_y].alpha = 0.5;

    // Store territory info in player
    _player.territory_x = _block_x;
    _player.territory_y = _block_y;
    _player.territory_color = _color;
    _player.territory_name = _territory_name;
    _player.has_territory = true;

    show_debug_message("Player claimed territory: " + _territory_name + " at (" + string(_block_x) + ", " + string(_block_y) + ")");
    return true;
}

/// @function scr_relocate_territory(player, new_block_x, new_block_y)
/// @description Relocates a player's territory to a new block (costs 10% tax)
/// @param {instance} player - The player instance relocating
/// @param {real} new_block_x - The x coordinate of the new block
/// @param {real} new_block_y - The y coordinate of the new block
function scr_relocate_territory(_player, _new_block_x, _new_block_y) {
    if (!instance_exists(territory_ctrl)) {
        show_debug_message("Territory controller not found!");
        return false;
    }

    // Check if player has a territory
    if (!variable_instance_exists(_player, "territory_x") || _player.territory_x == -1) {
        return false;
    }

    // Check if new block is unclaimed
    if (territory_ctrl.territory_grid[_new_block_x][_new_block_y].owner != noone) {
        return false;
    }

    // Clear old territory
    var _old_x = _player.territory_x;
    var _old_y = _player.territory_y;
    territory_ctrl.territory_grid[_old_x][_old_y].owner = noone;
    territory_ctrl.territory_grid[_old_x][_old_y].color = c_white;
    territory_ctrl.territory_grid[_old_x][_old_y].name = "Unclaimed";
    territory_ctrl.territory_grid[_old_x][_old_y].alpha = 0.3;

    // Claim new territory with same color and name
    territory_ctrl.territory_grid[_new_block_x][_new_block_y].owner = _player;
    territory_ctrl.territory_grid[_new_block_x][_new_block_y].color = _player.territory_color;
    territory_ctrl.territory_grid[_new_block_x][_new_block_y].name = _player.territory_name;
    territory_ctrl.territory_grid[_new_block_x][_new_block_y].alpha = 0.5;

    // Update player's territory coordinates
    _player.territory_x = _new_block_x;
    _player.territory_y = _new_block_y;

    show_debug_message("Player relocated territory to (" + string(_new_block_x) + ", " + string(_new_block_y) + ")");
    return true;
}

/// @function scr_update_territory_name(player, new_name)
/// @description Updates the name of a player's territory
/// @param {instance} player - The player instance
/// @param {string} new_name - The new name for the territory
function scr_update_territory_name(_player, _new_name) {
    if (!instance_exists(territory_ctrl)) {
        return false;
    }

    if (!variable_instance_exists(_player, "territory_x") || _player.territory_x == -1) {
        return false;
    }

    // Update name in grid and player
    _player.territory_name = _new_name;
    territory_ctrl.territory_grid[_player.territory_x][_player.territory_y].name = _new_name;

    return true;
}

/// @function scr_get_territory_owner(block_x, block_y)
/// @description Gets the owner of a territory block
/// @param {real} block_x - The x coordinate of the block
/// @param {real} block_y - The y coordinate of the block
/// @return {instance} The owner instance or noone if unclaimed
function scr_get_territory_owner(_block_x, _block_y) {
    if (!instance_exists(territory_ctrl)) {
        return noone;
    }

    if (_block_x < 0 || _block_x >= territory_ctrl.blocks_wide ||
        _block_y < 0 || _block_y >= territory_ctrl.blocks_tall) {
        return noone;
    }

    return territory_ctrl.territory_grid[_block_x][_block_y].owner;
}
