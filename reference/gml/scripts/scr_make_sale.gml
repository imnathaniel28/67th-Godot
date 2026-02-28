// Script: scr_make_sale
// Description: Handles making a sale - checks drug inventory and auto-executes based on auto_sale_mode
function scr_make_sale(player, npc) {
    // Check if a transaction dialog already exists
    if (instance_exists(obj_transaction_dialog)) {
        return;
    }

    // === DRUG INVENTORY CHECK ===
    var _wanted = npc.wanted_drug;

    // === AUTO SALE: No (refuse all) ===
    if (player.auto_sale_mode == 2) {
        npc.state = "leave";
        npc.leave_direction = random(360);
        npc.leave_speed = random_range(1.8, 2.2);
        if (npc.is_chasing) {
            npc.is_chasing = false;
            if (game_ctrl.customer_chasing_player == npc.id) {
                game_ctrl.customer_chasing_player = noone;
            }
        }
        return;
    }

    // === AUTO SALE: My Homie (send to nearest worker) ===
    if (player.auto_sale_mode == 1) {
        if (player.crew_unlocked) {
            var _nearest_worker = noone;
            var _nearest_dist = 9999;

            for (var i = 0; i < array_length(player.crew_members); i++) {
                var _worker = player.crew_members[i];
                if (instance_exists(_worker) && _worker.is_hired) {
                    var _dist = point_distance(npc.x, npc.y, _worker.x, _worker.y);
                    if (_dist < _nearest_dist) {
                        _nearest_dist = _dist;
                        _nearest_worker = _worker;
                    }
                }
            }

            if (_nearest_worker != noone) {
                npc.state = "follow_worker";
                npc.target_worker = _nearest_worker;
                // Crew sales add less heat
                player.heat_level = min(100, player.heat_level + 1);
                player.last_crime_time = game_ctrl.time_current;
                if (npc.is_chasing) {
                    npc.is_chasing = false;
                    if (game_ctrl.customer_chasing_player == npc.id) {
                        game_ctrl.customer_chasing_player = noone;
                    }
                }
                return;
            }
            // No workers available - fall through to personal sale below
        }
        // Crew not unlocked or no workers - fall through to personal sale
    }

    // === PERSONAL SALE (mode 0 "Yes", or mode 1 fallback) ===
    // Check if player has the requested drug
    if (!player_has_drug(player, _wanted)) {
        // Don't have what they want - NPC leaves disappointed
        scr_notify("No " + drug_get_name(_wanted) + " to sell!", c_red);
        npc.state = "leave";
        npc.leave_direction = random(360);
        npc.leave_speed = random_range(1.5, 2.0);
        if (npc.is_chasing) {
            npc.is_chasing = false;
            if (game_ctrl.customer_chasing_player == npc.id) {
                game_ctrl.customer_chasing_player = noone;
            }
        }
        return;
    }

    // Calculate price based on drug type
    var _payment = drug_calculate_price(_wanted);

    // Deduct drug from inventory
    player_deduct_drug(player, _wanted);

    // Pay the player
    player.money += _payment;
    player.sell_cooldown = 60;

    // Heat from selling
    player.heat_level = min(100, player.heat_level + 2);
    player.last_crime_time = game_ctrl.time_current;

    // Floating "+$" popup
    instance_create_depth(player.x, player.y - 20, -9999, obj_sale_popup);

    // NPC leaves satisfied
    npc.state = "leave";
    npc.leave_direction = random(360);
    npc.leave_speed = random_range(2.0, 2.4);
    if (npc.is_chasing) {
        npc.is_chasing = false;
        if (game_ctrl.customer_chasing_player == npc.id) {
            game_ctrl.customer_chasing_player = noone;
        }
    }
}
