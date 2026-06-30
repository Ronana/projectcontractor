extends Node
## Central runtime state. All values are plain GDScript types so they
## serialise cleanly to JSON via SaveManager.
## Do NOT store Godot Resource objects here -- keep those in /data/resources/.

# -- Currency ----------------------------------------------------------------
var cash: int = 100
var gems: int = 0

# -- Materials ---------------------------------------------------------------
## Keys: material id (String) -> current inventory count (int).
var materials: Dictionary = {}

# -- Crew --------------------------------------------------------------------
## Each entry is a plain Dictionary:
## { "id", "display_name", "level", "material_type", "base_speed_bonus", "location_id" }
var crew: Array = []

# -- Active build ------------------------------------------------------------
## Tracks the single building currently under construction.
## stage_started: true once materials are consumed and tapping has begun.
var current_building: Dictionary = {
	"tier_id":       "shed",
	"stage_index":   0,
	"stage_progress": 0.0,  # 0.0 -> 1.0 tap progress within the started stage
	"stage_started": false,  # true = materials consumed, tap to build
}

# -- Skyline -----------------------------------------------------------------
## Ordered list of tier_ids for every building ever completed.
var skyline: Array = []

# -- Player progression ------------------------------------------------------
## Player level (Mine Power = player_level × 2).
var player_level: int = 1
## XP accumulated toward the next level.
var player_xp: float = 0.0

# -- Mining ------------------------------------------------------------------
## Which location is currently selected on the Mine screen.
var active_location_id: String = "lumber_yard"
## Per-location node state: { loc_id: Array[{ "node_id": String, "hp": float }] }
## Each location holds active_node_count entries. Persisted for offline worker progress.
var location_nodes: Dictionary = {}
## How many nodes are active per location simultaneously (upgradeable, starts at 1).
var active_node_count: int = 1
## Nodes broken per location this contract (resets on prestige). Used for unlock gating.
var location_unlock_progress: Dictionary = {}

# -- Upgrades ----------------------------------------------------------------
## Keys: upgrade_id (String) -> purchased level (int, 0 = not bought).
var upgrades: Dictionary = {}

# -- Permanent (survive New Contract reset) ----------------------------------
## Cumulative Reputation Points earned across all contracts.
var reputation_points: int = 0
## Number of New Contracts signed so far (prestige count).
var contract_count: int = 0
## All buildings ever completed across every contract, in order.
var portfolio: Array = []
## Permanent artifacts bought with Reputation Points: artifact_id -> level.
var artifacts: Dictionary = {}

# -- UI preferences (survive prestige, never reset) -------------------------
## Shortcut IDs pinned to the quick bar (up to 4). Not reset on New Contract.
var pinned_shortcuts: Array = ["build", "crew", "craft", "sell"]

# -- Missions ----------------------------------------------------------------
## Active daily missions: Array of Dicts (see MissionManager for schema).
var daily_missions:  Array = []
## Active weekly missions.
var weekly_missions: Array = []
## Unix timestamp of next daily reset.
var daily_reset_at:  float = 0.0
## Unix timestamp of next weekly reset.
var weekly_reset_at: float = 0.0

# -- Toolbox -----------------------------------------------------------------
## Owned item counts: item_id → count.
var inventory: Dictionary = {}
## Active temporary boosts: effect_type → {mult, flat, expires_at}.
var active_boosts: Dictionary = {}

# -- Blueprints & Permits ----------------------------------------------------
## bp_id → { "level": int (0–5), "fragments": int (toward next level) }.
var blueprints: Dictionary = {}
## Array of permit ids that have been awarded (e.g. "commercial_permit").
var permits: Array = []

# -- First completions (permanent, survives prestige) ------------------------
## Tier IDs completed at least once across all contracts.
var first_completions: Array = []

# -- Site Inspections (permanent, survives prestige) -------------------------
## Inspection IDs passed at least once across all contracts.
var completed_inspections: Array = []

# -- Lifetime stats (permanent, never reset) ---------------------------------
## Total nodes broken across all contracts, all time.
var lifetime_nodes_broken: int = 0

# -- Trade Shows -------------------------------------------------------------
## State for the currently active (or most recently expired) Trade Show event.
## Resets when a new event starts. Resets on prestige.
## Fields:
##   event_index     : int    — index into TradeShowDatabase.EVENTS
##   expires_at      : float  — unix timestamp when this event ends
##   task_progress   : Dictionary  task_id → int progress
##   claimed_rewards : Array[int]  0=unclaimed 1=claimed per reward tier
var trade_show_state: Dictionary = {
	"event_index":     0,
	"expires_at":      0.0,
	"task_progress":   {},
	"claimed_rewards": [0, 0, 0],
}

