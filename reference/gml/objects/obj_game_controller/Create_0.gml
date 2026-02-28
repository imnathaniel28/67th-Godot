//===WINDOW===
window_set_fullscreen(false);
//window_set_rectangle(800, 300, 2732, 1536);
//window_set_rectangle(800, 300, 2560, 1440);
//window_set_rectangle(200, 100, 1920, 1080);
window_set_rectangle(100, 40, 1600, 900);
//window_set_rectangle(800, 300, 1366, 768);

// === TIME SYSTEM ===
day_length = 5 * 60 * 60; // 5 minutes in frames (60 fps) = 18000 frames
week_length = day_length * 7;

// Real-time equivalents (seconds)
day_length_seconds = day_length / 60;
week_length_seconds = week_length / 60;

// Use a high-resolution timer to compute real delta time
last_real_time = get_timer(); // microseconds
last_dt = 0; // last delta seconds, for debugging display

time_current = 0; // Time in frames (0 to day_length)
day_current = 1;
week_current = 1;

// Time display variables
time_hours = 0; // 0-23
time_minutes = 0; // 0-59
time_string = "00:00";

// Day/Night cycle
is_night = false; // true when 10pm-10am
night_alpha = 0; // Darkness overlay alpha (0-0.5)

// === GAME STATE ===
enum GAME_STATE {
    PLAYING,
    PVP_CHOICE,
    DUEL,
    JAIL,
    CUTSCENE
}
game_state = GAME_STATE.PLAYING;

// === ZONE THRESHOLDS (adjust to your map) ===
street_y_top = 320;
street_y_bottom = 400;
danger_zone_margin = 48;

// === CROSSWALKS (for jaywalking detection) ===
crosswalk_zones = [
    {x_min: 140, x_max: 165},
    {x_min: 655, x_max: 690},
    {x_min: 720, x_max: 750},
    {x_min: 1185, x_max: 1200}
];

// === JAYWALKING FINE ===
showing_fine_popup = false;
fine_amount = 500;
fined_player = noone;

// === GLOBAL REFERENCE ===
globalvar game_ctrl;
game_ctrl = id;

// === DEBUG MODE ===
global.debug_mode = false; // Set to true to see debug info

// === SEAMLESS TRAVEL SYSTEM ===
global.travel_active = false; // Flag for travel data restoration
global.travel_dest_x = 0;
global.travel_dest_y = 0;
global.travel_return_room = noone;
global.travel_return_x = 0;
global.travel_return_y = 0;

// Player stats during travel
global.travel_money = 0;
global.travel_health = 0;
global.travel_heat_level = 0;
global.travel_owned_car = -1;
global.travel_weapon_type = 0;
global.travel_has_gun = false;
global.travel_weapons_owned = ds_list_create();

// Inventory during travel
global.travel_inv_weed = 0;
global.travel_inv_cocaine = 0;
global.travel_inv_heroin = 0;
global.travel_inv_meth = 0;
global.travel_inv_pills = 0;

// Loan state during travel
global.travel_has_active_loan = false;
global.travel_loan_amount = 0;
global.travel_loan_due_day = 0;
global.travel_debt = 0;

// Territory during travel
global.travel_has_territory = false;
global.travel_territory_x = -1;
global.travel_territory_y = -1;

// Crew during travel
global.travel_crew_unlocked = false;
global.travel_total_crew_earnings = 0;

// Bleed state during travel
global.travel_is_bleeding = false;
global.travel_bleed_source = noone;

// === JAIL UI ===
jailed_player = noone;
jailed_player_scan_needed = false; // Guard flag to prevent repeated scans
confiscated_money = 0;
showing_snitch_offer = false;

// === POLICE ROBBERY UI ===
showing_robbery_popup = false;
robbery_money_lost = 0;
robbery_victim = noone;

// === PVP ===
pvp_player1 = noone;
pvp_player2 = noone;
pvp_choice1 = -1;
pvp_choice2 = -1;
pvp_choices_locked = false;

enum PVP_CHOICE {
    NONE = -1,
    COLLABORATE = 0,
    ROB = 1
}

// === DUEL ===
duel_player1 = noone;
duel_player2 = noone;
duel_p1_orig_x = 0;
duel_p1_orig_y = 0;
duel_p2_orig_x = 0;
duel_p2_orig_y = 0;
duel_orig_room = Seattle;

// === DELAYED ROBBERY ===
pending_robbery = false;
robber = noone;
victim = noone;
robbery_amount = 0;
show_backdoor_msg = false;
backdoor_msg_timer = 0;

// === DRUG SHIPMENT SYSTEM ===
shipment_schedule = [
    // External supplier -> Druglord: 1 big shipment per day at 6am
    {time: day_length * 0.25, amount: 1000, from: "external", to: "high", vehicle: "car", completed: false},

    // Druglord -> Mid-level: 2 shipments per day at 10am and 4pm
    {time: day_length * 0.416, amount: 500, from: "high", to: "mid", vehicle: "car", completed: false},
    {time: day_length * 0.666, amount: 500, from: "high", to: "mid", vehicle: "car", completed: false},

    // Mid-level -> Low-level: 4 shipments per day (walking)
    {time: day_length * 0.125, amount: 100, from: "mid", to: "low", vehicle: "walk", completed: false},
    {time: day_length * 0.375, amount: 100, from: "mid", to: "low", vehicle: "walk", completed: false},
    {time: day_length * 0.625, amount: 100, from: "mid", to: "low", vehicle: "walk", completed: false},
    {time: day_length * 0.875, amount: 100, from: "mid", to: "low", vehicle: "walk", completed: false}
];

dealer_network_initialized = false;

// === NOTIFICATION SYSTEM ===
notification_queue = [];
max_visible_toasts = 4;
toast_spacing = 30;

// === DAY/NIGHT GAMEPLAY MODIFIERS ===
night_price_multiplier = 1.5;

// === RANDOM EVENTS ===
event_timer = 0;                           // Counts up in frames
event_interval_min = day_length / 12;      // Minimum 2 in-game hours between events
event_interval_max = day_length / 8;       // Maximum 3 in-game hours between events
next_event_time = irandom_range(floor(event_interval_min), floor(event_interval_max));
last_event_time = 0;

// === PEDESTRIAN SPAWNING ===
max_pedestrians = 5;

// === CUSTOMER SPAWNING ===
// 1 game minute = day_length / 1440 frames = 12.5 frames
var _game_minute = day_length / 1440;
customer_spawn_min = floor(60 * _game_minute);  // 60 game minutes = 750 frames
customer_spawn_max = floor(90 * _game_minute);  // 90 game minutes = 1125 frames
customer_spawn_timer = irandom_range(customer_spawn_min, customer_spawn_max);
max_customers = 8;

// === CUSTOMER CHASE QUEUE ===
// Only one customer can chase player1 at a time to prevent crowding
customer_chasing_player = noone; // The customer currently pursuing player1

// === COP CAR SPAWNING ===
var _game_minute = day_length / 1440;
cop_spawn_timer = 0; // Current timer count
cop_spawn_next = irandom_range(floor(120 * _game_minute), floor(180 * _game_minute)); // Next spawn at random 120-180 game minutes

// === GUNFIRE-TRIGGERED COP RESPONSE ===
gunfire_cop_timer = 0; // Counts up when waiting for response
gunfire_cop_response_delay = 0; // Delay before first cop car appears (45-60 minutes)
gunfire_cop_cars_spawned = 0; // How many cop cars have spawned (out of 3)
has_pending_gunfire_response = false; // Whether we're waiting for cop cars