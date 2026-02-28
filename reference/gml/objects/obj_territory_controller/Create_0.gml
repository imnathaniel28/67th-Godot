// === TERRITORY CONTROL SYSTEM ===
// Manages zone ownership in the low-income neighborhood

// Grid settings for territory blocks
block_size = 64; // Size of each territory block in pixels
blocks_wide = 20; // Number of blocks horizontally
blocks_tall = 12; // Number of blocks vertically

// Low-income neighborhood bounds (adjust based on your map)
neighborhood_x = 64;
neighborhood_y = 448; // Bottom half of map for low-income area
neighborhood_width = blocks_wide * block_size;
neighborhood_height = blocks_tall * block_size;

// Territory grid - stores owner and color for each block
// Format: territory_grid[x][y] = {owner: player_id, color: c_color, name: "string"}
territory_grid = [];
for (var i = 0; i < blocks_wide; i++) {
    territory_grid[i] = [];
    for (var j = 0; j < blocks_tall; j++) {
        territory_grid[i][j] = {
            owner: noone,
            color: c_white,
            name: "Unclaimed",
            alpha: 0.3
        };
    }
}

// UI state
showing_claim_ui = false;
showing_relocate_ui = false;
selected_block_x = -1;
selected_block_y = -1;
claiming_player = noone;

// Color palette for players to choose from
available_colors = [
    c_red, c_blue, c_green, c_yellow,
    c_purple, c_orange, c_aqua, c_lime,
    make_color_rgb(255, 192, 203), // Pink
    make_color_rgb(128, 0, 128),   // Purple
    make_color_rgb(255, 165, 0),   // Orange
    make_color_rgb(0, 255, 255)    // Cyan
];

// Selected color for claiming
selected_color_index = 0;

// Relocation tax rate
relocation_tax_rate = 0.10; // 10% of player's cash

// Global reference
globalvar territory_ctrl;
territory_ctrl = id;