# -- Skill tree --------------------------------------------------------------
## Unspent Skill Points available to spend on the skill tree.
var skill_points: int = 0
## Purchased skills: skill_id → true. Only purchased skills appear here.
var skill_tree: Dictionary = {}

# -- Intro tasks (permanent, never reset) -----------------------------------
## Index of the current intro task (== INTRO_TASKS.size() when all complete).
var intro_task_index: int = 0
## Whether the strip is visible (player can dismiss it).
var intro_strip_visible: bool = true

# -- Tutorial progress counters (permanent, never reset) --------------------
## Total timber ever collected across all contracts.
var timber_collected: int = 0
## Total sand ever collected.
var sand_collected: int = 0
## Total lumber ever crafted.
var lumber_crafted: int = 0
## Total materials sold (any sell action = 1 per button press).
var materials_sold: int = 0
## 1 if stone quarry has been visited, else 0.
var visited_stone_quarry: int = 0
## 1 if sand pit has been visited, else 0.
var visited_sand_pit: int = 0
## Total blasting caps ever fired.
var blasting_caps_fired: int = 0

# -- Chest system ------------------------------------------------------------
## Pending chests per location: loc_id → chest_type ("delivery_pallet" | "vintage_chest" | "")
var pending_chests: Dictionary = {}
## Permanent stat modifiers from Vintage Tool Chests: Array of {effect, value, label, rarity}
var chest_modifiers: Array = []

## Sum of all chest modifier values for a given effect key.
func get_chest_modifier_bonus(effect: String) -> float:
	var total := 0.0
	for m: Dictionary in chest_modifiers:
		if m.get("effect", "") == effect:
			total += float(m.get("value", 0.0))
	return total
## Unix timestamp when blasting cap cooldown expires (0 = ready).
var blasting_cap_cooldown_until: float = 0.0
## Total toolbox items ever used.
var toolbox_items_used: int = 0
## Total delivery pallets ever opened (placeholder until chest system is implemented).
var delivery_pallets_opened: int = 0
## Total vintage tool chests ever opened (placeholder).
var vintage_chests_opened: int = 0

# -- Consent (permanent, never reset) ---------------------------------------
## True once the player has accepted the privacy/analytics agreement.
var privacy_agreed: bool = false

# -- Save metadata -----------------------------------------------------------
var last_saved_timestamp: float = 0.0

# ---------------------------------------------------------------------------
## Returns the active boost multiplier for an effect type, or 1.0 if none/expired.
func get_boost_mult(boost_type: String) -> float:
	if not active_boosts.has(boost_type):
		return 1.0
	var b: Dictionary = active_boosts[boost_type]
	if Time.get_unix_time_from_system() >= float(b.get("expires_at", 0)):
		active_boosts.erase(boost_type)
		return 1.0
	return float(b.get("mult", 1.0))

## Returns the active flat boost for an effect type, or 0 if none/expired.
func get_boost_flat(boost_type: String) -> int:
	if not active_boosts.has(boost_type):
		return 0
	var b: Dictionary = active_boosts[boost_type]
	if Time.get_unix_time_from_system() >= float(b.get("expires_at", 0)):
		active_boosts.erase(boost_type)
		return 0
	return int(b.get("flat", 0))

## Derived stat: sum of all hired crew member levels,
## multiplied by the Power Tools upgrade bonus and any active build_power boost.
func get_build_power() -> int:
	var total := 0
	for member: Dictionary in crew:
		total += int(member.get("level", 1))
	var mult := 1.0 + UpgradeDatabase.get_total_bonus("power_tools", upgrades.get("power_tools", 0))
	mult *= 1.0 + get_skill_bonus("build_power_pct")
	mult *= 1.0 + get_chest_modifier_bonus("build_power_pct")
	return max(int(float(total) * mult * get_boost_mult("build_power")), 0)

## Derived stat: damage per tap to ore nodes.
## Stacks Sharper Tools upgrade + Veteran Foreman artifact.
func get_mine_power() -> int:
	var base := player_level * 2
	var mult := 1.0 + UpgradeDatabase.get_total_bonus("sharper_tools", upgrades.get("sharper_tools", 0))
	mult *= 1.0 + ArtifactDatabase.get_total_bonus("veteran_foreman", artifacts.get("veteran_foreman", 0))
	mult *= 1.0 + get_skill_bonus("mine_power_pct")
	mult *= 1.0 + get_chest_modifier_bonus("mine_power_pct")
	return max(int(float(base) * mult * get_boost_mult("mine_power")), 1)

