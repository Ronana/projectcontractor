extends Node
## Static game data: building tier definitions + mining location definitions.
## Provides data to the build loop and mine loop at runtime.
##
## Autoload order: can live anywhere after GameState.

## Tiers that require a permit before the player can select them.
## Key: tier_id → permit_id the player must hold.
const TIER_PERMIT_REQUIRED: Dictionary = {
	"apartment_block": "commercial_permit",
	"retail_unit":     "commercial_permit",
	"office_block":    "engineering_permit",
	"high_rise":       "high_rise_permit",
	"skyscraper":      "landmark_permit",
}

## Per-tier reward tables and property income rates.
## stage_cash_base : base cash per stage (stage_order multiplier applied in code)
## stage_gems      : gems awarded per stage completion
## complete_cash   : cash bonus when the full building is finished
## complete_gems   : gems bonus when the full building is finished
## first_gems      : one-time gem bonus on the very first completion of this tier
## income_per_min  : passive cash/min this tier contributes once in the skyline
const TIER_REWARDS: Dictionary = {
	"shed":            {"stage_cash_base": 100,   "stage_gems": 1,  "complete_cash": 500,     "complete_gems": 8,    "first_gems": 15,   "income_per_min": 2   },
	"single_house":    {"stage_cash_base": 300,   "stage_gems": 2,  "complete_cash": 2000,    "complete_gems": 20,   "first_gems": 30,   "income_per_min": 8   },
	"two_story_house": {"stage_cash_base": 800,   "stage_gems": 3,  "complete_cash": 5000,    "complete_gems": 40,   "first_gems": 60,   "income_per_min": 20  },
	"apartment_block": {"stage_cash_base": 2000,  "stage_gems": 5,  "complete_cash": 15000,   "complete_gems": 80,   "first_gems": 120,  "income_per_min": 60  },
	"retail_unit":     {"stage_cash_base": 5000,  "stage_gems": 8,  "complete_cash": 40000,   "complete_gems": 150,  "first_gems": 250,  "income_per_min": 150 },
	"office_block":    {"stage_cash_base": 12000, "stage_gems": 12, "complete_cash": 100000,  "complete_gems": 300,  "first_gems": 500,  "income_per_min": 400 },
	"high_rise":       {"stage_cash_base": 30000, "stage_gems": 20, "complete_cash": 300000,  "complete_gems": 600,  "first_gems": 1000, "income_per_min": 1000},
	"skyscraper":      {"stage_cash_base": 80000, "stage_gems": 30, "complete_cash": 1000000, "complete_gems": 1500, "first_gems": 2500, "income_per_min": 3000},
}

## Full tier progression (Shed → Skyscraper).
const TIER_ORDER: Array[String] = [
	"shed", "single_house", "two_story_house",
	"apartment_block", "retail_unit", "office_block",
	"high_rise", "skyscraper",
]

## All mining locations (picker shows all from level 1).
const LOCATION_ORDER: Array[String] = [
	"lumber_yard", "stone_quarry", "sand_pit", "steel_yard",
	"clay_pit", "copper_mine", "limestone_quarry", "bauxite_mine",
]

var _tiers: Dictionary = {}
var _crew_templates: Array[CrewMemberResource] = []
var _locations: Dictionary = {}

# ---------------------------------------------------------------------------
func _ready() -> void:
	_register_shed()
	_register_single_house()
	_register_two_story_house()
	_register_apartment_block()
	_register_retail_unit()
	_register_office_block()
	_register_high_rise()
	_register_skyscraper()
	_register_crew()
	_register_locations()

# ── Public API — Tiers ──────────────────────────────────────────────────────

func get_tier(tier_id: String) -> BuildingTierResource:
	return _tiers.get(tier_id, null)

