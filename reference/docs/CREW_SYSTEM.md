# Crew/Gang System Documentation

## Overview
The Crew System allows players to build a team of hustlers who autonomously make sales and generate passive income. Unlocked at **$100,000**, this system creates strategic empire-building opportunities with risk/reward mechanics.

---

## 🔓 **UNLOCKING THE SYSTEM**

### Requirements
- Reach **$100,000** in cash
- System automatically unlocks (notification appears)
- Recruiters will begin approaching you in the streets

### First Recruitment
- After unlocking, hustlers approach every **5 in-game minutes**
- Recruiters walk up to you and present themselves
- Only appears if you haven't reached max crew size

---

## 👥 **RECRUITMENT**

### Recruiter Dialog
When a hustler approaches, you'll see:
- **Their Name** (randomly generated street names)
- **Stats**:
  - Sales Skill (1-10): How often they make successful sales
  - Heat Management (1-10): How well they avoid cops
  - Loyalty (1-10): Resistance to betrayal/theft
  - Stamina (1-10): Work duration before breaks
- **Daily Wage**: $200-$500 (based on sales skill)

### Recruitment Options

**[1] Hire Now ($500 signing bonus)**
- Pay $500 upfront
- Worker is permanently hired
- Starts working immediately

**[2] Test Run (1 day trial - FREE)** ⭐
- Worker works for **1 in-game day** for free
- See their performance before committing
- After 1 day, decide to keep or fire them
- No signing bonus required

**[3] Reject**
- Turn them down
- Another recruiter may approach later

---

## 💼 **WORKER BEHAVIOR**

### AI States

**ROAMING** 🟢
- Wanders within assigned territory
- Looks for customers (NPC pedestrians)
- Automatically approaches when customer spotted

**SELLING** 🟣
- Approaches customer
- 3-second transaction
- Success based on sales skill
- Earns $15-$45 per sale (modified by skill)
- Uses 1 drug unit per sale

**BREAK** 🟡
- After 15 minutes of work
- Takes 2-minute break
- Stands still, vulnerable to arrest/robbery

**FLEEING** 🔴
- Runs from cops (future implementation)
- Can get arrested

**RETURNING** ⚪
- Returns to trap house to drop off money (future implementation)

### Territory Assignment
Workers stay within assigned territory (future Phase 2 feature):
- **Free Roam**: Wanders entire low-income area
- **Trap House**: 200-pixel radius around your trap
- **Specific Corner**: Marked corner location
- **Follow Player**: Bodyguard mode (300px radius)

---

## 💰 **ECONOMICS**

### Costs
- **Signing Bonus**: $500 (if hiring immediately)
- **Test Run**: FREE for 1 day
- **Daily Wage**: $200-$500 (based on skill)
- **Re-up Cost**: Coming in Phase 2

### Revenue
- Workers earn **$15-$45 per sale**
- Modified by sales skill (0.3x to 1.0x multiplier)
- Average: **$500-$2000 per worker per day**
- Profit: **$300-$1500 per day** (after wages)

### Collecting Earnings
Press **[C]** near a worker to collect their daily earnings:
- Must be within 60 pixels
- Takes all accumulated money
- Resets their daily counter to $0

---

## 📊 **WORKER STATS & LEVELING**

### Stats Explained
- **Sales Skill**: Success rate and earnings multiplier
- **Heat Management**: Cop avoidance (coming in Phase 3)
- **Loyalty**: Prevents betrayal/theft (coming in Phase 3)
- **Stamina**: Work duration before breaks

### Leveling System
Workers gain **XP from successful sales**:
- **Level 1 (Rookie)**: Base stats
- **Level 2 (Corner Boy)**: +1 all stats, +$100 wage
- **Level 3 (Hustler)**: +2 all stats, +$200 wage
- **Level 4 (Dealer)**: +3 all stats, can train recruits
- **Level 5 (Lieutenant)**: +5 all stats, brings own recruits

*XP Required*: 20 sales per level (increases with level)

---

## 🎯 **MAX CREW SIZE**

