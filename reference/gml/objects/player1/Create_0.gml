move_speed = 1.5; 
tilemap = layer_tilemap_get_id("Tiles_col");

// === STATS ===
money =99999;
max_health = 100;
health = max_health;
health_regen_rate = 1;        // HP recovered per regen tick
health_regen_delay = 180;     // Frames between regen ticks (3 seconds at 60fps)
health_regen_timer = 0;       // Timer for regen

// === INVENTORY ===
inventory_weed = 0;
inventory_cocaine = 0;
inventory_heroin = 0;
inventory_meth = 0;
inventory_pills = 0;

// === COMMISSARY ===
commissary_food = 0; // Food items for trading in jail

// === CHAT SYSTEM ===
at_chat_table = noone; // Which table the player is at
chat_active = false; // Whether player is in a chat
typing_active = false; // Whether player is typing a message

// === SNITCH SYSTEM ===
is_snitch = false;
snitch_timer = 0;
snitch_duration = 70 * 60 * 60; // 70 minutes in frames

// Snitch reputation levels (customers flee less over time)
// Level 0: 3/4 flee, Level 1: 1/2 flee, Level 2: 1/4 flee, Level 3: 1/8 flee
snitch_level = 0;
snitch_level_timer = 0;
snitch_level_duration = 3 * 60 * 60; // 3 minutes per level
snitch_flee_chances = [0.75, 0.5, 0.25, 0.125]; // 3/4, 1/2, 1/4, 1/8

// === JAIL ===
is_jailed = false;
// jail timer removed; duration handled by alternate system

// === JAIL MELEE COMBAT ===
is_stunned = false;               // Player is stunned/fallen (HP <= 5)
melee_attack_range = 40;          // Range for melee attacks in jail
melee_damage = 10;                // Damage per melee hit
melee_cooldown = 0;               // Cooldown timer
melee_cooldown_max = 30;          // 0.5 seconds between attacks
stunned_regen_rate = 0.5;         // HP per second while stunned (30 frames = 0.5 sec)
stunned_regen_timer = 0;          // Timer for stunned regen
// === JAYWALKING & DEBT ===
debt = 0;
was_in_street = false;
street_entry_y = 0;
street_entry_x = 0;

// === LOAN SYSTEM ===
has_active_loan = false;
loan_amount = 0;             // Total owed (principal + interest)
loan_due_day = 0;            // In-game day deadline

// === COLLABORATION BONUS ===
collab_bonus_active = false;
collab_bonus_amount = 0;
collab_partner = noone;

// === BLEED / WOUNDED SYSTEM ===
is_bleeding = false;          // True when player is shot and bleeding out
bleed_rate = 0.05;            // HP lost per frame while bleeding (~9 HP/sec)
bleed_flash_timer = 0;        // Timer for red screen flash effect
bleed_source = "";            // What caused the bleed ("driveby", "cop", etc.)

// === HEAT SYSTEM ===
heat_level = 0;            // 0-100, police attention level
heat_decay_timer = 0;      // Counts frames for decay
last_crime_time = 0;       // game_ctrl.time_current when last crime committed

// === DANGER TRACKING ===
in_danger_zone = false;
sell_cooldown = 0;

// === COP STUN ESCAPE ===
stun_input_buffer = [];      // Stores recent directional inputs
stun_input_timer = 0;        // Frame counter for input timing
stun_combo_window = 30;      // Frames allowed to enter the 3-key combo
stun_escape_range = 180;     // Max distance to stun a chasing cop
stun_combo_cooldown = 0;     // Prevents immediate re-use of the combo

// === SPRITE SETUP ===
facing = "down";
image_xscale = -1; // Sprite art faces opposite direction, flip to correct it

// === DUEL ===
in_duel = false;
duel_opponent = noone;
duel_health = 100;
shoot_cooldown = 0;
shoot_cooldown_max = 20;

// === STREET COMBAT ===
in_street_fight = false;  // True when in active gunfight with rival

// === WEAPON SYSTEM ===
// weapon_type: 0=fists, 1=pistol, 2=SMG, 3=shotgun
weapon_type = 0;
has_gun = false; // backward compat: true if weapon_type > 0
weapon_drawn = false; // Must press [P] to draw weapon before shooting
weapons_owned = [true, false, false, false]; // Which weapons player has (fists always owned)

// Weapon stats: [damage, range, cooldown, cost, name]
weapon_stats = [
    {damage: 8,  range: 60,   cooldown: 30, cost: 0,    name: "Fists"},
    {damage: 20, range: 9999, cooldown: 20, cost: 2000, name: "Pistol"},
    {damage: 12, range: 9999, cooldown: 8,  cost: 5000, name: "SMG"},
    {damage: 40, range: 200,  cooldown: 40, cost: 8000, name: "Shotgun"}
];

