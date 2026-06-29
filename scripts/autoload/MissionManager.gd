extends Node
## Daily and weekly mission system for Project Contractor.
## Generates deterministic sets of missions from a template pool,
## tracks progress, awards rewards, and handles auto-reset.

# ── Mission template pool ────────────────────────────────────────────────────
# Each template: {type, mat (opt), target, reward_cash, reward_gems, label_fn}
# Types: collect_mat | break_nodes | craft_items | complete_stages | sell_cash

const DAILY_POOL: Array = [
	{"type": "collect_mat", "mat": "timber",    "target": 200, "reward_cash": 80,  "reward_gems": 0},
	{"type": "collect_mat", "mat": "stone",     "target": 200, "reward_cash": 80,  "reward_gems": 0},
	{"type": "collect_mat", "mat": "sand",      "target": 150, "reward_cash": 70,  "reward_gems": 0},
	{"type": "collect_mat", "mat": "steel_ore", "target": 120, "reward_cash": 90,  "reward_gems": 0},
	{"type": "collect_mat", "mat": "clay",      "target": 150, "reward_cash": 70,  "reward_gems": 0},
	{"type": "collect_mat", "mat": "copper_ore","target": 100, "reward_cash": 100, "reward_gems": 0},
	{"type": "break_nodes",                     "target": 25,  "reward_cash": 0,   "reward_gems": 1},
	{"type": "craft_items",                     "target": 10,  "reward_cash": 60,  "reward_gems": 0},
	{"type": "complete_stages",                 "target": 2,   "reward_cash": 0,   "reward_gems": 2},
	{"type": "sell_cash",                       "target": 300, "reward_cash": 0,   "reward_gems": 1},
]

const WEEKLY_POOL: Array = [
	{"type": "collect_mat", "mat": "timber",    "target": 1500, "reward_cash": 400, "reward_gems": 3},
	{"type": "collect_mat", "mat": "stone",     "target": 1200, "reward_cash": 350, "reward_gems": 2},
	{"type": "collect_mat", "mat": "sand",      "target": 1000, "reward_cash": 300, "reward_gems": 2},
	{"type": "collect_mat", "mat": "steel_ore", "target": 800,  "reward_cash": 500, "reward_gems": 2},
	{"type": "break_nodes",                     "target": 150,  "reward_cash": 200, "reward_gems": 5},
	{"type": "craft_items",                     "target": 50,   "reward_cash": 300, "reward_gems": 3},
	{"type": "complete_stages",                 "target": 6,    "reward_cash": 0,   "reward_gems": 8},
	{"type": "sell_cash",                       "target": 1200, "reward_cash": 0,   "reward_gems": 5},
]

const DAILY_COUNT  := 3
const WEEKLY_COUNT := 2

const SECS_PER_DAY  := 86400
const SECS_PER_WEEK := 604800

# Emitted when any mission's progress or state changes (so the panel can refresh).
signal missions_changed

# ── Initialisation ───────────────────────────────────────────────────────────
func _ready() -> void:
	# Wait one frame so GameState + SaveManager have fully loaded.
	await get_tree().process_frame
	_check_resets()

func _process(_delta: float) -> void:
	_check_resets()

# ── Reset logic ──────────────────────────────────────────────────────────────
var _last_reset_check: float = 0.0

func _check_resets() -> void:
	var now := Time.get_unix_time_from_system()
	if now - _last_reset_check < 60.0:
		return
	_last_reset_check = now

	var changed := false

	# Daily
	if now >= GameState.daily_reset_at:
		_generate_missions(GameState.daily_missions, DAILY_POOL, DAILY_COUNT, now, false)
		GameState.daily_reset_at = _next_midnight(now)
		changed = true

	# Weekly (Sunday midnight UTC)
	if now >= GameState.weekly_reset_at:
		_generate_missions(GameState.weekly_missions, WEEKLY_POOL, WEEKLY_COUNT, now, true)
		GameState.weekly_reset_at = _next_weekly_reset(now)
		changed = true

	if changed:
		missions_changed.emit()
		SaveManager.save_game()

## Force an immediate check (call after SaveManager.load_game finishes).
func force_check() -> void:
	_last_reset_check = 0.0
	_check_resets()

