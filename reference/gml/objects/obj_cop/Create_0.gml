// Movement and state
state = "roaming"; // States: "roaming", "chasing", "arresting"
target = noone;
move_speed = .5;
chase_speed = 1.1;
base_detection_range = 100;
detection_range = base_detection_range;
arrest_range = 5;
stunned_timer = 0;            // Frames remaining while stunned by player
chase_forget_time = 90;      // How long to keep chasing after losing sight
chase_timeout = room_speed * 10; // Max chase duration before returning to car (10 seconds)
chase_timer = 0;             // Counts frames spent chasing
car_parent = noone;          // Cop car that spawned this cop (if any)

// Sprites
spr_idle_left = Cop_Idle_L;
spr_idle_right = Cop_Idle_R;
spr_run_left = CopRunL;
spr_run_right = CopRunR;

// Direction tracking
facing = 1; // 1 = right, -1 = left

// Roaming behavior
roam_timer = 0;
roam_dir_x = choose(-1, 1);
roam_dir_y = choose(-1, 0, 1);
roam_change_time = irandom_range(60, 180); // Change direction every 1-3 seconds
lost_sight_timer = 0; // Counts down while chasing

// Lifetime - cop despawns after some time
lifetime = irandom_range(600, 1200); // 10-20 seconds at 60fps