## Returns the BuildStageResource for the stage the player is currently on,
## or null if the tier is complete.
func get_current_stage() -> BuildStageResource:
	var tier_id: String = GameState.current_building.get("tier_id", "shed")
	var tier := get_tier(tier_id)
	if not tier:
		return null
	var idx: int = int(GameState.current_building.get("stage_index", 0))
	if idx < 0 or idx >= tier.stages.size():
		return null
	return tier.stages[idx]

## Returns the permit id required to unlock tier_id, or "" if none needed.
func get_permit_required(tier_id: String) -> String:
	return TIER_PERMIT_REQUIRED.get(tier_id, "")

## Returns true if the player can currently select this tier
## (either no permit required, or the player holds it).
func is_tier_unlocked(tier_id: String) -> bool:
	var req: String = get_permit_required(tier_id)
	if req == "":
		return true
	return GameState.has_permit(req)

## Returns reward dict for the given tier (falls back to shed values if unknown).
func get_tier_rewards(tier_id: String) -> Dictionary:
	return TIER_REWARDS.get(tier_id, TIER_REWARDS["shed"])

## Returns the next tier id after current_tier_id, or "" if at the last tier.
func get_next_tier_id(current_tier_id: String) -> String:
	var idx := TIER_ORDER.find(current_tier_id)
	if idx < 0 or idx >= TIER_ORDER.size() - 1:
		return ""
	return TIER_ORDER[idx + 1]

# ── Public API — Locations & Nodes ─────────────────────────────────────────

## Returns location data dict or {} if not found.
func get_location(loc_id: String) -> Dictionary:
	return _locations.get(loc_id, {})

## Returns the best unlocked node for a location at the given player level,
## or {} if the location doesn't exist.
func get_active_node(loc_id: String, player_level: int) -> Dictionary:
	var loc: Dictionary = _locations.get(loc_id, {})
	if loc.is_empty():
		return {}
	var best: Dictionary = {}
	for node: Dictionary in loc.get("nodes", []):
		if int(node.get("unlock_level", 1)) <= player_level:
			best = node
	return best

## Looks up a node dict by its string id across all locations.
func get_node_data(node_id: String) -> Dictionary:
	for loc: Dictionary in _locations.values():
		for node: Dictionary in loc.get("nodes", []):
			if node.get("id", "") == node_id:
				return node
	return {}

## XP required to advance from player_level → player_level+1.
## Formula: round(50 × 1.6^(level-1))  → L1:50  L2:80  L3:128  L4:205  L5:328…
func get_xp_needed(player_level: int) -> float:
	return round(50.0 * pow(1.6, float(player_level - 1)))

## Returns the starting location_nodes dict for a fresh save.
## Called by SaveManager._init_fresh_state().
func get_default_location_nodes() -> Dictionary:
	var result: Dictionary = {}
	for loc_id: String in LOCATION_ORDER:
		var first_node := get_active_node(loc_id, 1)
		if not first_node.is_empty():
			result[loc_id] = [{
				"node_id": first_node.get("id", ""),
				"hp":      float(first_node.get("hp", 10))
			}]
	return result

## Returns the full list of crew members available to hire.
func get_hireable_crew() -> Array[CrewMemberResource]:
	return _crew_templates

# ── Tier registration ───────────────────────────────────────────────────────

func _register_shed() -> void:
	var shed := BuildingTierResource.new()
	shed.id = "shed"
	shed.display_name = "Garden Shed"
	shed.build_power_required = 0
	shed.unlock_condition = "none"
	shed.stages = [
		_stage("shed_clearance",   "Site Clearance & Groundworks",
			{"timber": 20},                     0),
		_stage("shed_foundations", "Foundations & Base",
			{"stone": 30, "timber": 10},         1),
		_stage("shed_framing",     "Wall Framing & Sheathing",
			{"timber": 40, "stone": 10},         2),
		_stage("shed_finish",      "Roof, Door & Snagging",
			{"timber": 20, "stone": 15},         3),
	]
	_tiers["shed"] = shed

