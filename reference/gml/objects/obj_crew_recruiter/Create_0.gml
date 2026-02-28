// === RECRUITER IDENTITY ===
var _names = [
    "Dre", "Tay", "Mook", "Slim", "Big", "Lil Man",
    "Ace", "Rico", "Smoke", "Tank", "Cheese", "Boo",
    "Ray", "J-Rock", "Peanut", "Stacks", "Ghost", "Killa",
    "Young", "OG", "C-Note", "Dice", "Loc", "Cee"
];
recruiter_name = _names[irandom(array_length(_names) - 1)];

// === STATS (for if hired) ===
sales_skill = irandom_range(3, 10);
heat_management = irandom_range(3, 10);
loyalty = irandom_range(4, 8);
stamina = irandom_range(5, 10);

// Appearance
appearance_skin = irandom(3);
appearance_bandana = irandom(2);

// === BEHAVIOR ===
move_speed = 1.5;
tilemap = layer_tilemap_get_id("Tiles_col");
state = "approaching"; // "approaching", "talking", "waiting", "leaving"
target_player = noone;

// === DIALOG ===
has_approached = false;
dialog_active = false;

// === SPRITE ===
facing = "down";
sprite_index = spr_player_idle_down;

// === LEAVING ===
leave_direction = 0; // Direction to walk when leaving (set once)

// === DEPTH ===
depth = -y;
