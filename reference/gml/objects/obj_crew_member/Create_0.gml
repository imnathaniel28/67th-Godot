// === CREW MEMBER STATS ===
// Randomly generated on creation
sales_skill = irandom_range(3, 10);      // 1-10: How often they make sales
heat_management = irandom_range(3, 10);   // 1-10: How well they avoid cops
loyalty = irandom_range(4, 8);            // 1-10: Chance they steal/snitch
stamina = irandom_range(5, 10);           // 1-10: How long they hustle

// === IDENTITY ===
// Pool of street names for random generation
var _names = [
    "Dre", "Tay", "Mook", "Slim", "Big", "Lil Man",
    "Ace", "Rico", "Smoke", "Tank", "Cheese", "Boo",
    "Ray", "J-Rock", "Peanut", "Stacks", "Ghost", "Killa",
    "Young", "OG", "C-Note", "Dice", "Loc", "Cee"
];
worker_name = _names[irandom(array_length(_names) - 1)];

// Randomize appearance
appearance_skin = irandom(3);  // 0-3 for skin tone
appearance_bandana = irandom(2); // 0-2 for bandana color

// === EMPLOYMENT STATUS ===
owner = noone;  // Which player owns this worker
is_hired = false; // False = recruiting, True = hired and working
is_test_run = false; // True if on test run (1 day trial)
test_run_end_time = 0; // When test run expires
days_worked = 0;
times_arrested = 0;

// === ECONOMICS ===
daily_wage = 200 + (sales_skill * 30); // Higher skill = higher wage ($200-$500)
daily_earnings = 0; // Money earned today
total_earnings = 0; // Money earned since hired
inventory_drugs = 10; // Start with 10 units

// === MOVEMENT ===
move_speed = 1.2;
tilemap = layer_tilemap_get_id("Tiles_col");

// === WANDER SYSTEM (like NPCs) ===
wander_direction = random(360);
wander_timer = irandom_range(60, 180); // 1-3 seconds per direction
wander_pause_timer = 0;

// === BEHAVIOR STATE ===
state = "recruiting_approach"; // "recruiting_approach", "recruiting_waiting", "rejected", "roaming", "selling", "break", "fleeing", "returning"
target_customer = noone;
target_player = noone; // Player to recruit to

// === TERRITORY ASSIGNMENT ===
assigned_territory = "free"; // "trap_house", "corner", "follow", "free"
territory_x = x; // Center point of assigned territory
territory_y = y;
territory_radius = 200; // How far they can roam from center

// === SELLING ===
sale_timer = 0;
sale_cooldown = 300; // 5 seconds between sales
detection_radius = 150; // How far they spot customers

// === BREAK SYSTEM ===
work_timer = 0;
work_duration = 900; // 15 minutes of work (900 seconds * 60fps = 54000 frames)
break_timer = 0;
break_duration = 120; // 2 minute break (7200 frames)

// === LEVELING ===
worker_xp = 0;
worker_level = 1;
xp_to_next_level = 20; // Sales needed to level up

// === VISUAL ===
show_status = true; // Show name tag
status_color = c_lime; // Green = working

// === LEAVING (for rejected state) ===
leave_direction = 0;

// === DEPTH SORTING ===
depth = -y;

// === SPRITE ===
facing = "down";
sprite_index = spr_player_idle_down; // Will use player sprites for now