func _register_single_house() -> void:
	var h := BuildingTierResource.new()
	h.id = "single_house"
	h.display_name = "Single-Storey House"
	h.build_power_required = 3
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("sh_clearance",   "Site Clearance & Groundworks",
			{"timber": 40, "stone": 25},           0),
		_stage("sh_foundations", "Foundations & Footings",
			{"concrete": 20, "stone": 15},         1),
		_stage("sh_framing",     "Ground Floor Framing",
			{"lumber": 35, "concrete": 10},        2),
		_stage("sh_sheathing",   "Wall Sheathing & Roof",
			{"lumber": 50, "concrete": 20},        3),
		_stage("sh_finish",      "Snagging & Handover",
			{"lumber": 25, "concrete": 15},        4),
	]
	_tiers["single_house"] = h

func _register_two_story_house() -> void:
	var h := BuildingTierResource.new()
	h.id = "two_story_house"
	h.display_name = "Two-Storey House"
	h.build_power_required = 8
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("th_clearance",   "Site Clearance & Groundworks",
			{"timber": 50, "stone": 35},           0),
		_stage("th_foundations", "Foundations",
			{"concrete": 35, "stone": 20},          1),
		_stage("th_gf_framing",  "Ground Floor Framing",
			{"lumber": 50, "concrete": 25},         2),
		_stage("th_ff_roof",     "First Floor, Joists & Roof",
			{"lumber": 70, "concrete": 35},         3),
		_stage("th_finish",      "Windows, Doors & Snagging",
			{"lumber": 40, "concrete": 25},         4),
	]
	_tiers["two_story_house"] = h

func _register_apartment_block() -> void:
	var h := BuildingTierResource.new()
	h.id = "apartment_block"
	h.display_name = "Apartment Block"
	h.build_power_required = 20
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("ab_clearance",   "Site Clearance & Groundworks",
			{"timber": 80, "stone": 60},                     0),
		_stage("ab_foundations", "Deep Foundations",
			{"concrete": 60, "stone": 50},                   1),
		_stage("ab_gf_struct",   "Ground Floor Structure",
			{"lumber": 80, "concrete": 60},                  2),
		_stage("ab_floors",      "Upper Floors & Lifts",
			{"lumber": 120, "concrete": 80},                 3),
		_stage("ab_cladding",    "Cladding & Glazing",
			{"lumber": 60, "glass": 40},                     4),
		_stage("ab_fitout",      "Fit-Out & Snagging",
			{"lumber": 60, "glass": 30, "concrete": 40},     5),
	]
	_tiers["apartment_block"] = h

func _register_retail_unit() -> void:
	var h := BuildingTierResource.new()
	h.id = "retail_unit"
	h.display_name = "Retail Unit"
	h.build_power_required = 40
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("ru_clearance",   "Site Clearance & Services",
			{"timber": 120, "stone": 80},                        0),
		_stage("ru_foundations", "Foundations & Ground Slab",
			{"concrete": 100, "stone": 60},                      1),
		_stage("ru_frame",       "Steel Frame Assembly",
			{"steel_beam": 30, "concrete": 80},                  2),
		_stage("ru_roof",        "Roof Deck & Structure",
			{"lumber": 100, "steel_beam": 20},                   3),
		_stage("ru_shopfront",   "Shop Front Glazing",
			{"glass": 70, "lumber": 80},                         4),
		_stage("ru_interior",    "Interior Fit-Out & Snagging",
			{"lumber": 80, "glass": 50, "concrete": 60},         5),
	]
	_tiers["retail_unit"] = h

