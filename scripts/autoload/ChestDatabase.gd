extends Node
## Defines the two chest types and their loot tables for Project Contractor.
##
## Delivery Pallet  — common chest, drops 1-3 random toolbox items.
## Vintage Tool Chest — relic chest, drops 1 permanent stat modifier.

# ---------------------------------------------------------------------------
# Vintage Tool Chest modifier pool.
# Each entry: { id, label, effect, value, rarity }
# effect matches keys used in get_chest_modifier_bonus().
const MODIFIERS: Array[Dictionary] = [
	# Common
	{"id": "mine_pwr_5",   "label": "Mine Power +5%",   "effect": "mine_power_pct",  "value": 0.05, "rarity": "common"},
	{"id": "xp_5",         "label": "XP Gain +5%",      "effect": "xp_pct",          "value": 0.05, "rarity": "common"},
	{"id": "drop_1",       "label": "Drop Bonus +1",     "effect": "drop_bonus_flat", "value": 1.0,  "rarity": "common"},
	{"id": "cash_5",       "label": "Cash Bonus +5%",   "effect": "stage_cash_pct",  "value": 0.05, "rarity": "common"},
	{"id": "worker_5",     "label": "Worker Rate +5%",   "effect": "worker_rate_pct", "value": 0.05, "rarity": "common"},
	# Uncommon
	{"id": "mine_pwr_10",  "label": "Mine Power +10%",  "effect": "mine_power_pct",  "value": 0.10, "rarity": "uncommon"},
	{"id": "xp_10",        "label": "XP Gain +10%",     "effect": "xp_pct",          "value": 0.10, "rarity": "uncommon"},
	{"id": "drop_2",       "label": "Drop Bonus +2",     "effect": "drop_bonus_flat", "value": 2.0,  "rarity": "uncommon"},
	{"id": "cash_10",      "label": "Cash Bonus +10%",  "effect": "stage_cash_pct",  "value": 0.10, "rarity": "uncommon"},
	# Rare
	{"id": "mine_pwr_20",  "label": "Mine Power +20%",  "effect": "mine_power_pct",  "value": 0.20, "rarity": "rare"},
	{"id": "build_pwr_10", "label": "Build Power +10%", "effect": "build_power_pct", "value": 0.10, "rarity": "rare"},
	{"id": "drop_3",       "label": "Drop Bonus +3",     "effect": "drop_bonus_flat", "value": 3.0,  "rarity": "rare"},
	{"id": "xp_20",        "label": "XP Gain +20%",     "effect": "xp_pct",          "value": 0.20, "rarity": "rare"},
]

# Rarity weights for rolling a modifier
const RARITY_WEIGHTS: Dictionary = {
	"common":   60,
	"uncommon": 30,
	"rare":     10,
}

const RARITY_COLORS: Dictionary = {
	"common":   Color(0.75, 0.75, 0.75),
	"uncommon": Color(0.40, 0.85, 1.00),
	"rare":     Color(1.00, 0.85, 0.20),
}

# ---------------------------------------------------------------------------
## Returns a random modifier dict from the pool, weighted by rarity.
func roll_modifier() -> Dictionary:
	var total_weight := 0
	for m: Dictionary in MODIFIERS:
		total_weight += int(RARITY_WEIGHTS.get(m.get("rarity", "common"), 0))
	var roll := randi() % total_weight
	var acc := 0
	for m: Dictionary in MODIFIERS:
		acc += int(RARITY_WEIGHTS.get(m.get("rarity", "common"), 0))
		if roll < acc:
			return m
	return MODIFIERS[0]

## Returns display color for a rarity string.
func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)
