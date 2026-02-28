// === RIVAL DEALER ===
state = "roaming"; // roaming, selling, intimidated, fighting, leaving
move_speed = 0.9;
hp = 80;
max_hp = 80;
money = irandom_range(200, 800);

// Roaming
wander_direction = random(360);
wander_timer = irandom_range(60, 180);
wander_pause_timer = 0;

// Selling
sell_timer = 0;
target_customer = noone;

// Combat - Melee (backup)
melee_damage = 8;
melee_cooldown = 0;
melee_cooldown_max = 40;
fight_timer = 0;

// Combat - Gun (primary)
gun_damage = 15;                // Base damage per shot (scales 20%-100% by accuracy)
gun_range = 250;                // Max shooting distance
gun_cooldown = 0;               // Current cooldown timer
gun_cooldown_max = 45;          // Frames between shots (~0.75 sec)
gun_accuracy = 12;              // Degrees of inaccuracy spread
fight_move_timer = 0;           // Timer for strafe direction changes
fight_move_dir = random(360);   // Current strafe direction
preferred_fight_dist = 120;     // Tries to maintain this distance from player

// Intimidation
intimidated_until_day = 0; // Day when intimidation wears off

// Lifetime
lifetime = irandom_range(3600, 7200); // 1-2 minutes

// Name for display
rival_name = choose("Snake", "Razor", "Smoke", "Ghost", "Blade", "Ace");