func _register_office_block() -> void:
	var h := BuildingTierResource.new()
	h.id = "office_block"
	h.display_name = "Office Block"
	h.build_power_required = 70
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("ob_clearance",   "Site Clearance & Demolition",
			{"timber": 150, "stone": 120},                       0),
		_stage("ob_foundations", "Piled Foundations",
			{"concrete": 140, "stone": 80},                      1),
		_stage("ob_frame",       "Steel Frame & Core",
			{"steel_beam": 60, "concrete": 100},                 2),
		_stage("ob_floors",      "Floor Plates & Staircases",
			{"steel_beam": 40, "concrete": 80, "lumber": 100},   3),
		_stage("ob_curtain",     "Curtain Wall Glazing",
			{"glass": 100, "steel_beam": 30},                    4),
		_stage("ob_mande",       "M&E Installation",
			{"steel_beam": 40, "glass": 60, "lumber": 120},      5),
		_stage("ob_fitout",      "Fit-Out & Commissioning",
			{"lumber": 120, "glass": 60, "concrete": 80},        6),
	]
	_tiers["office_block"] = h

func _register_high_rise() -> void:
	var h := BuildingTierResource.new()
	h.id = "high_rise"
	h.display_name = "High-Rise Tower"
	h.build_power_required = 110
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("hr_clearance",   "Site Preparation & Hoarding",
			{"timber": 200, "stone": 150},                          0),
		_stage("hr_foundations", "Deep Pile Foundations",
			{"concrete": 180, "stone": 100},                        1),
		_stage("hr_core",        "Core Structure & Lift Shafts",
			{"steel_beam": 90, "concrete": 150},                    2),
		_stage("hr_slabs",       "Floor Slabs ×20",
			{"steel_beam": 80, "concrete": 120, "lumber": 150},     3),
		_stage("hr_skin",        "External Skin Assembly",
			{"glass": 150, "steel_beam": 60},                       4),
		_stage("hr_mep",         "Mechanical & Electrical",
			{"steel_beam": 60, "glass": 90, "lumber": 150},         5),
		_stage("hr_finish",      "Finishing & Handover",
			{"lumber": 150, "glass": 80, "concrete": 100},          6),
	]
	_tiers["high_rise"] = h

func _register_skyscraper() -> void:
	var h := BuildingTierResource.new()
	h.id = "skyscraper"
	h.display_name = "Landmark Skyscraper"
	h.build_power_required = 160
	h.unlock_condition = "build_power"
	h.stages = [
		_stage("sk_site",        "Site Acquisition & Set-Up",
			{"timber": 250, "stone": 200},                            0),
		_stage("sk_foundation",  "Mega-Foundation",
			{"concrete": 250, "stone": 150},                          1),
		_stage("sk_core",        "Core Structure & Podium",
			{"steel_beam": 130, "concrete": 220},                     2),
		_stage("sk_tower",       "Tower Structure",
			{"steel_beam": 150, "concrete": 180, "lumber": 200},      3),
		_stage("sk_spire",       "Spire & Crown",
			{"steel_beam": 120, "glass": 180},                        4),
		_stage("sk_skin",        "External Skin & Cladding",
			{"glass": 220, "steel_beam": 90, "lumber": 150},          5),
		_stage("sk_mep",         "MEP Systems & Services",
			{"steel_beam": 80, "glass": 130, "lumber": 200},          6),
		_stage("sk_fitout",      "Interior Fit-Out & Handover",
			{"lumber": 250, "glass": 150, "concrete": 150},           7),
	]
	_tiers["skyscraper"] = h

# ── Location registration ────────────────────────────────────────────────────
## Node HP/XP scaled similarly to IOM ore system.
## HP starts at 10 (Sapling / Pebble) and scales with unlock_level.
## Mine Power = player_level × 2, so level-appropriate nodes take ~5 taps.