// === COMBAT STATS (derived from weapon_type) ===
duel_damage = weapon_stats[weapon_type].damage;
duel_attack_range = weapon_stats[weapon_type].range;
shoot_cooldown_max = weapon_stats[weapon_type].cooldown;

// === CUSTOMIZATION ===
// Load saved customization if globals don't exist
if (!variable_global_exists("player_skin_tone")) {
    scr_load_customization();
}

// Skin tone colors for blending
skin_tone_colors = [
    c_white,                       // Light
    make_color_rgb(222, 184, 135), // Medium
    make_color_rgb(139, 90, 43),   // Tan
    make_color_rgb(89, 60, 31)     // Dark
];

// Bandana colors
bandana_colors = [c_red, c_orange, c_blue];

// === TERRITORY SYSTEM ===
territory_x = -1;       // Grid x position of owned territory
territory_y = -1;       // Grid y position of owned territory
territory_color = c_white;  // Color of territory
territory_name = "";    // Name of territory
has_territory = false;  // Whether player owns territory

// === CREW/GANG SYSTEM ===
crew_unlocked = false;         // Unlocked at $100,000
crew_members = [];             // Array of crew member instances
max_crew_size = 2;             // Base: 2 workers (+1 per $50k earned, +1 per trap house)
total_crew_earnings = 0;       // Lifetime earnings from crew
last_recruitment_time = 0;     // When last recruiter approached
recruitment_cooldown = 30 * 60; // 30 seconds real-time between recruiter spawns (1800 frames)

// === AUTO SALE MODE ===
auto_sale_mode = 0; // 0 = Yes (auto-accept), 1 = My Homie (send to worker), 2 = No (refuse)

// === CAR & TRAVEL ===
owned_car = -1;                 // -1=none, 0=Beater, 1=Sedan, 2=Sports
last_city_room = Seattle;       // Room to return to when traveling back
last_city_x = 200;              // X position to return to
last_city_y = 350;              // Y position to return to

// === MINIMAP ===
minimap_visible = true;         // Toggle with [M]

// === PHONE SYSTEM ===
phone_active = false;           // Is player using phone?

// === CITY TRAVEL STATE RESTORE ===
// When traveling between cities, player data is saved to globals
// and restored here since player1 is not persistent
if (variable_global_exists("travel_active") && global.travel_active) {
    global.travel_active = false; // Clear flag so it doesn't repeat

    // Restore position
    x = global.travel_dest_x;
    y = global.travel_dest_y;

    // Restore essential stats
    money = global.travel_money;
    health = global.travel_health;
    heat_level = global.travel_heat_level;
    owned_car = global.travel_owned_car;
    weapon_type = global.travel_weapon_type;
    has_gun = global.travel_has_gun;
    if (variable_global_exists("travel_weapons_owned")) {
        weapons_owned = global.travel_weapons_owned;
    }

    // Restore derived combat stats from weapon
    duel_damage = weapon_stats[weapon_type].damage;
    duel_attack_range = weapon_stats[weapon_type].range;
    shoot_cooldown_max = weapon_stats[weapon_type].cooldown;

    // Restore inventory
    inventory_weed = global.travel_inv_weed;
    inventory_cocaine = global.travel_inv_cocaine;
    inventory_heroin = global.travel_inv_heroin;
    inventory_meth = global.travel_inv_meth;
    inventory_pills = global.travel_inv_pills;

    // Restore loan state
    has_active_loan = global.travel_has_active_loan;
    loan_amount = global.travel_loan_amount;
    loan_due_day = global.travel_loan_due_day;
    debt = global.travel_debt;

    // Restore territory
    has_territory = global.travel_has_territory;
    territory_x = global.travel_territory_x;
    territory_y = global.travel_territory_y;

    // Restore crew
    crew_unlocked = global.travel_crew_unlocked;
    total_crew_earnings = global.travel_total_crew_earnings;

    // Restore bleed state
    if (variable_global_exists("travel_is_bleeding")) {
        is_bleeding = global.travel_is_bleeding;
        bleed_source = global.travel_bleed_source;
        bleed_flash_timer = 0;
    }

    // Restore facing direction
    if (variable_global_exists("travel_facing")) {
        facing = global.travel_facing;
    }

    // Store return info
    last_city_room = global.travel_return_room;
    last_city_x = global.travel_return_x;
    last_city_y = global.travel_return_y;
}

// Flag to indicate player is fully initialized
player_initialized = true;

