# Crime and Cop Response System

## Overview
This document describes the advanced crime detection and cop response mechanics implemented in the game.

## Crime System

### Crime Cooldown
- **Duration**: 6 in-game hours (4500 frames / 75 real-time seconds)
- **Trigger**: Any criminal action (robbery, dice game robbery, etc.)
- **Effect**: Player cannot commit another crime until cooldown expires
- **Visual Indicator**: Displayed in HUD (top-left) showing minutes:seconds remaining
- **Location Tracking**: Last crime location stored for potential future use

### Criminal Actions
1. **Walker Robbery** (`obj_shipment_walker`)
   - Press [R] when near courier (within 48 pixels)
   - Blocked if crime cooldown active
   - Rewards: $50 per drug unit
   - Triggers cop response

2. **Dice Game Robbery** (`scr_dice_robbery`)
   - Requires gun (has_gun = true)
   - Steals entire pot + ground money
   - NPCs flee after robbery
   - Triggers cop response

## Cop Response System

### Multiple Cop Response
When a crime is committed:
1. **Detection Range**: All cop cars within 800 pixels are alerted
2. **Cop Spawning**: Each responding car spawns a cop entity at its location
3. **Car Behavior**: Cop car stops in place (has_target = true)
4. **Cop Initialization**: 
   - State: "chase"
   - Target: Player who committed crime
   - origin_car: Reference to spawning car

### Cop AI States

#### Chase State
- **Activation**: Spawned from crime or player within detection range (250 pixels)
- **Behavior**:
  - Pursues target player
  - Shoots when within 200 pixels
  - Arrests on contact
- **Obstacle Avoidance**:
  - Checks tilemap collisions
  - Checks building collisions (obj_building_parent)
  - Checks NPC collisions
  - Reverts position if collision detected
- **Stun Mechanic**: Cop freezes for 2 seconds when player evades
- **Abandonment**: Switches to return_to_car if distance > 1000 pixels

#### Return to Car State
- **Activation**: Player escapes beyond 1000 pixels
- **Behavior**:
  - Moves back toward origin_car at 80% speed
  - Still respects obstacle collisions
  - Despawns when within 32 pixels of car
  - Car resumes patrol (has_target = false)
- **Fallback**: If car no longer exists, switches to patrol

#### Patrol State
- **Standard Behavior**: Random wandering at 50% speed
- **Stop & Search**: Can randomly stop and search nearby players

## Player Evasion Mechanics

### Movement Tracking
- **History Size**: Last 6 directional changes
- **Tracked Directions**: "up", "down", "left", "right"
- **Recording**: Only when direction changes (not every frame)
- **Reset**: Cleared when player stops moving

### Evasion Patterns
Two types of patterns trigger cop stun:

1. **Vertical Evasion**:
   - Pattern: up → down → up
   - Pattern: down → up → down

2. **Horizontal Evasion**:
   - Pattern: left → right → left
   - Pattern: right → left → right

### Stun Effect
- **Duration**: 120 frames (2 seconds at 60fps)
- **Effect**: Cop cannot move but continues tracking
- **Visual**: Debug message shows which evasion type triggered
- **Cooldown**: One stun per chase (until pattern resets)

## Implementation Details

### Key Variables

**player1 (Player Object)**:
```gml
crime_cooldown = 0;           // Current cooldown timer
crime_cooldown_max = 4500;    // 6 in-game hours
last_crime_x = 0;             // Location of last crime
last_crime_y = 0;
movement_history = [];        // Last 6 directional changes
movement_history_max = 6;
last_move_dir = "";           // Current movement direction
```

**obj_cop (Cop Object)**:
```gml
origin_car = noone;           // Car that spawned this cop
chase_abandon_distance = 1000; // Abandonment threshold
is_stunned = false;           // Evasion stun status
stun_timer = 0;               // Frames remaining in stun
stun_duration = 120;          // Stun duration (2 seconds)
```

**obj_car (Car Object)**:
```gml
is_cop = false;               // Whether this is a cop car
has_target = false;           // Whether cop has been spawned
target_player = noone;        // Player being pursued
```

### Code Flow

**Crime Committed**:
```
1. Check if player.crime_cooldown > 0
   - If yes: Block action, show warning
   - If no: Continue

2. Execute crime action (robbery, etc.)

3. Set player.crime_cooldown = crime_cooldown_max

4. Store crime location (player.last_crime_x/y)

5. Alert cop cars:
   with (obj_car) {
       if (is_cop && distance < 800) {
           Spawn cop at car location
           Set cop.state = "chase"
           Set cop.target = player
           Set cop.origin_car = this car
           Set car.has_target = true
       }
   }
```

