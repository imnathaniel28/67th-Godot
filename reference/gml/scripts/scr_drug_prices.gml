/// scr_drug_prices - Drug type definitions, pricing, and inventory helpers

// === DRUG TYPE ENUM ===
enum DRUG_TYPE {
    WEED = 0,
    PILLS = 1,
    COCAINE = 2,
    HEROIN = 3,
    METH = 4
}

/// Returns the price range {low, high} for a given drug type
function drug_get_price_range(_type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    return {low: 15, high: 25};
        case DRUG_TYPE.PILLS:   return {low: 20, high: 35};
        case DRUG_TYPE.COCAINE: return {low: 40, high: 60};
        case DRUG_TYPE.HEROIN:  return {low: 50, high: 75};
        case DRUG_TYPE.METH:    return {low: 60, high: 90};
        default:                return {low: 10, high: 30};
    }
}

/// Returns the display name for a drug type
function drug_get_name(_type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    return "Weed";
        case DRUG_TYPE.PILLS:   return "Pills";
        case DRUG_TYPE.COCAINE: return "Coke";
        case DRUG_TYPE.HEROIN:  return "H";
        case DRUG_TYPE.METH:    return "Meth";
        default:                return "Stuff";
    }
}

/// Returns the color associated with a drug type (for UI)
function drug_get_color(_type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    return c_lime;
        case DRUG_TYPE.PILLS:   return c_aqua;
        case DRUG_TYPE.COCAINE: return c_white;
        case DRUG_TYPE.HEROIN:  return c_orange;
        case DRUG_TYPE.METH:    return c_yellow;
        default:                return c_gray;
    }
}

/// Checks if player has at least 1 unit of the given drug type
function player_has_drug(_player, _type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    return _player.inventory_weed > 0;
        case DRUG_TYPE.PILLS:   return _player.inventory_pills > 0;
        case DRUG_TYPE.COCAINE: return _player.inventory_cocaine > 0;
        case DRUG_TYPE.HEROIN:  return _player.inventory_heroin > 0;
        case DRUG_TYPE.METH:    return _player.inventory_meth > 0;
        default:                return false;
    }
}

/// Deducts 1 unit of the given drug type from player inventory
function player_deduct_drug(_player, _type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    _player.inventory_weed = max(0, _player.inventory_weed - 1); break;
        case DRUG_TYPE.PILLS:   _player.inventory_pills = max(0, _player.inventory_pills - 1); break;
        case DRUG_TYPE.COCAINE: _player.inventory_cocaine = max(0, _player.inventory_cocaine - 1); break;
        case DRUG_TYPE.HEROIN:  _player.inventory_heroin = max(0, _player.inventory_heroin - 1); break;
        case DRUG_TYPE.METH:    _player.inventory_meth = max(0, _player.inventory_meth - 1); break;
    }
}

/// Adds 1 unit of the given drug type to player inventory
function player_add_drug(_player, _type) {
    switch (_type) {
        case DRUG_TYPE.WEED:    _player.inventory_weed += 1; break;
        case DRUG_TYPE.PILLS:   _player.inventory_pills += 1; break;
        case DRUG_TYPE.COCAINE: _player.inventory_cocaine += 1; break;
        case DRUG_TYPE.HEROIN:  _player.inventory_heroin += 1; break;
        case DRUG_TYPE.METH:    _player.inventory_meth += 1; break;
    }
}

/// Calculates the sale price for a drug based on type and game conditions
function drug_calculate_price(_type) {
    var _range = drug_get_price_range(_type);
    var _base_price = irandom_range(_range.low, _range.high);

    // Night multiplier (1.5x at night)
    if (instance_exists(obj_game_controller) && obj_game_controller.is_night) {
        _base_price = floor(_base_price * obj_game_controller.night_price_multiplier);
    }

    // City multiplier (LA = 2x prices - higher risk, higher reward)
    if (room == LA) {
        _base_price = floor(_base_price * 2.0);
    }

    return _base_price;
}

/// Returns the total drug inventory count for a player
function player_total_drugs(_player) {
    return _player.inventory_weed + _player.inventory_pills
         + _player.inventory_cocaine + _player.inventory_heroin
         + _player.inventory_meth;
}

/// Checks if player has ANY drug at all
function player_has_any_drug(_player) {
    return player_total_drugs(_player) > 0;
}

/// Returns the drug type the player has the most of (for auto-selection)
function player_most_stocked_drug(_player) {
    var _best_type = DRUG_TYPE.WEED;
    var _best_amount = _player.inventory_weed;

    if (_player.inventory_pills > _best_amount) { _best_type = DRUG_TYPE.PILLS; _best_amount = _player.inventory_pills; }
    if (_player.inventory_cocaine > _best_amount) { _best_type = DRUG_TYPE.COCAINE; _best_amount = _player.inventory_cocaine; }
    if (_player.inventory_heroin > _best_amount) { _best_type = DRUG_TYPE.HEROIN; _best_amount = _player.inventory_heroin; }
    if (_player.inventory_meth > _best_amount) { _best_type = DRUG_TYPE.METH; _best_amount = _player.inventory_meth; }

    return _best_type;
}
