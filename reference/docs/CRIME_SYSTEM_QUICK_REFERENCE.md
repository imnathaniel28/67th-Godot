# Crime and Cop Response System - Quick Reference

## System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CRIME COMMITTED                          │
│                     (Player presses [R])                        │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Check Cooldown? │
              └────┬────────┬───┘
                   │        │
              YES  │        │  NO
                   │        │
                   ▼        ▼
         ┌──────────────┐  ┌──────────────────────────────────┐
         │ Block Action │  │ 1. Execute Crime                 │
         │ Show Warning │  │ 2. Set cooldown = 4500 frames    │
         └──────────────┘  │ 3. Alert cop cars in 800px range │
                           └────────────┬─────────────────────┘
                                        │
                                        ▼
                           ┌─────────────────────────────┐
                           │   For Each Cop Car in Range │
                           │   ┌─────────────────────┐   │
                           │   │ 1. Stop car         │   │
                           │   │ 2. Spawn cop        │   │
                           │   │ 3. Set state=chase  │   │
                           │   │ 4. Set target       │   │
                           │   └─────────────────────┘   │
                           └────────────┬────────────────┘
                                        │
                                        ▼
                           ┌─────────────────────────────┐
                           │     COP CHASE BEGINS        │
                           └─────────────────────────────┘
```

## Chase State Machine

```
                    ┌──────────────────────┐
                    │   PATROL (Default)   │
                    │  • Random wander     │
                    │  • 50% speed         │
                    └──────────┬───────────┘
                               │
                    Player in range (250px)
                    or Crime committed
                               │
                               ▼
    ┌──────────────────────────────────────────────────┐
    │              CHASE STATE                         │
    │  • Move toward player                            │
    │  • Shoot when in range (200px)                   │
    │  • Arrest on contact                             │
    │  • Check evasion patterns                        │
    │  • Check distance                                │
    └──┬───────────────┬──────────────┬────────────────┘
       │               │              │
       │ Evasion       │ Distance     │ Normal
       │ Pattern       │ > 1000px     │ Continue
       │               │              │
       ▼               ▼              ▼
  ┌─────────┐    ┌──────────┐   ┌─────────┐
  │ STUNNED │    │ RETURN   │   │  CHASE  │
  │ 2 sec   │    │ TO CAR   │   │ PLAYER  │
  └────┬────┘    └────┬─────┘   └─────────┘
       │              │
       │              ▼
       │         Car despawns cop
       │         Car resumes patrol
       │
       └─► Resume chase after 120 frames
```

## Evasion Patterns

```
VERTICAL EVASION:
┌─────┐       ┌─────┐
│  ↑  │       │  ↓  │
│  ↓  │  OR   │  ↑  │
│  ↑  │       │  ↓  │
└─────┘       └─────┘
  = STUN        = STUN

HORIZONTAL EVASION:
┌─────┐       ┌─────┐
│ ← → │       │ → ← │
│  ←  │  OR   │  →  │
└─────┘       └─────┘
  = STUN        = STUN
```

## Distance Mechanics

```
Player Position:
    ├──────────┼──────────┼──────────┤
    0px      250px      1000px    ∞

Cop Behavior:
    │          │          │          │
    │  Patrol  │  Chase   │  Abandon │
    │          │  Begin   │  Chase   │
```

## Cooldown Timeline

```
Real Time:    0s ─────────────────────────────────── 75s
              │                                       │
              │         Crime Cooldown                │
              │                                       │
In-Game Time: 0:00 ─────────────────────────────── 6:00
              (Crime)                          (Can Crime Again)

Visual: "Crime Cooldown: 5m 59s" → ... → "Crime Cooldown: 0m 1s"
```

## Multi-Cop Response

```
Crime Location (Player):  ⚠️  (x, y)
                          
                    800px Radius
         ┌─────────────────────────────┐
         │                             │
         │    🚔 Car 1 (600px)        │
         │    ↳ Spawns Cop 👮          │
         │                             │
         │    🚔 Car 2 (750px)        │
         │    ↳ Spawns Cop 👮          │
         │                             │
         │    🚔 Car 3 (400px)        │
         │    ↳ Spawns Cop 👮          │
         │                             │
         └─────────────────────────────┘
         
         🚔 Car 4 (1200px) - No response (out of range)
```

## Collision System

```
Cop Movement Check:
    
    1. Calculate new position (x, y)
       ↓
    2. Check tilemap at (x, y)
       ↓
    3. Check buildings at (x, y)
       ↓
    4. Check NPCs at (x, y)
       ↓
    5. Collision detected?
       │
       ├─ YES → Revert to old position
       │
       └─ NO → Accept new position
```

## HUD Display

```
┌─────────────────────────────────────┐
│ HP: [████████████░░] 80/100        │  ← Health bar
│ $1250                               │  ← Money
│ ! DANGER ZONE !                     │  ← Zone warning
│ Crime Cooldown: 3m 42s              │  ← NEW: Crime cooldown
└─────────────────────────────────────┘
```

## Key Numbers

| Feature | Value | Notes |
|---------|-------|-------|
| Crime Cooldown | 4500 frames | 75 real-time seconds / 6 in-game hours |
| Cop Alert Range | 800 pixels | Detection radius for crime |
| Chase Abandon Distance | 1000 pixels | Player must escape beyond this |
| Evasion Stun Duration | 120 frames | 2 real-time seconds |
| Movement History | 6 entries | Tracks last 6 direction changes |
| Cop Detection Range | 250 pixels | Normal patrol detection |
| Cop Shoot Range | 200 pixels | When cops start shooting |
| Return Despawn Range | 32 pixels | Cop despawns when this close to car |

## Crime Types

| Crime | Cooldown | Cop Response | Reward |
|-------|----------|--------------|--------|
| Walker Robbery | ✅ 6 hours | ✅ Multiple cops | $50 per unit |
| Dice Robbery | ✅ 6 hours | ✅ Multiple cops | Entire pot |
| Future Crimes | ✅ Shared | ✅ Same system | TBD |

## Tips for Players

### Committing Crimes
1. Check cooldown before attempting
2. Commit crimes away from roads (fewer cop cars)
3. Have escape route planned
4. Be aware of cop car traffic patterns

### Evading Cops
1. Use rapid directional changes (up-down-up or left-right-left)
2. Lead cops into buildings/obstacles
3. Run 1000+ pixels away
4. Combine evasion with distance

### Managing Cooldown
1. Plan crimes strategically
2. Use cooldown time for other activities
3. Wait for cooldown to expire before next crime
4. Visual timer helps track cooldown status

## Testing Commands

```gml
// Toggle debug mode (F12)
keyboard_check_pressed(vk_f12)

// Force jail player (F11 or J)
keyboard_check_pressed(vk_f11)
keyboard_check_pressed(ord("J"))

// Check crime cooldown
show_debug_message("Cooldown: " + string(player1.crime_cooldown))

// Check movement history
show_debug_message("History: " + string(player1.movement_history))

// Count active cops
show_debug_message("Cops: " + string(instance_number(obj_cop)))
```