func _register_locations() -> void:
	_locations["lumber_yard"] = {
		"display_name": "Lumber Yard",
		"material":     "timber",
		"unlock_level": 1,
		"nodes": [
			{"id": "sapling",  "name": "Sapling",  "hp": 10,  "drop_qty": 1, "xp": 2,  "unlock_level": 1},
			{"id": "pine_log", "name": "Pine Log",  "hp": 30,  "drop_qty": 2, "xp": 6,  "unlock_level": 3},
			{"id": "oak_log",  "name": "Oak Log",   "hp": 80,  "drop_qty": 3, "xp": 15, "unlock_level": 6},
			{"id": "hardwood", "name": "Hardwood",  "hp": 200, "drop_qty": 5, "xp": 35, "unlock_level": 10},
		]
	}
	_locations["stone_quarry"] = {
		"display_name": "Stone Quarry",
		"material":     "stone",
		"unlock_level": 1,
		"nodes": [
			{"id": "pebble",  "name": "Pebble",  "hp": 10,  "drop_qty": 1, "xp": 2,  "unlock_level": 1},
			{"id": "cobble",  "name": "Cobble",  "hp": 30,  "drop_qty": 2, "xp": 6,  "unlock_level": 3},
			{"id": "boulder", "name": "Boulder", "hp": 80,  "drop_qty": 3, "xp": 15, "unlock_level": 6},
			{"id": "granite", "name": "Granite", "hp": 200, "drop_qty": 5, "xp": 35, "unlock_level": 10},
		]
	}
	_locations["sand_pit"] = {
		"display_name": "Sand Pit",
		"material":     "sand",
		"unlock_level": 1,
		"nodes": [
			{"id": "sand_pile",   "name": "Sand Pile",   "hp": 10,  "drop_qty": 1, "xp": 2,  "unlock_level": 1},
			{"id": "coarse_sand", "name": "Coarse Sand", "hp": 30,  "drop_qty": 2, "xp": 6,  "unlock_level": 3},
			{"id": "fine_sand",   "name": "Fine Sand",   "hp": 80,  "drop_qty": 3, "xp": 15, "unlock_level": 6},
			{"id": "silica_bed",  "name": "Silica Bed",  "hp": 200, "drop_qty": 5, "xp": 35, "unlock_level": 10},
		]
	}
	_locations["steel_yard"] = {
		"display_name": "Steel Yard",
		"material":     "steel_ore",
		"unlock_level": 1,
		"nodes": [
			{"id": "iron_scraps",  "name": "Iron Scraps",  "hp": 12,  "drop_qty": 1, "xp": 3,  "unlock_level": 1},
			{"id": "iron_ore",     "name": "Iron Ore",     "hp": 40,  "drop_qty": 2, "xp": 8,  "unlock_level": 4},
			{"id": "steel_billet", "name": "Steel Billet", "hp": 100, "drop_qty": 3, "xp": 20, "unlock_level": 8},
			{"id": "high_grade",   "name": "High Grade",   "hp": 250, "drop_qty": 5, "xp": 45, "unlock_level": 12},
		]
	}
	_locations["clay_pit"] = {
		"display_name": "Clay Pit",
		"material":     "clay",
		"unlock_level": 1,
		"nodes": [
			{"id": "clay_mound",   "name": "Clay Mound",   "hp": 15,  "drop_qty": 1, "xp": 3,  "unlock_level": 1},
			{"id": "clay_bed",     "name": "Clay Bed",     "hp": 45,  "drop_qty": 2, "xp": 9,  "unlock_level": 4},
			{"id": "rich_clay",    "name": "Rich Clay",    "hp": 120, "drop_qty": 3, "xp": 22, "unlock_level": 8},
			{"id": "pure_clay",    "name": "Pure Clay",    "hp": 300, "drop_qty": 5, "xp": 50, "unlock_level": 13},
		]
	}
	_locations["copper_mine"] = {
		"display_name": "Copper Mine",
		"material":     "copper_ore",
		"unlock_level": 1,
		"nodes": [
			{"id": "copper_flakes", "name": "Copper Flakes", "hp": 18,  "drop_qty": 1, "xp": 4,  "unlock_level": 1},
			{"id": "copper_vein",   "name": "Copper Vein",   "hp": 55,  "drop_qty": 2, "xp": 11, "unlock_level": 5},
			{"id": "rich_vein",     "name": "Rich Vein",     "hp": 140, "drop_qty": 3, "xp": 28, "unlock_level": 9},
			{"id": "native_copper", "name": "Native Copper", "hp": 350, "drop_qty": 5, "xp": 60, "unlock_level": 14},
		]
	}
	_locations["limestone_quarry"] = {
		"display_name": "Limestone Quarry",
		"material":     "limestone",
		"unlock_level": 1,
		"nodes": [
			{"id": "limestone_slab",  "name": "Limestone Slab",  "hp": 20,  "drop_qty": 1, "xp": 5,  "unlock_level": 1},
			{"id": "limestone_block", "name": "Limestone Block",  "hp": 60,  "drop_qty": 2, "xp": 12, "unlock_level": 5},
			{"id": "fossil_bed",      "name": "Fossil Bed",       "hp": 160, "drop_qty": 3, "xp": 32, "unlock_level": 10},
			{"id": "white_limestone", "name": "White Limestone",  "hp": 400, "drop_qty": 5, "xp": 70, "unlock_level": 15},
		]
	}
	_locations["bauxite_mine"] = {
		"display_name": "Bauxite Mine",
		"material":     "bauxite",
		"unlock_level": 1,
		"nodes": [
			{"id": "bauxite_soil", "name": "Bauxite Soil",    "hp": 22,  "drop_qty": 1, "xp": 5,  "unlock_level": 1},
			{"id": "bauxite_rock", "name": "Bauxite Rock",    "hp": 70,  "drop_qty": 2, "xp": 14, "unlock_level": 6},
			{"id": "red_bauxite",  "name": "Red Bauxite",     "hp": 180, "drop_qty": 3, "xp": 36, "unlock_level": 11},
			{"id": "grade_a",      "name": "Grade-A Bauxite", "hp": 450, "drop_qty": 5, "xp": 80, "unlock_level": 16},
		]
	}

