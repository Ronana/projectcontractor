extends SceneTree
## Headless regression tests for Project Contractor.
##
## Run from the project root:
##   godot --headless --path . -s res://tests/test_runner.gd
## Exit code 0 = all tests passed, 1 = at least one failure.
##
## The suite redirects SaveManager to its own file under user://test_run/
## before any autoload runs, so the player's real save is never read or written.
## Every test_* method starts from a fresh game state (see _fresh()).

const TEST_DIR  := "user://test_run"
const TEST_SAVE := TEST_DIR + "/save.json"
const TEST_BAK  := TEST_DIR + "/save.bak.json"
const TEST_BAD  := TEST_DIR + "/save.corrupt.json"

var GS: Node
var SM: Node
var BD: Node
var BPD: Node
var OPC: Node
var _main: Node

var _passed := 0
var _failed := 0
var _checks := 0
var _test_failed := false

# ── Runner ──────────────────────────────────────────────────────────────────

func _initialize() -> void:
	# Runs before the autoloads' _ready(), so SaveManager never opens the real save.
	GS  = root.get_node("GameState")
	SM  = root.get_node("SaveManager")
	BD  = root.get_node("BuildDatabase")
	BPD = root.get_node("BlueprintDatabase")
	OPC = root.get_node("OfflineProgressCalculator")
	SM.save_path = TEST_SAVE
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_wipe_test_files()
	call_deferred("_run")

func _run() -> void:
	_main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(_main)
	for i in 3:
		await process_frame  # Main._ready awaits a frame before building its UI

	for m: Dictionary in get_script().get_script_method_list():
		var test_name: String = m["name"]
		if not test_name.begins_with("test_"):
			continue
		_fresh()
		_checks = 0
		_test_failed = false
		call(test_name)
		if _checks == 0:
			# A script error aborted the test before it asserted anything.
			_test_failed = true
			print("    FAIL: test aborted before making any assertion")
		if _test_failed:
			_failed += 1
			print("FAIL  %s" % test_name)
		else:
			_passed += 1
			print("ok    %s" % test_name)

	print("\n%d passed, %d failed" % [_passed, _failed])
	_wipe_test_files()
	quit(1 if _failed > 0 else 0)

# ── Helpers ─────────────────────────────────────────────────────────────────

func _fresh() -> void:
	_wipe_test_files()
	SM.load_game()  # no save file → fresh state

func _wipe_test_files() -> void:
	for f in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + "/" + f)

func _expect(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_test_failed = true
		print("    FAIL: %s" % what)

## Strict equality: a float 7.0 does NOT equal the int 7.
func _expect_eq(actual: Variant, expected: Variant, what: String) -> void:
	var same: bool = typeof(actual) == typeof(expected) and actual == expected
	_expect(same, "%s — expected %s (%s), got %s (%s)" % [what,
		str(expected), type_string(typeof(expected)), str(actual), type_string(typeof(actual))])

func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _live_children(n: Node) -> Array:
	return n.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())

func _now() -> float:
	return Time.get_unix_time_from_system()

func _old_bob(level: int) -> Dictionary:
	return {"id": "old_bob", "display_name": "Old Bob", "level": level,
		"material_type": "timber", "base_speed_bonus": 0.5, "location_id": "lumber_yard"}

# ── Save safety ─────────────────────────────────────────────────────────────

func test_save_keeps_previous_save_as_backup() -> void:
	GS.cash = 111
	SM.save_game()
	GS.cash = 222
	SM.save_game()
	_expect_eq(int(_read_json(TEST_BAK).get("cash", -1)), 111, "backup holds the previous save")
	_expect_eq(int(_read_json(TEST_SAVE).get("cash", -1)), 222, "main file holds the latest save")

func test_corrupt_save_is_recovered_from_backup() -> void:
	GS.cash = 111
	SM.save_game()
	GS.cash = 222
	SM.save_game()
	_write_text(TEST_SAVE, "{ \"cash\": 22")  # truncated mid-write
	SM.load_game()
	_expect_eq(GS.cash, 111, "cash restored from backup")

func test_missing_save_is_recovered_from_backup() -> void:
	# App killed between moving the old save aside and moving the new one in.
	GS.cash = 111
	SM.save_game()
	GS.cash = 222
	SM.save_game()
	DirAccess.remove_absolute(TEST_SAVE)
	SM.load_game()
	_expect_eq(GS.cash, 111, "cash restored from backup")