# ── Generation ───────────────────────────────────────────────────────────────
## Fills `out_array` with DAILY_COUNT / WEEKLY_COUNT mission dicts.
## Uses `now` as the seed so the selection is deterministic for the day/week.
func _generate_missions(out_array: Array, pool: Array, count: int, now: float, weekly: bool) -> void:
	out_array.clear()
	var seed_val: int = int(now / SECS_PER_WEEK) if weekly else int(now / SECS_PER_DAY)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Shuffle indices without repeating
	var indices := range(pool.size())
	for i in range(indices.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = indices[i]; indices[i] = indices[j]; indices[j] = tmp

	for i in count:
		var tmpl: Dictionary = pool[indices[i]]
		var mission := {
			"id":           "%s_%d_%d" % ["w" if weekly else "d", seed_val, i],
			"type":         tmpl["type"],
			"mat":          tmpl.get("mat", ""),
			"target":       tmpl["target"],
			"progress":     0,
			"reward_cash":  tmpl["reward_cash"],
			"reward_gems":  tmpl["reward_gems"],
			"claimed":      false,
		}
		out_array.append(mission)

# ── Progress tracking ────────────────────────────────────────────────────────
## Call this from Main.gd at relevant action points.
## type: one of the mission types above
## mat:  material id for collect_mat, "" otherwise
## amount: how much to add
func add_progress(type: String, mat: String, amount: int) -> void:
	var changed := false
	for m: Dictionary in GameState.daily_missions:
		if m["claimed"]: continue
		if _matches(m, type, mat):
			m["progress"] = mini(m["progress"] + amount, m["target"])
			changed = true
	for m: Dictionary in GameState.weekly_missions:
		if m["claimed"]: continue
		if _matches(m, type, mat):
			m["progress"] = mini(m["progress"] + amount, m["target"])
			changed = true
	if changed:
		missions_changed.emit()

func _matches(m: Dictionary, type: String, mat: String) -> bool:
	if m["type"] != type: return false
	if type == "collect_mat" and m["mat"] != mat: return false
	return true

# ── Claiming ─────────────────────────────────────────────────────────────────
func try_claim(mission_id: String) -> bool:
	for m: Dictionary in GameState.daily_missions:
		if m["id"] == mission_id:
			return _do_claim(m)
	for m: Dictionary in GameState.weekly_missions:
		if m["id"] == mission_id:
			return _do_claim(m)
	return false

func _do_claim(m: Dictionary) -> bool:
	if m["claimed"] or m["progress"] < m["target"]:
		return false
	m["claimed"] = true
	GameState.cash += m["reward_cash"]
	GameState.gems += m["reward_gems"]
	missions_changed.emit()
	SaveManager.save_game()
	return true

# ── Time helpers ─────────────────────────────────────────────────────────────
## Next UTC midnight after `now`.
func _next_midnight(now: float) -> float:
	return float(int(now / SECS_PER_DAY + 1) * SECS_PER_DAY)

## Next Sunday 00:00 UTC after `now`.
func _next_weekly_reset(now: float) -> float:
	return float(int(now / SECS_PER_WEEK + 1) * SECS_PER_WEEK)

## Human-readable countdown string.
func time_until_string(target: float) -> String:
	var secs: int = maxi(0, int(target - Time.get_unix_time_from_system()))
	var h: int = int(secs / 3600.0)
	var m: int = int((secs % 3600) / 60.0)
	var s: int = secs % 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm %02ds" % [m, s]

# ── Label helpers ─────────────────────────────────────────────────────────────
func mission_label(m: Dictionary) -> String:
	match m["type"]:
		"collect_mat":    return "Collect %s %s" % [_fmt(m["target"]), _mat_name(m["mat"])]
		"break_nodes":    return "Break %d nodes" % m["target"]
		"craft_items":    return "Craft %d items" % m["target"]
		"complete_stages":return "Complete %d build stages" % m["target"]
		"sell_cash":      return "Earn $%s from selling" % _fmt(m["target"])
	return "Mission"

func reward_label(m: Dictionary) -> String:
	var parts: Array = []
	if m["reward_cash"] > 0: parts.append("$%s" % _fmt(m["reward_cash"]))
	if m["reward_gems"]  > 0: parts.append("%d💎" % m["reward_gems"])
	return "  ".join(parts)

func _mat_name(mat: String) -> String:
	return mat.replace("_", " ").capitalize()

func _fmt(n: int) -> String:
	if n >= 1_000_000: return "%.1fM" % (float(n) / 1_000_000.0)
	if n >= 10_000:    return "%.1fK" % (float(n) / 1_000.0)
	return "%d" % n
