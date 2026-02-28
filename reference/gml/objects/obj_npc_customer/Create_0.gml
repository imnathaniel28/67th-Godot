// === MOVEMENT ===
move_speed = 1.2;
target = noone;

// === DRUG DEMAND ===
wanted_drug = irandom(4); // DRUG_TYPE enum: 0=WEED, 1=PILLS, 2=COCAINE, 3=HEROIN, 4=METH
speech_text = "Got " + drug_get_name(wanted_drug) + "?";

// === SALE VALUES (now calculated from drug type) ===
var _price_range = drug_get_price_range(wanted_drug);
min_payment = _price_range.low;
max_payment = _price_range.high;
payment_amount = irandom_range(min_payment, max_payment);

// === BEHAVIOR ===
detection_radius = 175; // Close proximity - NPCs only notice player when walking nearby
state = "wander";
flee_target = noone; // Who we're running from (snitch)
checked_snitch = noone; // Track which player we already checked (avoid re-rolling)
is_chasing = false; // Are we the one currently chasing the player?
has_asked = false; // Track if we already asked this player (only ask once)
target_worker = noone; // Worker we're going to buy from (when redirected)

// === WANDER (walk aimlessly) ===
wander_direction = random(360); // Random direction to walk
wander_timer = irandom_range(60, 180); // How long to walk in this direction (1-3 seconds at 60fps)
wander_pause_timer = 0; // Timer for pausing between direction changes
wander_speed = move_speed * 0.7; // Slower wandering speed for casual feel

// === LEAVE (run away after sale) ===
leave_direction = 0; // Direction to run after sale
leave_speed = 0; // Speed to run after sale (set when leaving)

// === CROSSWALK NAVIGATION ===
is_crossing = false;              // Currently executing a crossing
crossing_phase = "none";          // "approach", "crossing", "none"
target_crosswalk = noone;         // Which crosswalk we're heading to
original_target = noone;          // Store follow target during crossing
crossing_destination_y = 0;       // Target Y position after crossing

// === CROSSWALK HELPER FUNCTIONS ===

// Check if NPC needs to cross street to reach target Y position
function needs_to_cross(_target_y) {
    var _on_top_side = (y < game_ctrl.street_y_top);
    var _target_on_top = (_target_y < game_ctrl.street_y_top);
    return (_on_top_side != _target_on_top);
}

// Check if currently standing in a crosswalk zone
function is_in_crosswalk() {
    for (var i = 0; i < array_length(game_ctrl.crosswalk_zones); i++) {
        var _cw = game_ctrl.crosswalk_zones[i];
        if (x >= _cw.x_min && x <= _cw.x_max) {
            return true;
        }
    }
    return false;
}

// Find the nearest crosswalk to current position
function find_nearest_crosswalk() {
    var _nearest = noone;
    var _min_dist = 999999;

    for (var i = 0; i < array_length(game_ctrl.crosswalk_zones); i++) {
        var _cw = game_ctrl.crosswalk_zones[i];
        var _center_x = (_cw.x_min + _cw.x_max) / 2;
        var _dist = abs(x - _center_x);

        if (_dist < _min_dist) {
            _min_dist = _dist;
            _nearest = {
                x_min: _cw.x_min,
                x_max: _cw.x_max,
                center_x: _center_x
            };
        }
    }
    return _nearest;
}

// Start the crossing sequence
function initiate_crossing(_destination_y) {
    is_crossing = true;
    crossing_destination_y = _destination_y;
    target_crosswalk = find_nearest_crosswalk();

    // If already in crosswalk, skip approach phase
    if (is_in_crosswalk()) {
        crossing_phase = "crossing";
    } else {
        crossing_phase = "approach";
    }
}

// Prevent jaywalking when not in a crossing sequence
function apply_crosswalk_constraints(_new_x, _new_y) {
    // Only block if we're not already performing a crossing and we're outside a crosswalk lane
    if (!is_crossing && !is_in_crosswalk()) {
        // Moving from top sidewalk toward/into the street
        if (y < game_ctrl.street_y_top && _new_y >= game_ctrl.street_y_top) {
            _new_y = game_ctrl.street_y_top - 1;
        }
        // Moving from bottom sidewalk toward/into the street
        else if (y > game_ctrl.street_y_bottom && _new_y <= game_ctrl.street_y_bottom) {
            _new_y = game_ctrl.street_y_bottom + 1;
        }
    }

    x = _new_x;
    y = _new_y;
}

// === NPC MONEY (for gambling) ===
money = irandom_range(500, 2000);  // NPCs start with random money for dice games

// === SPEECH BUBBLE (announcing interest) ===
show_speech_bubble = false;       // Whether to display the speech bubble
speech_bubble_timer = 0;          // How long to show the bubble (in frames)
speech_bubble_duration = 120;     // Show bubble for 2 seconds (120 frames at 60fps)
has_announced = false;            // Track if we already announced to this player (only once)

// === GUNSHOT PANIC ===
has_fled = false;                 // Whether NPC fled due to gunshots
flee_until_time = 0;              // Game time when NPC will return (1 hour = 3600 in-game seconds)
