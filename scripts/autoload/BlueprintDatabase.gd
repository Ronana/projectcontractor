extends Node
## Defines all Blueprint cards and Permits for Project Contractor.
## Blueprints are earned through gameplay and give permanent multipliers.
## Permits gate access to higher building tiers.

# ── Fragment thresholds: fragments needed to reach each level ───────────────
# Index = current level (0→1 needs 3, 1→2 needs 5, etc.)
const FRAGMENTS_PER_LEVEL: Array[int] = [3, 5, 8, 12, 20]
const MAX_LEVEL := 5
const BONUS_PER_LEVEL := 0.08   # +8% per level → +40% at max

# ── Blueprint categories ─────────────────────────────────────────────────────
# effect types:
#   "mat_yield"     — multiplies drop amount for a specific raw/refined material
#   "stage_cash"    — multiplies cash earned from stages of a specific building tier
#   "crew_rate"     — multiplies all crew gather rates
#   "mine_power"    — multiplies mine power (tap damage)
#   "xp_gain"       — multiplies all XP earned

const BLUEPRINTS: Array[Dictionary] = [
	# ── Raw materials ─────────────────────────────────────────────────────────
	{
		"id": "bp_timber",   "name": "Timber Blueprint",
		"desc": "+8% timber yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "timber",
		"color": Color(0.95, 0.72, 0.30), "symbol": "T",
	},
	{
		"id": "bp_stone",    "name": "Stone Blueprint",
		"desc": "+8% stone yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "stone",
		"color": Color(0.68, 0.68, 0.72), "symbol": "S",
	},
	{
		"id": "bp_sand",     "name": "Sand Blueprint",
		"desc": "+8% sand yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "sand",
		"color": Color(0.96, 0.88, 0.55), "symbol": "D",
	},
	{
		"id": "bp_steel_ore","name": "Steel Ore Blueprint",
		"desc": "+8% steel ore yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "steel_ore",
		"color": Color(0.60, 0.70, 0.80), "symbol": "O",
	},
	{
		"id": "bp_clay",     "name": "Clay Blueprint",
		"desc": "+8% clay yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "clay",
		"color": Color(0.80, 0.45, 0.30), "symbol": "C",
	},
	{
		"id": "bp_copper",   "name": "Copper Blueprint",
		"desc": "+8% copper yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "copper",
		"color": Color(0.85, 0.52, 0.25), "symbol": "Cu",
	},
	{
		"id": "bp_limestone","name": "Limestone Blueprint",
		"desc": "+8% limestone yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "limestone",
		"color": Color(0.90, 0.88, 0.80), "symbol": "L",
	},
	{
		"id": "bp_bauxite",  "name": "Bauxite Blueprint",
		"desc": "+8% bauxite yield per level",
		"category": "raw",   "effect": "mat_yield",  "target": "bauxite",
		"color": Color(0.75, 0.55, 0.45), "symbol": "Ba",
	},
	# ── Refined materials ─────────────────────────────────────────────────────
	{
		"id": "bp_lumber",   "name": "Lumber Blueprint",
		"desc": "+8% lumber craft yield per level",
		"category": "refined","effect": "mat_yield", "target": "lumber",
		"color": Color(0.75, 0.55, 0.20), "symbol": "Lu",
	},
	{
		"id": "bp_concrete", "name": "Concrete Blueprint",
		"desc": "+8% concrete craft yield per level",
		"category": "refined","effect": "mat_yield", "target": "concrete",
		"color": Color(0.55, 0.58, 0.62), "symbol": "Co",
	},
	{
		"id": "bp_glass",    "name": "Glass Blueprint",
		"desc": "+8% glass craft yield per level",
		"category": "refined","effect": "mat_yield", "target": "glass",
		"color": Color(0.55, 0.88, 0.95), "symbol": "Gl",
	},
	{
		"id": "bp_steel_beam","name": "Steel Beam Blueprint",
		"desc": "+8% steel beam craft yield per level",
		"category": "refined","effect": "mat_yield", "target": "steel_beam",
		"color": Color(0.50, 0.65, 0.85), "symbol": "SB",
	},
	# ── Buildings ─────────────────────────────────────────────────────────────
	{
		"id": "bp_shed",             "name": "Shed Blueprint",
		"desc": "+8% cash from Shed stages per level",
		"category": "building",      "effect": "stage_cash", "target": "shed",
		"color": Color(0.90, 0.75, 0.30), "symbol": "Sh",
	},
	{
		"id": "bp_single_house",     "name": "House Blueprint",
		"desc": "+8% cash from Single House stages",
		"category": "building",      "effect": "stage_cash", "target": "single_house",
		"color": Color(0.40, 0.85, 0.60), "symbol": "H1",
	},
	{
		"id": "bp_two_story_house",  "name": "Two-Storey Blueprint",
		"desc": "+8% cash from Two-Storey stages",
		"category": "building",      "effect": "stage_cash", "target": "two_story_house",
		"color": Color(0.35, 0.75, 0.90), "symbol": "H2",
	},
	{
		"id": "bp_apartment_block",  "name": "Apartment Blueprint",
		"desc": "+8% cash from Apartment stages",
		"category": "building",      "effect": "stage_cash", "target": "apartment_block",
		"color": Color(0.70, 0.50, 1.00), "symbol": "Ap",
	},
	{
		"id": "bp_retail_unit",      "name": "Retail Blueprint",
		"desc": "+8% cash from Retail Unit stages",
		"category": "building",      "effect": "stage_cash", "target": "retail_unit",
		"color": Color(1.00, 0.55, 0.25), "symbol": "Re",
	},
	{
		"id": "bp_office_block",     "name": "Office Blueprint",
		"desc": "+8% cash from Office Block stages",
		"category": "building",      "effect": "stage_cash", "target": "office_block",
		"color": Color(0.40, 0.70, 1.00), "symbol": "Of",
	},
	{
		"id": "bp_high_rise",        "name": "High-Rise Blueprint",
		"desc": "+8% cash from High-Rise stages",
		"category": "building",      "effect": "stage_cash", "target": "high_rise",
		"color": Color(0.85, 0.25, 0.60), "symbol": "HR",
	},
	{
		"id": "bp_skyscraper",       "name": "Skyscraper Blueprint",
		"desc": "+8% cash from Skyscraper stages",
		"category": "building",      "effect": "stage_cash", "target": "skyscraper",
		"color": Color(1.00, 0.78, 0.20), "symbol": "SK",
	},
	# ── General ───────────────────────────────────────────────────────────────
	{
		"id": "bp_crew",     "name": "Crew Blueprint",
		"desc": "+8% all crew gather rates per level",
		"category": "general","effect": "crew_rate",  "target": "",
		"color": Color(0.40, 0.90, 0.90), "symbol": "Cr",
	},
	{
		"id": "bp_mine",     "name": "Mine Blueprint",
		"desc": "+8% mine power (tap damage) per level",
		"category": "general","effect": "mine_power", "target": "",
		"color": Color(0.30, 0.90, 0.40), "symbol": "Mi",
	},
	{
		"id": "bp_xp",       "name": "XP Blueprint",
		"desc": "+8% all XP earned per level",
		"category": "general","effect": "xp_gain",   "target": "",
		"color": Color(0.80, 0.40, 1.00), "symbol": "XP",
	},
]