func test_unrecoverable_save_is_kept_for_inspection() -> void:
	_write_text(TEST_SAVE, "not json at all")
	SM.load_game()
	_expect_eq(GS.cash, 100, "falls back to a fresh game")
	_expect_eq(FileAccess.get_file_as_string(TEST_BAD), "not json at all",
		"corrupt file copied aside before it can be overwritten")

func test_counts_stay_integers_after_reload() -> void:
	GS.materials                = {"timber": 7}
	GS.utility_counts["blast_cap"] = 200
	GS.upgrades                 = {"sharper_tools": 2}
	GS.inventory                = {"energy_drink": 3}
	GS.artifacts                = {"veteran_foreman": 1}
	GS.location_unlock_progress = {"lumber_yard": 3}
	GS.blueprints               = {"bp_timber": {"level": 2, "fragments": 1}}
	GS.crew                     = [_old_bob(2)]
	GS.daily_missions = [{"id": "d_1_0", "type": "break_nodes", "mat": "", "target": 25,
		"progress": 5, "reward_cash": 0, "reward_gems": 1, "claimed": false}]
	GS.trade_show_state = {"event_index": 1, "expires_at": _now() + 86400.0,
		"task_progress": {"hrs_t2": 2}, "claimed_rewards": [1, 0, 0]}
	SM.save_game()
	SM.load_game()
	_expect_eq(GS.materials["timber"], 7, "materials")
	_expect_eq(GS.utility_counts["blast_cap"], 200, "utility_counts (shown on UTILS badges)")
	_expect_eq(GS.upgrades["sharper_tools"], 2, "upgrades")
	_expect_eq(GS.inventory["energy_drink"], 3, "inventory")
	_expect_eq(GS.artifacts["veteran_foreman"], 1, "artifacts")
	_expect_eq(GS.location_unlock_progress["lumber_yard"], 3, "location_unlock_progress")
	_expect_eq(GS.blueprints["bp_timber"]["level"], 2, "blueprint level")
	_expect_eq(GS.blueprints["bp_timber"]["fragments"], 1, "blueprint fragments")
	_expect_eq(GS.crew[0]["level"], 2, "crew level")
	_expect_eq(GS.daily_missions[0]["progress"], 5, "mission progress")
	_expect_eq(GS.daily_missions[0]["target"], 25, "mission target")
	_expect_eq(GS.trade_show_state["event_index"], 1, "trade show event index")
	_expect_eq(GS.trade_show_state["task_progress"]["hrs_t2"], 2, "trade show task progress")
	_expect_eq(GS.trade_show_state["claimed_rewards"], [1, 0, 0], "trade show claims")

# ── Gameplay bugs ───────────────────────────────────────────────────────────

func test_contract_panel_lists_portfolio() -> void:
	GS.portfolio = ["shed", "shed", "single_house"]
	_main._update_contract_panel()
	var rows := _live_children(_main._portfolio_list_box)
	_expect_eq(rows.size(), 2, "one row per building type")
	_expect(rows.size() > 0 and "Garden Shed" in rows[0].text and "×2" in rows[0].text,
		"first row reads 'Garden Shed ×2'")

func test_prestige_resets_extra_node_slots() -> void:
	GS.upgrades["extra_node_slot"] = 4
	GS.active_node_count = 5
	SM.prestige_reset(0)
	_expect_eq(GS.active_node_count, 1, "node count back to 1 with the upgrade")

func test_load_repairs_node_count_from_upgrade_level() -> void:
	# Saves made before the prestige fix can hold count 5 with the upgrade at level 2.
	GS.upgrades = {"extra_node_slot": 2}
	GS.active_node_count = 5
	for loc_id: String in GS.location_nodes:
		var nodes: Array = GS.location_nodes[loc_id]
		while nodes.size() < 5:
			nodes.append(nodes[0].duplicate())
	SM.save_game()
	SM.load_game()
	_expect_eq(GS.active_node_count, 3, "1 base node + 2 upgrade levels")
	_expect_eq(GS.location_nodes["lumber_yard"].size(), 3, "surplus nodes trimmed")

func test_prestige_keeps_trade_show_claims() -> void:
	GS.trade_show_state = {"event_index": 2, "expires_at": _now() + 86400.0,
		"task_progress": {"me_t1": 150}, "claimed_rewards": [1, 1, 1]}
	SM.prestige_reset(0)
	_main._ts_ensure_active()
	_expect_eq(GS.trade_show_state["claimed_rewards"], [1, 1, 1], "claimed rewards survive prestige")
	_expect_eq(GS.trade_show_state["event_index"], 2, "same event keeps running")

