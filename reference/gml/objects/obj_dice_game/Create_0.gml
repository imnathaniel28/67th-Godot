/// obj_dice_game - Create Event
/// Street craps game manager object

// === DISPLAY ===
show_prompt = false;
table_name = "Dice Game";

// === GAME STATE MACHINE ===
enum DICE_STATE {
    IDLE,           // No game active, waiting for players
    WAITING_BETS,   // Collecting bets before roll
    ROLLING,        // Dice animation in progress
    COME_OUT,       // First roll phase
    POINT_PHASE,    // Trying to hit point or 7
    PAYOUT,         // Distributing winnings
    POLICE_WARNING, // 3-second warning before bust
    BUSTED          // Police have arrived
}
dice_state = DICE_STATE.IDLE;

// === PLAYER MANAGEMENT ===
max_players = 4;
players_in_game = ds_list_create();  // Player/NPC instances in game
current_shooter_index = 0;           // Index in players_in_game
current_shooter = noone;

// === BETTING ===
bet_min = 100;
bet_max = 1000000;
bets = ds_map_create();              // Map: player_id -> bet_amount
bet_types = ds_map_create();         // Map: player_id -> "pass" or "dont_pass"
pot_total = 0;                       // Total money on ground

// === DICE VALUES ===
die1 = 0;
die2 = 0;
dice_total = 0;
point_value = 0;                     // The "point" number (4,5,6,8,9,10)

// === DICE ANIMATION ===
roll_timer = 0;
roll_duration = 60;                  // 1 second at 60fps
is_rolling = false;
dice_anim_frame = 0;

// === GROUND MONEY (visual pile) ===
ground_money_objects = ds_list_create();

// === POLICE BUST SYSTEM ===
bust_threshold = 10000;              // If pot >= this, police ROB instead of arrest
warning_timer = 0;
warning_duration = 180;              // 3 seconds at 60fps
next_bust_time = 0;                  // Frame count for next bust
busts_today = 0;                     // How many busts have occurred today
max_busts_per_day = 2;

// Initialize first bust time (random within day)
// Schedule bust for random time in remaining day
var _day_length = obj_game_controller.day_length;
var _remaining = _day_length;
var _offset = irandom_range(floor(_remaining * 0.1), floor(_remaining * 0.9));
next_bust_time = _offset;

// === ROBBERY SYSTEM ===
robbery_in_progress = false;
robbery_target = noone;
robber = noone;

// === PROXIMITY ===
join_range = 100;
interaction_range = 80;

// === MESSAGES ===
game_message = "";
message_timer = 0;

// === VICTORY SPEECH BUBBLE ===
victory_timer = 0;
victory_message = "";
victory_phrases = [
    "Let's go!",
    "Easy money!",
    "That's what I'm talking about!",
    "Pay me!",
    "Winner winner!",
    "Run it back!"
];
