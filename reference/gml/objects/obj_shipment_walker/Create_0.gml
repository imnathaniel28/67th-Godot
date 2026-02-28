// === WALKING COURIER (for low-level routes) ===

// Shipment details
drug_amount = 0;
origin = noone;
destination = noone;
route_type = "mid_to_low";

// Movement
move_speed = 1.5;
target_x = x;
target_y = y;
arrived = false;

// Risk and robbery
risk_level = 1; // 1-3 scale (1=low, 3=high)
can_be_robbed = true;
robbed = false;

// Visual
image_blend = c_white; // Normal NPC appearance for stealth