## Multiplier applied to worker HP/s from the Quick Crew upgrade + active boost.
func get_worker_rate_mult() -> float:
	return (1.0 + UpgradeDatabase.get_total_bonus("quick_crew", upgrades.get("quick_crew", 0)) \
		+ get_skill_bonus("worker_rate_pct") \
		+ get_chest_modifier_bonus("worker_rate_pct")) \
		* get_boost_mult("worker_rate")

## Flat bonus drops per node break. Stacks Bonus Drop upgrade + artifact + active boost.
func get_drop_bonus() -> int:
	var upgrade_bonus  := int(UpgradeDatabase.get_total_bonus("bonus_drop", upgrades.get("bonus_drop", 0)))
	var artifact_bonus := int(ArtifactDatabase.get_total_bonus("quality_materials", artifacts.get("quality_materials", 0)))
	var skill_bonus    := int(get_skill_bonus("drop_bonus"))
	var chest_bonus    := int(get_chest_modifier_bonus("drop_bonus_flat"))
	return upgrade_bonus + artifact_bonus + skill_bonus + chest_bonus + get_boost_flat("drop_bonus")

## XP multiplier. Stacks XP Rush upgrade + Fast Learner artifact + active boost.
func get_xp_mult() -> float:
	var base := 1.0 + UpgradeDatabase.get_total_bonus("xp_rush", upgrades.get("xp_rush", 0))
	return base \
		* (1.0 + ArtifactDatabase.get_total_bonus("fast_learner", artifacts.get("fast_learner", 0))) \
		* (1.0 + get_skill_bonus("xp_pct")) \
		* (1.0 + get_chest_modifier_bonus("xp_pct")) \
		* get_boost_mult("xp_mult")

## Cash multiplier applied to stage completion rewards.
## Stacks Cash Bonus upgrade + Site Reputation artifact + active boost.
func get_stage_cash_mult() -> float:
	var base := 1.0 + UpgradeDatabase.get_total_bonus("cash_bonus", upgrades.get("cash_bonus", 0))
	return base \
		* (1.0 + ArtifactDatabase.get_total_bonus("site_reputation", artifacts.get("site_reputation", 0))) \
		* (1.0 + get_skill_bonus("stage_cash_pct")) \
		* (1.0 + get_chest_modifier_bonus("stage_cash_pct")) \
		* get_boost_mult("stage_cash")

## Blueprint yield multiplier for a material (raw or refined).
## Stacks multiplicatively on top of drop_bonus (which is flat).
func get_mat_yield_mult(mat_id: String) -> float:
	var bp_id := "bp_" + mat_id
	var entry: Dictionary = blueprints.get(bp_id, {})
	var lvl: int = int(entry.get("level", 0))
	return 1.0 + BlueprintDatabase.total_bonus(lvl)

## Stage cash multiplier from building blueprints.
func get_building_cash_mult(tier_id: String) -> float:
	var bp_id := "bp_" + tier_id
	var entry: Dictionary = blueprints.get(bp_id, {})
	var lvl: int = int(entry.get("level", 0))
	return 1.0 + BlueprintDatabase.total_bonus(lvl)

## Returns true if the player currently holds the named permit.
func has_permit(permit_id: String) -> bool:
	return permits.has(permit_id)

## Returns the total bonus granted by all purchased skill tree nodes for a given effect type.
func get_skill_bonus(effect: String) -> float:
	return SkillDatabase.get_total_effect_bonus(effect, skill_tree)

## Returns passive cash per minute generated by all buildings in the skyline.
func get_property_income_rate() -> float:
	var total := 0.0
	for tier_id: String in skyline:
		var rewards: Dictionary = BuildDatabase.TIER_REWARDS.get(tier_id, {})
		total += float(rewards.get("income_per_min", 0))
	return total

## Chance (0.0–1.0) to yield 2× output when crafting.
func get_double_craft_chance() -> float:
	return UpgradeDatabase.get_total_bonus("double_craft", upgrades.get("double_craft", 0)) \
		+ get_skill_bonus("double_craft_chance")

## Extra build progress multiplier from the Fast Build upgrade.
func get_build_progress_mult() -> float:
	return 1.0 + UpgradeDatabase.get_total_bonus("fast_build", upgrades.get("fast_build", 0)) \
		+ get_skill_bonus("build_progress_pct")

## Starting level for newly hired crew, boosted by Experienced Crew artifact.
func get_crew_start_level() -> int:
	return 1 + int(ArtifactDatabase.get_total_bonus("experienced_crew", artifacts.get("experienced_crew", 0)))