### Formula
```
Base: 2 workers
+1 worker per $50,000 earned (lifetime)
+1 worker per trap house owned
Maximum: 8 workers total
```

### Examples
- **$100k earned, 1 trap**: Max 4 workers
- **$200k earned, 2 traps**: Max 7 workers
- **$250k earned, 3 traps**: Max 8 workers (cap)

---

## 🎮 **CONTROLS & UI**

### In-Game Controls
- **[C]** near worker - Collect earnings
- **[1/2/3]** during recruitment - Choose option

### HUD Display (Top-Left)
```
Health: ████████░░ 80/100
$15,420
Crew: 3/5              ← Active workers / Max crew
Today: +$1,240         ← Total daily earnings
```

### Worker Name Tags
Each worker shows:
- **Name** (white text in black box above head)
- **Status Dot** (colored indicator):
  - 🟢 Green = Working/roaming
  - 🟡 Yellow = On break
  - 🟣 Purple = Making a sale
  - 🔴 Red = In trouble (future)

---

## ⚠️ **CURRENT LIMITATIONS (Phase 1)**

### Not Yet Implemented
- ❌ Worker arrest system
- ❌ Loyalty/betrayal mechanics
- ❌ Territory assignment UI
- ❌ Wage payments (automatic deduction)
- ❌ Drug re-supply mechanics
- ❌ Crew management menu
- ❌ Worker customization (appearance)
- ❌ Test run expiration enforcement

### Coming in Phase 2
- Territory assignment system
- Crew management UI (Press C menu)
- Wage deduction at end of day
- Re-supply drug inventory

### Coming in Phase 3
- Arrest system
- Loyalty/betrayal
- Worker robbery
- Bail payments

---

## 🎲 **STRATEGIC TIPS**

### Early Game ($100k-$150k)
- Take **Test Runs** to evaluate workers
- Look for high **Sales Skill** (7-10)
- 2-3 workers is manageable

### Mid Game ($150k-$250k)
- Hire workers with balanced stats
- High **Loyalty** prevents future problems
- Expand to 4-6 workers

### Late Game ($250k+)
- Max out at 8 workers
- Focus on **Leveling** your best workers
- Replace low performers

### Profit Maximization
- Collect earnings regularly
- Let high-skill workers level up
- Don't hire more than you can manage

---

## 🔧 **TECHNICAL DETAILS**

### Objects
- **obj_crew_member** - Worker NPC
- **obj_crew_recruiter** - Hustler who recruits

### Player Variables
```gml
crew_unlocked = false              // Unlocked at $100k
crew_members = []                  // Array of worker instances
max_crew_size = 2                  // Dynamic based on progress
total_crew_earnings = 0            // Lifetime earnings
last_recruitment_time = 0          // Cooldown tracking
recruitment_cooldown = 18000       // 5 in-game minutes
```

### Worker Variables
```gml
// Stats
sales_skill, heat_management, loyalty, stamina

// Economics
daily_wage, daily_earnings, inventory_drugs

// Employment
owner, is_test_run, test_run_end_time, days_worked

// AI
state, target_customer, assigned_territory

// Leveling
worker_xp, worker_level, xp_to_next_level
```

---

## 📝 **CHANGELOG**

### 2026-01-26 - Phase 1 Core System
✅ Created obj_crew_member with roaming AI
✅ Created obj_crew_recruiter with dialog system
✅ Recruitment at $100k milestone
✅ Test Run option (1 day free trial)
✅ Basic sale mechanics
✅ Worker leveling system
✅ HUD display for crew earnings
✅ [C] key to collect earnings
✅ Visual name tags and status indicators

### Upcoming - Phase 2
🔲 Territory assignment UI
🔲 Crew management menu
🔲 Wage deduction system
🔲 Drug re-supply mechanics

### Future - Phase 3
🔲 Arrest and bail system
🔲 Loyalty and betrayal
🔲 Worker robbery mechanics

---

## 🎉 **ENJOY BUILDING YOUR EMPIRE!**

Your crew is your passive income engine. Recruit wisely, manage strategically, and watch your empire grow!