**Evasion Detection**:
```
1. Cop in chase state

2. Check target.movement_history length >= 3

3. Get last 3 movements

4. Check patterns:
   - [up, down, up] or [down, up, down]
   - [left, right, left] or [right, left, right]

5. If pattern matches:
   - Set cop.is_stunned = true
   - Set cop.stun_timer = 120
   - Debug message
```

**Chase Abandonment**:
```
1. Cop in chase state

2. Calculate distance to target

3. If distance > 1000:
   - Check if origin_car exists
   - If yes: state = "return_to_car"
   - If no: state = "patrol"

4. Return to car state:
   - Move toward origin_car
   - When distance < 32:
     - Set car.has_target = false
     - Destroy cop
```

## Balance Considerations

### Crime Cooldown
- **6 in-game hours** = 75 real-time seconds
- Prevents spam but allows strategic crime
- Long enough to force planning
- Short enough to not frustrate players

### Cop Response Range
- **800 pixels** = roughly 1/3 of typical screen
- Multiple cops respond to visible crimes
- Not punishing for crimes in remote areas
- Scales with number of cop cars on road

### Chase Abandonment
- **1000 pixels** = about 1.5 screens
- Requires sustained escape effort
- Evasion + distance = successful escape
- Cop returns to car maintains realism

### Evasion Stun
- **2 seconds** = meaningful but not overpowered
- Requires deliberate player action
- Pattern must be precise (3 rapid changes)
- Doesn't work on patrol cops

## Testing Checklist

### Crime System
- [ ] Crime cooldown blocks actions correctly
- [ ] Cooldown timer displays accurately
- [ ] Cooldown persists across room changes
- [ ] Multiple crime types share cooldown
- [ ] Visual indicators clear and visible

### Cop Response
- [ ] Multiple cop cars respond to single crime
- [ ] Cops spawn at correct car locations
- [ ] All cops within 800px respond
- [ ] Cops outside 800px don't respond
- [ ] Car stops when cop spawned

### Chase Mechanics
- [ ] Cops pursue player correctly
- [ ] Cops shoot when in range
- [ ] Cops arrest on contact
- [ ] Cops avoid buildings
- [ ] Cops avoid tilemap obstacles
- [ ] Cops don't get stuck in walls

### Evasion System
- [ ] Movement history tracks correctly
- [ ] Vertical evasion triggers stun
- [ ] Horizontal evasion triggers stun
- [ ] Stun duration accurate (2 seconds)
- [ ] Stunned cops can't move
- [ ] Pattern requires 3 changes

### Chase Abandonment
- [ ] Cops abandon at 1000+ pixels
- [ ] Cops return to origin car
- [ ] Cops despawn near car
- [ ] Car resumes patrol after cop returns
- [ ] Fallback to patrol if car gone

## Edge Cases

### Player Death
- Crime cooldown persists through death
- Chasing cops continue pursuit
- No special handling needed

### Room Change
- Crime cooldown tracked globally
- Cops destroyed on room change (standard behavior)
- Car system resets with traffic spawner

### Multiple Players
- Each player has own crime cooldown
- Cops can chase different targets
- Evasion checks target's movement history
- System scales to multiplayer

### Car Despawn
- If car despawns while cop returning
- Cop switches to patrol state
- No crash or error
- Smooth degradation

## Future Enhancements

### Potential Features
1. **Wanted Level**: Escalating responses based on crime frequency
2. **Cop Coordination**: Multiple cops coordinate pursuit
3. **Roadblocks**: Cop cars block escape routes
4. **Backup Calls**: Cops call for reinforcements
5. **Witness System**: NPCs report crimes to cops
6. **Crime Types**: Different crimes have different cooldowns
7. **Police Stations**: Cops spawn from fixed locations
8. **Pursuit Vehicles**: Cop cars join chase dynamically

### Balance Adjustments
- Monitor player feedback on cooldown duration
- Adjust cop spawn range based on difficulty
- Fine-tune evasion stun duration
- Consider wanted level tiers
- Test multiplayer scaling

## Technical Notes

### Performance
- Cop spawning: O(n) where n = number of cop cars
- Evasion detection: O(1) array access
- Collision checks: Standard GameMaker collision
- No noticeable performance impact

### Save System
- crime_cooldown saved with player
- movement_history not saved (transient)
- Cops don't persist across sessions
- Car system regenerates on load

### Debugging
- Debug messages show evasion triggers
- F12 toggles debug overlay
- Visual indicators aid testing
- All key values accessible in debugger