func test_every_mined_material_has_a_blueprint() -> void:
	for loc_id: String in BD.LOCATION_ORDER:
		var mat: String = BD.get_location(loc_id)["material"]
		_expect(not BPD.get_blueprint(BPD.mat_drop_id(mat)).is_empty(),
			"%s drops a blueprint that exists" % mat)

func test_material_blueprint_boosts_node_drops() -> void:
	GS.blueprints = {"bp_timber": {"level": 5, "fragments": 0}}
	GS.active_boosts = {"drop_bonus": {"mult": 1.0, "flat": 9, "expires_at": _now() + 600.0}}
	GS.active_location_id = "lumber_yard"
	GS.location_nodes["lumber_yard"] = [{"node_id": "sapling", "hp": 1.0, "max_hp": 10.0}]
	_main._break_node("lumber_yard", 0)
	# Sapling drops 1, Material Surge adds 9 → 10; blueprint Lv5 = +40% → 14.
	_expect_eq(int(GS.materials.get("timber", 0)), 14, "timber from one sapling")

func test_fractional_yield_bonus_pays_out_on_average() -> void:
	GS.blueprints = {"bp_timber": {"level": 5, "fragments": 0}}
	seed(1234)
	var total := 0
	for i in 2000:
		total += GS.roll_yield("timber", 1)
	var avg := total / 2000.0
	_expect(avg > 1.35 and avg < 1.45, "1 drop at +40%% averages ~1.4 (got %.3f)" % avg)

func test_refined_blueprint_boosts_crafting() -> void:
	GS.blueprints = {"bp_lumber": {"level": 5, "fragments": 0}}
	GS.materials = {"timber": 30}
	_main._on_craft_all("timber", "lumber", 3)
	_expect_eq(int(GS.materials.get("lumber", 0)), 14, "30 timber → 10 lumber, +40% → 14")

func test_offline_rate_includes_material_blueprint() -> void:
	GS.crew = [_old_bob(1)]
	var base: float = OPC._get_idle_rates().get("timber", 0.0)
	GS.blueprints = {"bp_timber": {"level": 5, "fragments": 0}}
	var boosted: float = OPC._get_idle_rates().get("timber", 0.0)
	_expect(base > 0.0 and is_equal_approx(boosted, base * 1.4),
		"offline timber rate ×1.4 (base %.4f, boosted %.4f)" % [base, boosted])

func test_experienced_crew_starts_higher() -> void:
	GS.artifacts = {"experienced_crew": 3}
	GS.cash = 1000
	_main._on_hire_pressed("old_bob")
	_expect_eq(int(GS.crew[0]["level"]) if not GS.crew.is_empty() else -1, 4,
		"Lv3 artifact → hired at level 4")

func test_inspection_fragments_granted_before_blueprints_unlock() -> void:
	GS.skyline = ["shed"]
	GS.current_building = {"tier_id": "shed", "stage_index": 0, "stage_progress": 0.0,
		"stage_started": false, "build_started_at": _now(), "gem_skips_used": 0}
	_main._check_inspections("shed")
	var entry: Dictionary = GS.blueprints.get("bp_shed", {})
	# Clean Build (5) + Fast Track (8) = 13 fragments: 3 → Lv1, 5 → Lv2, 5 left toward Lv3.
	_expect_eq(int(entry.get("level", 0)), 2, "shed blueprint level")
	_expect_eq(int(entry.get("fragments", 0)), 5, "fragments toward next level")

# ── Exported builds ─────────────────────────────────────────────────────────

## An exported PCK holds "frame.png.import" + the imported .ctex, but not the
## source "frame.png". Rebuild that layout under user:// and list it.
func test_anim_frames_load_without_source_pngs() -> void:
	var src   := "res://assets/sprites/ui/menu/chest/"
	var fixt  := TEST_DIR + "/anim/"
	DirAccess.make_dir_recursive_absolute(fixt)
	DirAccess.copy_absolute(src + "Metal Chest - frame  01.png.import", fixt + "b.png.import")
	DirAccess.copy_absolute(src + "Metal Chest - frame  00.png.import", fixt + "a.png.import")
	_write_text(fixt + "notes.txt", "not a frame")
	var frames: Array = _main._load_anim_frames(fixt)
	_expect_eq(frames.size(), 2, "frames found from .import files alone")
	if frames.size() == 2:
		_expect(frames[0].resource_path.ends_with("a.png"),
			"frames sorted by name (first is %s)" % frames[0].resource_path)
	for f in DirAccess.get_files_at(fixt):
		DirAccess.remove_absolute(fixt + f)
	DirAccess.remove_absolute(fixt)