# ── Permits ──────────────────────────────────────────────────────────────────
# unlock_tier:          the tier the player must have completed N times
# completions_required: how many of that tier to complete
# unlocks:              array of tier_ids now accessible
const PERMITS: Array[Dictionary] = [
	{
		"id":                   "commercial_permit",
		"name":                 "Commercial Permit",
		"desc":                 "Unlocks Apartment Block & Retail Unit",
		"unlock_tier":          "two_story_house",
		"completions_required": 3,
		"unlocks":              ["apartment_block", "retail_unit"],
		"color":                Color(0.70, 0.50, 1.00),
	},
	{
		"id":                   "engineering_permit",
		"name":                 "Engineering Permit",
		"desc":                 "Unlocks Office Block",
		"unlock_tier":          "apartment_block",
		"completions_required": 3,
		"unlocks":              ["office_block"],
		"color":                Color(0.40, 0.70, 1.00),
	},
	{
		"id":                   "high_rise_permit",
		"name":                 "High-Rise Permit",
		"desc":                 "Unlocks High-Rise Tower",
		"unlock_tier":          "office_block",
		"completions_required": 3,
		"unlocks":              ["high_rise"],
		"color":                Color(0.85, 0.25, 0.60),
	},
	{
		"id":                   "landmark_permit",
		"name":                 "Landmark Permit",
		"desc":                 "Unlocks Skyscraper",
		"unlock_tier":          "high_rise",
		"completions_required": 3,
		"unlocks":              ["skyscraper"],
		"color":                Color(1.00, 0.78, 0.20),
	},
]

# ── Public API ───────────────────────────────────────────────────────────────
func get_blueprint(id: String) -> Dictionary:
	for bp: Dictionary in BLUEPRINTS:
		if bp["id"] == id:
			return bp
	return {}

func get_all_by_category(cat: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bp: Dictionary in BLUEPRINTS:
		if bp.get("category", "") == cat:
			result.append(bp)
	return result

func get_permit(id: String) -> Dictionary:
	for p: Dictionary in PERMITS:
		if p["id"] == id:
			return p
	return {}

## Fragments needed to go from `current_level` to `current_level + 1`.
## Returns 0 if already at max level.
func fragments_for_next_level(current_level: int) -> int:
	if current_level >= MAX_LEVEL:
		return 0
	return FRAGMENTS_PER_LEVEL[current_level]

## Total bonus multiplier (additive on top of 1.0) for a given level.
func total_bonus(level: int) -> float:
	return float(level) * BONUS_PER_LEVEL

## Returns the blueprint id that drops from breaking a node of this material.
func mat_drop_id(mat_id: String) -> String:
	return "bp_" + mat_id

## Returns the blueprint id that drops from completing a building of this tier.
func building_drop_id(tier_id: String) -> String:
	return "bp_" + tier_id

## Returns the blueprint id that drops from crafting a refined material.
func craft_drop_id(ref_mat_id: String) -> String:
	return "bp_" + ref_mat_id
