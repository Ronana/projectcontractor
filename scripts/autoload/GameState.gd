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

# -- Save metadata -----------------------------------------------------------
var last_saved_timestamp: float = 0.0

# ---------------------------------------------------------------------------
## Derived stat: sum of all hired crew member levels,
## multiplied by the Power Tools upgrade bonus.
func get_build_power() -> int:
	var total := 0
	for member: Dictionary in crew:
		total += int(member.get("level", 1))
	var mult := 1.0 + UpgradeDatabase.get_total_bonus("power_tools", upgrades.get("power_tools", 0))
	return max(int(float(total) * mult), 0)

## Derived stat: damage per tap to ore nodes.
## Stacks Sharper Tools upgrade + Veteran Foreman artifact.
func get_mine_power() -> int:
	var base := player_level * 2
	var mult := 1.0 + UpgradeDatabase.get_total_bonus("sharper_tools", upgrades.get("sharper_tools", 0))
	mult *= 1.0 + ArtifactDatabase.get_total_bonus("veteran_foreman", artifacts.get("veteran_foreman", 0))
	return max(int(float(base) * mult), 1)

## Multiplier applied to worker HP/s from the Quick Crew upgrade.
func get_worker_rate_mult() -> float:
	return 1.0 + UpgradeDatabase.get_total_bonus("quick_crew", upgrades.get("quick_crew", 0))

## Flat bonus drops per node break. Stacks Bonus Drop upgrade + Quality Materials artifact.
func get_drop_bonus() -> int:
	var upgrade_bonus  := int(UpgradeDatabase.get_total_bonus("bonus_drop", upgrades.get("bonus_drop", 0)))
	var artifact_bonus := int(ArtifactDatabase.get_total_bonus("quality_materials", artifacts.get("quality_materials", 0)))
	return upgrade_bonus + artifact_bonus

## XP multiplier. Stacks XP Rush upgrade + Fast Learner artifact.
func get_xp_mult() -> float:
	var base := 1.0 + UpgradeDatabase.get_total_bonus("xp_rush", upgrades.get("xp_rush", 0))
	return base * (1.0 + ArtifactDatabase.get_total_bonus("fast_learner", artifacts.get("fast_learner", 0)))

## Cash multiplier applied to stage completion rewards.
## Stacks Cash Bonus upgrade + Site Reputation artifact.
func get_stage_cash_mult() -> float:
	var base := 1.0 + UpgradeDatabase.get_total_bonus("cash_bonus", upgrades.get("cash_bonus", 0))
	return base * (1.0 + ArtifactDatabase.get_total_bonus("site_reputation", artifacts.get("site_reputation", 0)))

## Chance (0.0–1.0) to yield 2× output when crafting.
func get_double_craft_chance() -> float:
	return UpgradeDatabase.get_total_bonus("double_craft", upgrades.get("double_craft", 0))

## Extra build progress multiplier from the Fast Build upgrade.
func get_build_progress_mult() -> float:
	return 1.0 + UpgradeDatabase.get_total_bonus("fast_build", upgrades.get("fast_build", 0))

## Starting level for newly hired crew, boosted by Experienced Crew artifact.
func get_crew_start_level() -> int:
	return 1 + int(ArtifactDatabase.get_total_bonus("experienced_crew", artifacts.get("experienced_crew", 0)))
