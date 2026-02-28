// === DELAYED ROBBERY EXECUTION ===
if (pending_robbery && instance_exists(robber) && instance_exists(victim)) {
    // Steal the money
    robber.money += robbery_amount;
    victim.money -= robbery_amount;

    // End the fake collaboration for victim
    victim.collab_bonus_active = false;
    victim.collab_bonus_amount = 0;
    victim.collab_partner = noone;

    // Show "YOU'VE BEEN BACKDOORED" message for 3 seconds
    show_backdoor_msg = true;
    backdoor_msg_timer = 180; // 3 seconds at 60fps
}

// Reset robbery state
pending_robbery = false;
robber = noone;
victim = noone;
robbery_amount = 0;