# ── Crew registration ────────────────────────────────────────────────────────
## base_speed_bonus: material/s at level 1.
## Converted to HP/s in Main.gd: hp_per_s = bonus × level × 4.

func _register_crew() -> void:
	_crew_templates = [
		_crew("old_bob",      "Old Bob",      "timber",     "lumber_yard",       40,  0.5),
		_crew("granite_pete", "Granite Pete", "stone",      "stone_quarry",      75,  1.0),
		_crew("nimble_nick",  "Nimble Nick",  "timber",     "lumber_yard",       90,  1.0),
		_crew("sandy_walsh",  "Sandy Walsh",  "sand",       "sand_pit",          70,  0.8),
		_crew("iron_mike",    "Iron Mike",    "steel_ore",  "steel_yard",        110, 1.0),
		_crew("clay_molly",   "Clay Molly",   "clay",       "clay_pit",          90,  0.8),
		_crew("copper_carl",  "Copper Carl",  "copper_ore", "copper_mine",       120, 0.9),
		_crew("lime_larry",   "Lime Larry",   "limestone",  "limestone_quarry",  140, 1.0),
		_crew("boxy_dave",    "Boxy Dave",    "bauxite",    "bauxite_mine",      160, 1.1),
	]

func _crew(id: String, crew_name: String, mat: String, loc: String,
		cost: int, bonus: float) -> CrewMemberResource:
	var c               := CrewMemberResource.new()
	c.id               = id
	c.display_name     = crew_name
	c.material_type    = mat
	c.location_id      = loc
	c.hire_cost        = cost
	c.base_speed_bonus = bonus
	c.level            = 1
	return c

# ── Factory helpers ─────────────────────────────────────────────────────────

func _stage(id: String, stage_name: String, mats: Dictionary, order: int) -> BuildStageResource:
	var s                    := BuildStageResource.new()
	s.id                      = id
	s.display_name            = stage_name
	s.required_materials      = mats
	s.stage_order             = order
	return s
