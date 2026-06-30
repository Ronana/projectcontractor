extends Node
## Handles all save/load for Project Contractor.
## Runs load_game() at startup, autosaves every 30 s, and saves on
## app-pause / window-close so no progress is lost on mobile.

const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 30.0

var _autosave_timer: float = 0.0

# ---------------------------------------------------------------------------
func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

# ---------------------------------------------------------------------------
func save_game() -> void:
	var now := Time.get_unix_time_from_system()
	GameState.last_saved_timestamp = now

	var data := {
		"version":               4,
		# -- Temporary (reset on New Contract) --
		"cash":                  GameState.cash,
		"gems":                  GameState.gems,
		"materials":             GameState.materials,
		"crew":                  GameState.crew,
		"current_building":      GameState.current_building,
		"skyline":               GameState.skyline,
		"player_level":          GameState.player_level,
		"player_xp":             GameState.player_xp,
		"active_location_id":    GameState.active_location_id,
		"location_nodes":             GameState.location_nodes,
		"active_node_count":          GameState.active_node_count,
		"location_unlock_progress":   GameState.location_unlock_progress,
		"upgrades":              GameState.upgrades,
		# -- Permanent (survive New Contract reset) --
		"reputation_points":     GameState.reputation_points,
		"contract_count":        GameState.contract_count,
		"portfolio":             GameState.portfolio,
		"artifacts":             GameState.artifacts,
		"last_saved_timestamp":  now,
		# -- UI preferences (permanent, survive prestige) --
		"pinned_shortcuts":      GameState.pinned_shortcuts,
		# -- Missions --
		"daily_missions":        GameState.daily_missions,
		"weekly_missions":       GameState.weekly_missions,
		"daily_reset_at":        GameState.daily_reset_at,
		"weekly_reset_at":       GameState.weekly_reset_at,
		# -- Toolbox --
		"inventory":             GameState.inventory,
		"active_boosts":         GameState.active_boosts,
		# -- Blueprints & Permits --
		"blueprints":            GameState.blueprints,
		"permits":               GameState.permits,
		# -- First completions (permanent) --
		"first_completions":     GameState.first_completions,
		# -- Site Inspections (permanent) --
		"completed_inspections": GameState.completed_inspections,
		# -- Lifetime stats (permanent) --
		"lifetime_nodes_broken": GameState.lifetime_nodes_broken,
		# -- Trade Shows --
		"trade_show_state":      GameState.trade_show_state,
		# -- Skill tree --
		"skill_points":          GameState.skill_points,
		"skill_tree":            GameState.skill_tree,
		# -- Intro tasks (permanent) --
		"intro_task_index":      GameState.intro_task_index,
		"intro_strip_visible":   GameState.intro_strip_visible,
		# -- Tutorial progress counters (permanent) --
		"timber_collected":      GameState.timber_collected,
		"sand_collected":        GameState.sand_collected,
		"lumber_crafted":        GameState.lumber_crafted,
		"materials_sold":        GameState.materials_sold,
		"visited_stone_quarry":  GameState.visited_stone_quarry,
		"visited_sand_pit":      GameState.visited_sand_pit,
		"blasting_caps_fired":           GameState.blasting_caps_fired,
		"blasting_cap_cooldown_until":   GameState.blasting_cap_cooldown_until,
		# -- Chest system (permanent modifiers) --
		"chest_modifiers":               GameState.chest_modifiers,
		"pending_chests":                GameState.pending_chests,
		"toolbox_items_used":    GameState.toolbox_items_used,
		"delivery_pallets_opened": GameState.delivery_pallets_opened,
		"vintage_chests_opened": GameState.vintage_chests_opened,
		# -- Consent (permanent) --
		"privacy_agreed":        GameState.privacy_agreed,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		push_error("SaveManager: could not open '%s' for writing (error %d)" \
			% [SAVE_PATH, FileAccess.get_open_error()])

# ---------------------------------------------------------------------------
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_init_fresh_state()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: could not open '%s' for reading." % SAVE_PATH)
		_init_fresh_state()
		return

	var raw := file.get_as_text()
	file.close()

	var parser := JSON.new()
	if parser.parse(raw) != OK:
		push_error("SaveManager: JSON parse error in save file -- starting fresh.")
		_init_fresh_state()
		return

	var d: Dictionary = parser.get_data()
	GameState.cash                 = d.get("cash", 100)
	GameState.gems                 = d.get("gems", 0)
	GameState.materials            = d.get("materials", {})
	GameState.crew                 = d.get("crew", [])
	GameState.current_building     = d.get("current_building", _default_building())
	GameState.skyline              = d.get("skyline", [])
	GameState.player_level         = int(d.get("player_level", 1))
	GameState.player_xp            = float(d.get("player_xp", 0.0))
	GameState.active_location_id   = d.get("active_location_id", "lumber_yard")
	GameState.last_saved_timestamp = d.get("last_saved_timestamp",
		Time.get_unix_time_from_system())

	# Migrate v1/v2/v3 saves: ensure new fields exist
	if not GameState.current_building.has("stage_started"):
		GameState.current_building["stage_started"] = false
	if not GameState.current_building.has("stage_progress"):
		GameState.current_building["stage_progress"] = 0.0
	GameState.upgrades            = d.get("upgrades", {})

	# -- Permanent fields (always loaded, never reset by prestige) --
	GameState.reputation_points   = int(d.get("reputation_points", 0))
	GameState.contract_count      = int(d.get("contract_count", 0))
	GameState.portfolio           = d.get("portfolio", [])
	GameState.artifacts           = d.get("artifacts", {})
	GameState.pinned_shortcuts    = d.get("pinned_shortcuts", ["build", "crew", "craft", "sell"])

	# -- Missions (loaded but MissionManager will regenerate if timestamps expired) --
	GameState.daily_missions      = d.get("daily_missions",  [])
	GameState.weekly_missions     = d.get("weekly_missions", [])
	GameState.daily_reset_at      = float(d.get("daily_reset_at",  0.0))
	GameState.weekly_reset_at     = float(d.get("weekly_reset_at", 0.0))

	# -- Toolbox --
	GameState.inventory           = d.get("inventory",     {})
	GameState.active_boosts       = d.get("active_boosts", {})

	# -- Blueprints & Permits --
	GameState.blueprints          = d.get("blueprints", {})
	GameState.permits             = d.get("permits",    [])
	# -- First completions (permanent) --
	GameState.first_completions      = d.get("first_completions", [])
	# -- Site Inspections (permanent) --
	GameState.completed_inspections  = d.get("completed_inspections", [])
	# -- Lifetime stats (permanent) --
	GameState.lifetime_nodes_broken  = int(d.get("lifetime_nodes_broken", 0))
	# -- Trade Shows --
	GameState.trade_show_state       = d.get("trade_show_state", {
		"event_index": 0, "expires_at": 0.0,
		"task_progress": {}, "claimed_rewards": [0, 0, 0],
	})
	# -- Skill tree --
	GameState.skill_points           = int(d.get("skill_points", 0))
	GameState.skill_tree             = d.get("skill_tree", {})
	# -- Intro tasks (permanent) --
	GameState.intro_task_index       = int(d.get("intro_task_index", 0))
	GameState.intro_strip_visible    = bool(d.get("intro_strip_visible", true))
	# -- Tutorial progress counters (permanent) --
	GameState.timber_collected       = int(d.get("timber_collected", 0))
	GameState.sand_collected         = int(d.get("sand_collected", 0))
	GameState.lumber_crafted         = int(d.get("lumber_crafted", 0))
	GameState.materials_sold         = int(d.get("materials_sold", 0))
	GameState.visited_stone_quarry   = int(d.get("visited_stone_quarry", 0))
	GameState.visited_sand_pit       = int(d.get("visited_sand_pit", 0))
	GameState.blasting_caps_fired            = int(d.get("blasting_caps_fired", 0))
	GameState.blasting_cap_cooldown_until    = float(d.get("blasting_cap_cooldown_until", 0.0))
	# -- Chest system --
	GameState.chest_modifiers                = d.get("chest_modifiers", [])
	GameState.pending_chests                 = d.get("pending_chests", {})
	GameState.toolbox_items_used     = int(d.get("toolbox_items_used", 0))
	GameState.delivery_pallets_opened = int(d.get("delivery_pallets_opened", 0))
	GameState.vintage_chests_opened  = int(d.get("vintage_chests_opened", 0))
	# -- Consent (permanent) --
	GameState.privacy_agreed         = bool(d.get("privacy_agreed", false))

	# Migrate crew: add location_id if missing (timber → lumber_yard, stone → stone_quarry)
	for member: Dictionary in GameState.crew:
		if not member.has("location_id") or member["location_id"] == "":
			var mat: String = member.get("material_type", "timber")
			member["location_id"] = "stone_quarry" if mat == "stone" else "lumber_yard"

	GameState.active_node_count          = int(d.get("active_node_count", 1))
	GameState.location_unlock_progress   = d.get("location_unlock_progress", {})

	# Load location_nodes; migrate old single-dict format → array; fill missing from defaults
	var saved_nodes: Dictionary = d.get("location_nodes", {})
	var defaults := BuildDatabase.get_default_location_nodes()
	for loc_id: String in defaults.keys():
		if saved_nodes.has(loc_id):
			var val = saved_nodes[loc_id]
			# Migrate v4 single-dict → array
			GameState.location_nodes[loc_id] = [val] if val is Dictionary else val
		else:
			GameState.location_nodes[loc_id] = defaults[loc_id]
	# Pad each location's node array to match active_node_count
	for loc_id: String in GameState.location_nodes.keys():
		var nodes: Array = GameState.location_nodes[loc_id]
		while nodes.size() < GameState.active_node_count:
			var best := BuildDatabase.get_active_node(loc_id, GameState.player_level)
			if best.is_empty(): break
			var base_hp: float = float(best.get("hp", 10))
			var hp: float = roundf(base_hp * randf_range(0.8, 1.2))
			nodes.append({"node_id": best.get("id",""), "hp": hp, "max_hp": hp})

# ---------------------------------------------------------------------------
func _init_fresh_state() -> void:
	GameState.cash                 = 100
	GameState.gems                 = 0
	GameState.materials            = {}
	GameState.crew                 = []
	GameState.current_building     = _default_building()
	GameState.skyline              = []
	GameState.player_level         = 1
	GameState.player_xp            = 0.0
	GameState.active_location_id         = "lumber_yard"
	GameState.active_node_count          = 1
	GameState.location_nodes             = BuildDatabase.get_default_location_nodes()
	GameState.location_unlock_progress   = {}
	GameState.upgrades             = {}
	GameState.reputation_points    = 0
	GameState.contract_count       = 0
	GameState.portfolio            = []
	GameState.artifacts            = {}
	GameState.last_saved_timestamp = Time.get_unix_time_from_system()
	GameState.pinned_shortcuts     = ["build", "crew", "craft", "sell"]
	GameState.inventory            = {}
	GameState.active_boosts        = {}
	GameState.blueprints           = {}
	GameState.permits              = []
	GameState.first_completions      = []
	GameState.completed_inspections  = []
	GameState.lifetime_nodes_broken  = 0
	GameState.trade_show_state       = {
		"event_index": 0, "expires_at": 0.0,
		"task_progress": {}, "claimed_rewards": [0, 0, 0],
	}
	GameState.skill_points           = 0
	GameState.skill_tree             = {}
	GameState.intro_task_index       = 0
	GameState.intro_strip_visible    = true
	GameState.timber_collected       = 0
	GameState.sand_collected         = 0
	GameState.lumber_crafted         = 0
	GameState.materials_sold         = 0
	GameState.visited_stone_quarry   = 0
	GameState.visited_sand_pit       = 0
	GameState.blasting_caps_fired            = 0
	GameState.blasting_cap_cooldown_until    = 0.0
	GameState.chest_modifiers                = []
	GameState.pending_chests                 = {}
	GameState.toolbox_items_used     = 0
	GameState.delivery_pallets_opened = 0
	GameState.vintage_chests_opened  = 0
	GameState.privacy_agreed         = false

## Reset all temporary state for a New Contract (prestige).
## rep_earned is added to the permanent reputation_points total.
## Permanent fields (gems, rep, portfolio, artifacts) survive.
func prestige_reset(rep_earned: int) -> void:
	# Accumulate permanent gains
	GameState.reputation_points += rep_earned
	GameState.contract_count    += 1
	# Move this contract's skyline into the all-time portfolio
	for b: String in GameState.skyline:
		GameState.portfolio.append(b)
	# Reset temporary state (gems survive)
	GameState.cash               = 100
	GameState.materials          = {}
	GameState.crew               = []
	GameState.current_building   = _default_building()
	GameState.skyline            = []
	GameState.player_level       = 1
	GameState.player_xp          = 0.0
	GameState.active_location_id         = "lumber_yard"
	GameState.location_nodes             = BuildDatabase.get_default_location_nodes()
	GameState.location_unlock_progress   = {}
	GameState.upgrades           = {}
	GameState.skill_points       = 0
	GameState.skill_tree         = {}
	GameState.trade_show_state   = {
		"event_index": 0, "expires_at": 0.0,
		"task_progress": {}, "claimed_rewards": [0, 0, 0],
	}
	save_game()

func _default_building() -> Dictionary:
	return {
		"tier_id":        "shed",
		"stage_index":    0,
		"stage_progress": 0.0,
		"stage_started":  false,
	}
