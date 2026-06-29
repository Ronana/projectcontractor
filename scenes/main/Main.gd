extends Node2D
## Gameplay redesign: MINE screen as default, MENU+SHOP navigation.
##
## Screen layout (720×1280 portrait):
##   [   0 – 110 ] HUD + XP bar        (CanvasLayer 10)
##   [ 110 – 190 ] Location bar        (Node2D — always visible)
##   [ 190 – 1180] Mine area           (Node2D — always visible)
##   [1180 – 1280] Bottom bar          (CanvasLayer 50 — always on top)
##
## Overlay panels  (CanvasLayer 20):  Build, Craft, Crew, Skyline, Shop
## Wall panel      (CanvasLayer 25)
## Menu modal      (CanvasLayer 30)
## Splash          (CanvasLayer 40)

# ── Constants ──────────────────────────────────────────────────────────────
const SCREEN_W     := 720
const SCREEN_H     := 1280
const HUD_H        := 110
const BOTTOM_BAR_H := 100
const LOC_BAR_H    := 76
const MINE_Y       := HUD_H + LOC_BAR_H   # 186
const MINE_H       := SCREEN_H - MINE_Y - BOTTOM_BAR_H  # 994

const _HOUSE_SHEET_PATH := "res://assets/imported/ModernHouseA.png"
const _CELL_W           := 281
const _CELL_H           := 384
const _LOGO_W           := 200

## All available quick-bar shortcuts. Order = display order in pin panel.
const SHORTCUT_DEFS: Array = [
	{"id": "build",    "label": "BUILD",    "symbol": "B"},
	{"id": "crew",     "label": "CREW",     "symbol": "C"},
	{"id": "craft",    "label": "CRAFT",    "symbol": "W"},
	{"id": "sell",     "label": "SELL",     "symbol": "$"},
	{"id": "skyline",  "label": "SKYLINE",  "symbol": "S"},
	{"id": "upgrades", "label": "UPGRADES", "symbol": "+"},
	{"id": "contract", "label": "CONTRACT", "symbol": "R"},
	{"id": "shop",     "label": "SHOP",     "symbol": "◆"},
	{"id": "missions", "label": "MISSIONS", "symbol": "M"},
	{"id": "toolbox",  "label": "TOOLBOX",  "symbol": "T"},
]

# ── Colour palette ─────────────────────────────────────────────────────────
const C_BG       := Color(0.06, 0.07, 0.10)
const C_PANEL    := Color(0.09, 0.10, 0.15, 0.98)
const C_CARD     := Color(0.13, 0.14, 0.20)
const C_BORDER   := Color(0.20, 0.22, 0.32)
const C_GOLD     := Color(1.00, 0.78, 0.20)
const C_GEM      := Color(0.40, 0.85, 1.00)
const C_TIMBER     := Color(0.82, 0.57, 0.25)
const C_STONE      := Color(0.70, 0.70, 0.76)
const C_LUMBER     := Color(0.95, 0.72, 0.30)
const C_CONCRETE   := Color(0.55, 0.55, 0.62)
const C_SAND       := Color(0.88, 0.78, 0.45)
const C_STEEL_ORE  := Color(0.60, 0.65, 0.72)
const C_GLASS      := Color(0.55, 0.88, 0.95)
const C_STEEL_BEAM := Color(0.45, 0.52, 0.65)

const PANEL_TEX_PATH := "res://assets/sprites/ui/panel_grey_bolts_detail_a.svg"

## Sprite pools per material. Add an entry here when art is available.
## Each node picks a random sprite at a random scale on every spawn/respawn.
const NODE_SPRITES: Dictionary = {
	"timber": [
		"res://assets/sprites/materials/lumber_yard/tree_small_NE.png",
		"res://assets/sprites/materials/lumber_yard/tree_small_NW.png",
		"res://assets/sprites/materials/lumber_yard/tree_small_SE.png",
		"res://assets/sprites/materials/lumber_yard/tree_small_SW.png",
		"res://assets/sprites/materials/lumber_yard/tree_tall_NE.png",
		"res://assets/sprites/materials/lumber_yard/tree_tall_NW.png",
		"res://assets/sprites/materials/lumber_yard/tree_tall_SE.png",
		"res://assets/sprites/materials/lumber_yard/tree_tall_SW.png",
		"res://assets/sprites/materials/lumber_yard/tree_thin_NE.png",
		"res://assets/sprites/materials/lumber_yard/tree_thin_NW.png",
		"res://assets/sprites/materials/lumber_yard/tree_thin_SE.png",
		"res://assets/sprites/materials/lumber_yard/tree_thin_SW.png",
	],
	"stone": [
		"res://assets/sprites/materials/stone_quarry/stone_largeF_NE.png",
		"res://assets/sprites/materials/stone_quarry/stone_largeF_NW.png",
		"res://assets/sprites/materials/stone_quarry/stone_largeF_SE.png",
		"res://assets/sprites/materials/stone_quarry/stone_largeF_SW.png",
		"res://assets/sprites/materials/stone_quarry/stone_smallE_NE.png",
		"res://assets/sprites/materials/stone_quarry/stone_smallE_NW.png",
		"res://assets/sprites/materials/stone_quarry/stone_smallE_SE.png",
		"res://assets/sprites/materials/stone_quarry/stone_smallE_SW.png",
		"res://assets/sprites/materials/stone_quarry/stone_tallE_NE.png",
		"res://assets/sprites/materials/stone_quarry/stone_tallE_NW.png",
		"res://assets/sprites/materials/stone_quarry/stone_tallE_SE.png",
		"res://assets/sprites/materials/stone_quarry/stone_tallE_SW.png",
	],
	# Add other materials here as sprites become available:
	# "sand":      [ "res://assets/sprites/materials/sand_pit/..." ],
	# "steel_ore": [ "res://assets/sprites/materials/steel_yard/..." ],
	# "sand":      [ "res://assets/sprites/materials/sand_pit/..." ],
	# "steel_ore": [ "res://assets/sprites/materials/steel_yard/..." ],
}
const C_CLAY       := Color(0.80, 0.48, 0.28)
const C_COPPER_ORE := Color(0.72, 0.45, 0.20)
const C_LIMESTONE  := Color(0.85, 0.82, 0.70)
const C_BAUXITE    := Color(0.75, 0.38, 0.22)
const C_BRICK      := Color(0.72, 0.28, 0.18)
const C_COPPER_PIPE := Color(0.82, 0.58, 0.22)
const C_PLASTER    := Color(0.88, 0.86, 0.76)
const C_ALUMINIUM  := Color(0.76, 0.80, 0.88)
const C_GREEN    := Color(0.25, 0.80, 0.42)
const C_RED      := Color(0.85, 0.28, 0.28)
const C_ACCENT   := Color(0.28, 0.62, 1.00)
const C_TEXT     := Color(0.92, 0.92, 0.96)
const C_DIM      := Color(0.50, 0.52, 0.60)
const C_XP       := Color(0.70, 0.35, 1.00)

# ── HUD refs ───────────────────────────────────────────────────────────────
var _lbl_cash:       Label
var _lbl_gems:       Label
var _lbl_level:      Label
var _lbl_active_mat: Label    # 4th chip: active-material count
var _lbl_xp:         Label    # XP bar overlay label (shows live numbers)
var _xp_bar_fill:    ColorRect

# ── Mine screen refs ───────────────────────────────────────────────────────
var _lbl_active_loc:   Label            # active location name in the bar
var _loc_bar_accent:   ColorRect        # coloured underline strip
var _loc_picker_panel: CanvasLayer      # vertical location picker overlay
const MAX_NODES := 5                # visual pool; active count driven by GameState.active_node_count
var _node_visuals: Array = []       # Array[Dictionary] – one slot per possible node
var _lbl_mat_count:    Label
var _lbl_mine_rate:    Label
var _lbl_feedback:     Label
var _feedback_tween:   Tween
var _mine_backdrop:        TextureRect
var _last_backdrop_loc:    String = ""

# ── Build panel refs ───────────────────────────────────────────────────────
var _build_panel:       CanvasLayer
var _building_sprite:   Sprite2D
var _house_sheet_tex:   Texture2D
var _lbl_build_stage:   Label
var _build_reqs_box:    VBoxContainer
var _build_prog_bg:     ColorRect
var _build_prog_fill:   ColorRect
var _lbl_build_pct:     Label
var _btn_start_stage:   Button
var _lbl_cant_start:    Label
var _btn_tap_build:     Button
var _lbl_build_bp:      Label
var _lbl_build_feedback:Label

# ── Menu overlay refs ──────────────────────────────────────────────────────
var _menu_overlay: CanvasLayer

# ── Quick bar (bottom bar) refs ────────────────────────────────────────────
var _bottom_bar_cl:    CanvasLayer
var _pin_slot_nodes:   Array[Node]      = []   # rebuilt whenever pins change
var _pin_panel:        CanvasLayer             # pin-customiser overlay
var _pin_card_borders: Array[ColorRect] = []   # one per SHORTCUT_DEFS entry
var _pin_state_labels: Array[Label]     = []   # "✓ PINNED" labels

# ── Crew panel refs ────────────────────────────────────────────────────────
var _crew_panel:          CanvasLayer
var _lbl_crew_bp:         Label
var _crew_hire_btns:      Array[Button]    = []
var _crew_levelup_btns:   Array[Button]    = []
var _crew_level_labels:   Array[Label]     = []
var _crew_rate_labels:    Array[Label]     = []
var _crew_progress_fills: Array[ColorRect] = []
var _crew_scroll_content:  Control
var _crew_loc_labels:      Array[Label]  = []   # current location per card
var _crew_move_btns:       Array[Button] = []   # "▶ MOVE" per card
var _crew_loc_picker:      CanvasLayer           # location-reassign overlay
var _crew_loc_picker_for:  String = ""           # crew id being reassigned

# ── Craft panel refs ───────────────────────────────────────────────────────
var _craft_panel:      CanvasLayer
var _craft_inv_lbls:   Array[Label]  = []
var _craft_yield_lbls: Array[Label]  = []
var _craft1_btns:      Array[Button] = []
var _craftall_btns:    Array[Button] = []

# ── Wall panel refs ────────────────────────────────────────────────────────
var _wall_panel:      CanvasLayer
var _lbl_wall_title:  Label
var _lbl_wall_detail: Label

# ── Skyline panel refs ─────────────────────────────────────────────────────
var _skyline_panel:    CanvasLayer
var _skyline_list_box: VBoxContainer

# ── Upgrades panel refs ────────────────────────────────────────────────────
var _upgrades_panel:     CanvasLayer
var _upgrade_cards:      Array[Dictionary] = []  # {bg, bar, name_lbl, desc_lbl, level_lbl, cost_lbl, btn}

# ── Sell panel refs ────────────────────────────────────────────────────────
var _sell_panel:       CanvasLayer
var _sell_inv_lbls:    Array[Label]  = []   # current qty per material
var _sell_earn_lbls:   Array[Label]  = []   # "= X cash" preview

# ── Contract panel refs ────────────────────────────────────────────────────
var _contract_panel:       CanvasLayer
var _lbl_contract_rep:     Label
var _artifact_cards:       Array[Dictionary] = []  # {id, outer, name_lbl, level_lbl, cost_lbl, btn}
var _portfolio_list_box:   VBoxContainer

# ── Prestige confirm panel refs ────────────────────────────────────────────
var _prestige_confirm_panel:  CanvasLayer
var _lbl_prestige_rep_earned: Label
var _lbl_prestige_new_rep:    Label

# ── Skyline panel "New Contract" footer refs ────────────────────────────────
var _btn_new_contract:          Button
var _lbl_new_contract_locked:   Label

# ── Shop panel refs ────────────────────────────────────────────────────────
var _shop_panel:     CanvasLayer
var _lbl_shop_gems:  Label
var _btn_stage_skip: Button

# ── Runtime accumulators ───────────────────────────────────────────────────
# Per-location worker HP-damage accumulator (smooth sub-integer ticking)
var _worker_dmg_accum: Dictionary = {}

# ── Offline popup refs ─────────────────────────────────────────────────────
var _offline_popup:    CanvasLayer
var _offline_rows_box: VBoxContainer
var _lbl_offline_time: Label

# ── Toolbox panel refs ──────────────────────────────────────────────────────
var _toolbox_panel:         CanvasLayer
var _toolbox_cells:         Array = []   # [{bg, border, symbol_lbl, name_lbl, count_badge, item_id}]
var _toolbox_selected:      String = ""
var _lbl_tb_item_name:      Label
var _lbl_tb_item_desc:      Label
var _lbl_tb_item_count:     Label
var _btn_tb_use:            Button
var _btn_tb_buy:            Button
var _toolbox_float_cl:      CanvasLayer   # persistent floating button on mine screen
var _boost_strip:           CanvasLayer   # thin strip showing active boost timers
var _boost_chip_box:        HBoxContainer
var _boost_strip_timer:     float = 0.0

# ── Missions panel refs ─────────────────────────────────────────────────────
var _missions_panel:      CanvasLayer
var _mission_card_refs:   Array = []   # [{prog_bar, prog_lbl, claim_btn, mission_id}]
var _lbl_daily_countdown: Label
var _lbl_weekly_countdown: Label

# ══════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_splash()
	_build_backdrop()
	_build_hud()
	_build_location_bar()
	_build_loc_picker_panel()
	_build_mine_area()
	_build_bottom_bar()
	_build_pin_panel()
	_build_menu_overlay()
	_build_build_panel()
	_build_crew_panel()
	_build_craft_panel()
	_build_wall_panel()
	_build_skyline_panel()
	_build_upgrades_panel()
	_build_sell_panel()
	_build_contract_panel()
	_build_prestige_confirm_panel()
	_build_shop_panel()
	_build_offline_popup()
	_build_missions_panel()
	MissionManager.missions_changed.connect(_update_missions_panel)
	_build_toolbox_panel()
	_build_toolbox_float_btn()
	_build_boost_strip()
	_update_display()
	_check_offline_summary()
	_apply_global_font()

func _apply_global_font() -> void:
	var bold := load("res://assets/fonts/Rajdhani-Bold.ttf")     as FontFile
	var semi := load("res://assets/fonts/Rajdhani-SemiBold.ttf") as FontFile
	if not bold or not semi:
		push_warning("Rajdhani fonts not found — using default font")
		return
	for lbl: Label  in find_children("*", "Label",  true, false):
		lbl.add_theme_font_override("font", bold)
	for btn: Button in find_children("*", "Button", true, false):
		btn.add_theme_font_override("font", semi)

var _mission_countdown_timer: float = 0.0

func _process(delta: float) -> void:
	_tick_workers(delta)
	# Refresh active boost strip every second
	_boost_strip_timer += delta
	if _boost_strip_timer >= 1.0:
		_boost_strip_timer = 0.0
		_update_boost_strip()

	# Refresh mission countdown labels every second while panel is open
	if _missions_panel and _missions_panel.visible:
		_mission_countdown_timer += delta
		if _mission_countdown_timer >= 1.0:
			_mission_countdown_timer = 0.0
			if _lbl_daily_countdown:
				_lbl_daily_countdown.text = "Resets in %s" % MissionManager.time_until_string(GameState.daily_reset_at)
			if _lbl_weekly_countdown:
				_lbl_weekly_countdown.text = "Resets in %s" % MissionManager.time_until_string(GameState.weekly_reset_at)

# ══════════════════════════════════════════════════════════════════════════
# Scene construction
# ══════════════════════════════════════════════════════════════════════════

# ── Splash ─────────────────────────────────────────────────────────────────
func _build_splash() -> void:
	var cl      := CanvasLayer.new()
	cl.name      = "Splash"
	cl.layer     = 40
	add_child(cl)

	var bg      := ColorRect.new()
	bg.color     = Color(0.04, 0.06, 0.14)
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H)
	cl.add_child(bg)

	var logo_tex := load("res://assets/imported/MainLogoWText.png") as Texture2D
	if logo_tex:
		var logo          := Sprite2D.new()
		logo.texture       = logo_tex
		var scale_f        := float(SCREEN_W - 40) / float(logo_tex.get_width())
		logo.scale         = Vector2(scale_f, scale_f)
		logo.position      = Vector2(SCREEN_W / 2.0, SCREEN_H / 2.0)
		cl.add_child(logo)

	var skip_btn     := Button.new()
	skip_btn.flat     = true
	skip_btn.position = Vector2.ZERO
	skip_btn.size     = Vector2(SCREEN_W, SCREEN_H)
	skip_btn.pressed.connect(cl.queue_free)
	cl.add_child(skip_btn)

	var timer          := Timer.new()
	timer.wait_time     = 2.5
	timer.one_shot      = true
	timer.autostart     = true
	timer.timeout.connect(cl.queue_free)
	cl.add_child(timer)

# ── HUD ────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	var cl  := CanvasLayer.new()
	cl.name  = "HUD"
	cl.layer = 10
	add_child(cl)

	var bg      := ColorRect.new()
	bg.color     = Color(0.07, 0.08, 0.12, 0.72)
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, HUD_H)
	cl.add_child(bg)

	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.position  = Vector2(0, HUD_H - 2)
	sep.size      = Vector2(SCREEN_W, 2)
	cl.add_child(sep)

	# Banner logo (left side)
	var banner_tex := load("res://assets/imported/BannerLogo.png") as Texture2D
	if banner_tex:
		var logo         := TextureRect.new()
		logo.texture      = banner_tex
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.position     = Vector2(8, 0)
		logo.size         = Vector2(_LOGO_W, HUD_H - 26)
		cl.add_child(logo)

	# Stat chips: Cash | Gems | Level | Active-Mat  (right of logo)
	var chip_w := float(SCREEN_W - _LOGO_W) / 4.0
	_lbl_cash       = _hud_chip(cl, "$ 0",      C_GOLD,   _LOGO_W + chip_w * 0, chip_w)
	_lbl_gems       = _hud_chip(cl, "◆ 0",      C_GEM,    _LOGO_W + chip_w * 1, chip_w)
	_lbl_level      = _hud_chip(cl, "Lv.1",     C_ACCENT, _LOGO_W + chip_w * 2, chip_w)
	_lbl_active_mat = _hud_chip(cl, "0\nTimber", C_TIMBER, _LOGO_W + chip_w * 3, chip_w)

	# Subtle vertical dividers between the 4 chips
	for i in 3:
		var div      := ColorRect.new()
		div.color     = Color(0.30, 0.32, 0.45, 0.4)
		div.position  = Vector2(_LOGO_W + chip_w * (i + 1), 14)
		div.size      = Vector2(1, HUD_H - 46)
		cl.add_child(div)

	# XP bar strip along the bottom of the HUD
	var xp_bg      := ColorRect.new()
	xp_bg.color     = Color(0.10, 0.06, 0.18)
	xp_bg.position  = Vector2(0, HUD_H - 22)
	xp_bg.size      = Vector2(SCREEN_W, 20)
	cl.add_child(xp_bg)

	_xp_bar_fill         = ColorRect.new()
	_xp_bar_fill.color   = C_XP
	_xp_bar_fill.position = Vector2(0, HUD_H - 22)
	_xp_bar_fill.size     = Vector2(0, 20)
	cl.add_child(_xp_bar_fill)

	_lbl_xp          = Label.new()
	_lbl_xp.name     = "XpLabel"
	_lbl_xp.text     = "XP"
	_lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_xp.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_xp.position = Vector2(0, HUD_H - 22)
	_lbl_xp.size     = Vector2(SCREEN_W, 20)
	_lbl_xp.add_theme_font_size_override("font_size", 11)
	_lbl_xp.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	cl.add_child(_lbl_xp)

func _hud_chip(parent: CanvasLayer, text: String, color: Color, x: float, w: float) -> Label:
	# Thin coloured accent line at bottom of chip area
	var accent      := ColorRect.new()
	accent.color     = color
	accent.position  = Vector2(x + 6, HUD_H - 28)
	accent.size      = Vector2(w - 12, 3)
	parent.add_child(accent)

	var lbl := Label.new()
	lbl.text                 = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.position             = Vector2(x, 0)
	lbl.size                 = Vector2(w, HUD_H - 26)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

## Applies a coloured StyleBoxFlat to a button for all interaction states.
## Call once after creating any action button instead of add_theme_color_override.
func _apply_btn_style(btn: Button, bg: Color, fg: Color = Color.WHITE, radius: int = 6) -> void:
	btn.add_theme_color_override("font_color", fg)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := StyleBoxFlat.new()
		match state:
			"normal":   s.bg_color = bg
			"hover":    s.bg_color = bg.lightened(0.12)
			"pressed":  s.bg_color = bg.darkened(0.18)
			"disabled": s.bg_color = Color(bg.r, bg.g, bg.b, 0.28)
			"focus":    s.bg_color = bg.lightened(0.06)
		s.corner_radius_top_left     = radius
		s.corner_radius_top_right    = radius
		s.corner_radius_bottom_left  = radius
		s.corner_radius_bottom_right = radius
		btn.add_theme_stylebox_override(state, s)

## Builds a standard panel header: coloured top strip, dark bg, bottom separator,
## centred title, styled close button. Returns the close button for signal connection.
func _build_panel_header(parent: Node, title_text: String, accent: Color) -> Button:
	# Full-panel bolt-texture background overlay
	var _pt := load(PANEL_TEX_PATH) as Texture2D
	if _pt:
		var np := NinePatchRect.new()
		np.texture             = _pt
		np.position            = Vector2.ZERO
		np.size                = Vector2(SCREEN_W, SCREEN_H)
		np.patch_margin_left   = 16
		np.patch_margin_right  = 16
		np.patch_margin_top    = 16
		np.patch_margin_bottom = 16
		np.modulate            = Color(0.65, 0.70, 0.78, 0.14)
		parent.add_child(np)
	# Dark header background
	var header      := ColorRect.new()
	header.color     = Color(0.07, 0.08, 0.13)
	header.position  = Vector2.ZERO
	header.size      = Vector2(SCREEN_W, 78)
	parent.add_child(header)

	# Coloured top strip
	var top_strip      := ColorRect.new()
	top_strip.color     = accent
	top_strip.position  = Vector2.ZERO
	top_strip.size      = Vector2(SCREEN_W, 4)
	parent.add_child(top_strip)

	# Bottom separator (slightly dimmed accent)
	var sep      := ColorRect.new()
	sep.color     = accent.darkened(0.25)
	sep.position  = Vector2(0, 76)
	sep.size      = Vector2(SCREEN_W, 2)
	parent.add_child(sep)

	# Title label
	var title      := Label.new()
	title.text      = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title.position  = Vector2(60, 4)
	title.size      = Vector2(SCREEN_W - 120, 72)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(title)

	# Close button
	var close_btn     := Button.new()
	close_btn.flat     = true
	close_btn.text     = "✕"
	close_btn.position = Vector2(SCREEN_W - 68, 12)
	close_btn.size     = Vector2(52, 52)
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.add_theme_color_override("font_color", Color(0.55, 0.57, 0.70))
	parent.add_child(close_btn)

	return close_btn

# ── Location selector bar ───────────────────────────────────────────────────
# ── Node visual helpers ──────────────────────────────────────────────────────

func _make_empty_node_vis() -> Dictionary:
	# Creates the persistent hp bar + label objects (not yet added to any container)
	var c       := Node2D.new()
	var hp_bg   := ColorRect.new()
	var hp_fill := ColorRect.new()
	var lbl     := Label.new()
	hp_bg.color     = Color(0.06, 0.06, 0.10)
	hp_bg.position  = Vector2(-48, 72)
	hp_bg.size      = Vector2(96, 10)
	hp_fill.color     = C_GREEN
	hp_fill.position  = Vector2(-48, 72)
	hp_fill.size      = Vector2(96, 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-56, 86)
	lbl.size     = Vector2(112, 22)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	return { "container": c, "parts": [], "sprite": null, "hp_bg": hp_bg,
			 "hp_fill": hp_fill, "lbl": lbl, "max_hp": 10.0,
			 "pos": Vector2(-1.0, -1.0) }

func _setup_node_vis(vis: Dictionary, mat: String, node_name: String,
		accent: Color, max_hp: float) -> void:
	var c: Node2D = vis["container"]
	# Free previous ColorRect shape parts
	for p: ColorRect in vis["parts"]:
		p.queue_free()
	vis["parts"].clear()
	# Free previous sprite if any
	if vis.get("sprite") != null:
		vis["sprite"].queue_free()
		vis["sprite"] = null
	# Remove hp overlay so visuals go beneath it
	if vis["hp_bg"].get_parent()   == c: c.remove_child(vis["hp_bg"])
	if vis["hp_fill"].get_parent() == c: c.remove_child(vis["hp_fill"])
	if vis["lbl"].get_parent()     == c: c.remove_child(vis["lbl"])
	# ── Sprite-based visual ──────────────────────────────────────────────────
	var sprite_paths: Array = NODE_SPRITES.get(mat, [])
	if not sprite_paths.is_empty():
		var path: String = sprite_paths[randi() % sprite_paths.size()]
		var tex := load(path) as Texture2D
		if tex:
			var sp       := Sprite2D.new()
			sp.texture    = tex
			sp.scale      = Vector2.ONE * randf_range(0.8, 1.3)
			c.add_child(sp)
			vis["sprite"] = sp
	# ── Fallback: themed ColorRect shapes ────────────────────────────────────
	else:
		var shapes := _node_shape_parts(mat, accent)
		for s in shapes: c.add_child(s)
		vis["parts"] = shapes
	# Re-add hp bar + label on top
	c.add_child(vis["hp_bg"])
	c.add_child(vis["hp_fill"])
	c.add_child(vis["lbl"])
	vis["max_hp"]   = max_hp

func _node_shape_parts(mat: String, accent: Color) -> Array:
	match mat:
		"timber":
			return [
				_cr(Vector2( -8,  14), Vector2(16, 46), accent.darkened(0.55)),  # trunk
				_cr(Vector2(-44, -20), Vector2(88, 36), accent.darkened(0.22)),  # base canopy
				_cr(Vector2(-30, -52), Vector2(60, 34), accent),                 # mid canopy
				_cr(Vector2(-18, -82), Vector2(36, 32), accent.lightened(0.15)), # top canopy
			]
		"stone":
			return [
				_cr(Vector2(-46,  -2), Vector2(54, 48), Color(0.38, 0.38, 0.41)),
				_cr(Vector2( -6,   0), Vector2(50, 44), Color(0.48, 0.48, 0.51)),
				_cr(Vector2(-26, -50), Vector2(54, 52), Color(0.45, 0.45, 0.48)),
			]
		"sand":
			return [
				_cr(Vector2(-50,  10), Vector2(100, 18), accent.darkened(0.28)),
				_cr(Vector2(-36, -14), Vector2( 72, 26), accent),
				_cr(Vector2(-22, -40), Vector2( 44, 28), accent.lightened(0.10)),
				_cr(Vector2(-12, -62), Vector2( 24, 24), accent.lightened(0.22)),
			]
		"steel_ore":
			return [
				_cr(Vector2(-44,   4), Vector2(88, 16), accent.darkened(0.30)),  # base
				_cr(Vector2(-34, -72), Vector2(18, 78), accent),                 # left pillar
				_cr(Vector2( 16, -72), Vector2(18, 78), accent),                 # right pillar
				_cr(Vector2(-34, -40), Vector2(68, 12), accent.lightened(0.12)), # crossbeam
				_cr(Vector2(-20, -92), Vector2(40, 22), accent.darkened(0.12)),  # cap
			]
		_:
			return [_cr(Vector2(-38, -50), Vector2(76, 72), accent)]

## Shorthand ColorRect factory used by _node_shape_parts.
func _cr(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size     = sz
	r.color    = col
	return r

func _random_mine_pos(slot_idx: int, total: int) -> Vector2:
	var x_min := 80.0
	var x_max := 640.0
	var y_min := float(MINE_Y) + 100.0
	var y_max := float(MINE_Y + MINE_H) - 200.0
	var cols  := clampi(total, 1, 3)
	var rows  := ceili(float(total) / float(cols))
	var col   := slot_idx % cols
	var row   := slot_idx / cols
	var cw    := (x_max - x_min) / float(cols)
	var ch    := (y_max - y_min) / float(rows)
	var cx    := x_min + cw * (float(col) + 0.5) + randf_range(-cw * 0.22, cw * 0.22)
	var cy    := y_min + ch * (float(row) + 0.5) + randf_range(-ch * 0.22, ch * 0.22)
	return Vector2(cx, cy)

func _refresh_mine_visuals(loc_id: String) -> void:
	var loc_data := BuildDatabase.get_location(loc_id)
	var mat: String  = loc_data.get("material", "timber")
	var accent       := _mat_color(mat)
	var nodes: Array = GameState.location_nodes.get(loc_id, [])
	var count        := nodes.size()
	for i in MAX_NODES:
		var vis: Dictionary = _node_visuals[i]
		if i < count:
			var nd: Dictionary  = nodes[i]
			var node_id: String = nd.get("node_id", "")
			# Cleared slot — hide until wave respawn
			if node_id == "":
				vis["container"].visible = false
				continue
			var node_data         := BuildDatabase.get_node_data(node_id)
			var base_hp: float    = float(node_data.get("hp", 10)) if not node_data.is_empty() else 10.0
			var max_hp: float     = float(nd.get("max_hp", base_hp))
			var node_name: String = node_data.get("name", node_id) if not node_data.is_empty() else node_id
			_setup_node_vis(vis, mat, node_name, accent, max_hp)
			# Assign position: reuse stored pos or generate a new one
			var p: Vector2 = vis.get("pos", Vector2(-1.0, -1.0))
			if p.x < 0.0:
				p = _random_mine_pos(i, count)
				vis["pos"] = p
			vis["container"].position = p
			_update_mine_hp_bar(vis, float(nd.get("hp", max_hp)), max_hp)
			vis["container"].visible = true
		else:
			vis["container"].visible = false

func _update_mine_hps(loc_id: String) -> void:
	var nodes: Array = GameState.location_nodes.get(loc_id, [])
	for i in mini(nodes.size(), MAX_NODES):
		var nd: Dictionary  = nodes[i]
		var node_id: String = nd.get("node_id", "")
		if node_id == "": continue   # cleared slot — bar already hidden
		var node_data := BuildDatabase.get_node_data(node_id)
		var base_hp: float = float(node_data.get("hp", 10)) if not node_data.is_empty() else 10.0
		var max_hp: float  = float(nd.get("max_hp", base_hp))
		_update_mine_hp_bar(_node_visuals[i], float(nd.get("hp", max_hp)), max_hp)

func _update_mine_hp_bar(vis: Dictionary, hp: float, max_hp: float) -> void:
	var pct: float = minf(hp / max_hp, 1.0)
	vis["hp_fill"].size.x = 96.0 * pct
	vis["hp_fill"].color  = C_GREEN if pct > 0.6 else (C_GOLD if pct > 0.3 else C_RED)
	vis["lbl"].text       = "%d" % int(hp)

func _flash_node_hit(slot_idx: int) -> void:
	if slot_idx >= _node_visuals.size(): return
	var c: Node2D = _node_visuals[slot_idx]["container"]
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.12, 1.12), 0.12)
	tw.tween_property(c, "scale", Vector2(1.0,  1.0),  0.22)

func _build_location_bar() -> void:
	var bg      := ColorRect.new()
	bg.color     = Color(0.07, 0.08, 0.13, 0.72)
	bg.position  = Vector2(0, HUD_H)
	bg.size      = Vector2(SCREEN_W, LOC_BAR_H)
	add_child(bg)

	# Accent underline (colour changes with active location)
	_loc_bar_accent         = ColorRect.new()
	_loc_bar_accent.color   = C_TIMBER
	_loc_bar_accent.position = Vector2(0, HUD_H + LOC_BAR_H - 4)
	_loc_bar_accent.size    = Vector2(SCREEN_W, 4)
	add_child(_loc_bar_accent)

	# Active location label
	_lbl_active_loc = Label.new()
	_lbl_active_loc.text = "Lumber Yard"
	_lbl_active_loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_active_loc.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_active_loc.position = Vector2(0, HUD_H)
	_lbl_active_loc.size     = Vector2(SCREEN_W - 80, LOC_BAR_H)
	_lbl_active_loc.add_theme_font_size_override("font_size", 18)
	_lbl_active_loc.add_theme_color_override("font_color", C_TEXT)
	add_child(_lbl_active_loc)

	# Chevron button (right side)
	var chevron      := Button.new()
	chevron.text      = "▼"
	chevron.flat      = true
	chevron.position  = Vector2(SCREEN_W - 72, HUD_H + 4)
	chevron.size      = Vector2(64, LOC_BAR_H - 8)
	chevron.add_theme_font_size_override("font_size", 20)
	chevron.add_theme_color_override("font_color", C_DIM)
	chevron.pressed.connect(_on_loc_picker_open)
	add_child(chevron)

	# Tap the whole bar to open picker too
	var bar_btn      := Button.new()
	bar_btn.flat      = true
	bar_btn.position  = Vector2(0, HUD_H)
	bar_btn.size      = Vector2(SCREEN_W - 72, LOC_BAR_H)
	bar_btn.pressed.connect(_on_loc_picker_open)
	add_child(bar_btn)

func _build_loc_picker_panel() -> void:
	_loc_picker_panel        = CanvasLayer.new()
	_loc_picker_panel.layer  = 22
	_loc_picker_panel.visible = false
	add_child(_loc_picker_panel)

	# Dim backdrop
	var dim      := ColorRect.new()
	dim.color     = Color(0, 0, 0, 0.6)
	dim.position  = Vector2.ZERO
	dim.size      = Vector2(SCREEN_W, SCREEN_H)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_loc_picker_panel.visible = false)
	_loc_picker_panel.add_child(dim)

	# Panel card
	var card_w := 660
	var card_h := 900
	var card_x := (SCREEN_W - card_w) / 2.0
	var card_y := (SCREEN_H - card_h) / 2.0

	var card      := ColorRect.new()
	card.color     = C_PANEL
	card.position  = Vector2(card_x, card_y)
	card.size      = Vector2(card_w, card_h)
	_loc_picker_panel.add_child(card)

	var top_bar      := ColorRect.new()
	top_bar.color     = C_ACCENT
	top_bar.position  = Vector2(card_x, card_y)
	top_bar.size      = Vector2(card_w, 4)
	_loc_picker_panel.add_child(top_bar)

	var title      := Label.new()
	title.text      = "SELECT LOCATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position  = Vector2(card_x, card_y + 10)
	title.size      = Vector2(card_w, 44)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT)
	_loc_picker_panel.add_child(title)

	var close_btn      := Button.new()
	close_btn.text      = "✕"
	close_btn.flat      = true
	close_btn.position  = Vector2(card_x + card_w - 52, card_y + 8)
	close_btn.size      = Vector2(44, 36)
	close_btn.add_theme_color_override("font_color", C_DIM)
	close_btn.pressed.connect(func(): _loc_picker_panel.visible = false)
	_loc_picker_panel.add_child(close_btn)

	# Scroll area for location cards
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(card_x + 12, card_y + 60)
	scroll.size      = Vector2(card_w - 24, card_h - 72)
	_loc_picker_panel.add_child(scroll)

	var vbox      := VBoxContainer.new()
	vbox.size      = Vector2(card_w - 24, 0)
	scroll.add_child(vbox)

	for loc_id: String in BuildDatabase.LOCATION_ORDER:
		var loc_data := BuildDatabase.get_location(loc_id)
		var dname: String = loc_data.get("display_name", loc_id)
		var mat: String   = loc_data.get("material", "timber")
		var accent        := _mat_color(mat)

		var row      := Button.new()
		row.flat      = true
		row.custom_minimum_size = Vector2(card_w - 24, 100)
		row.pressed.connect(_on_location_btn.bind(loc_id))
		vbox.add_child(row)

		# Coloured left strip
		var strip      := ColorRect.new()
		strip.color     = accent
		strip.position  = Vector2(0, 8)
		strip.size      = Vector2(6, 84)
		row.add_child(strip)

		# Location name
		var name_lbl      := Label.new()
		name_lbl.text      = dname
		name_lbl.position  = Vector2(20, 16)
		name_lbl.size      = Vector2(card_w - 80, 36)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(name_lbl)

		# Material type label
		var mat_lbl      := Label.new()
		mat_lbl.text      = mat.capitalize()
		mat_lbl.position  = Vector2(20, 54)
		mat_lbl.size      = Vector2(card_w - 80, 28)
		mat_lbl.add_theme_font_size_override("font_size", 14)
		mat_lbl.add_theme_color_override("font_color", accent)
		row.add_child(mat_lbl)

		# Separator
		var sep      := ColorRect.new()
		sep.color     = C_BORDER
		sep.custom_minimum_size = Vector2(card_w - 24, 2)
		vbox.add_child(sep)

func _on_loc_picker_open() -> void:
	_loc_picker_panel.visible = true

# ── Mine area ───────────────────────────────────────────────────────────────
## Backdrop texture paths per location. Add entries as art is ready.
const BACKDROP_PATHS: Dictionary = {
	"lumber_yard":      "res://assets/imported/bg_lumber_yard.png",
	"stone_quarry":     "res://assets/imported/bg_stone_quarry.png",
	"sand_pit":         "res://assets/imported/bg_sand_pit.png",
	"steel_yard":       "res://assets/imported/bg_steel_yard.png",
	# "clay_pit":       "res://assets/imported/bg_clay_pit.png",
	# "copper_mine":    "res://assets/imported/bg_copper_mine.png",
	# "limestone_quarry": "res://assets/imported/bg_limestone_quarry.png",
	# "bauxite_mine":   "res://assets/imported/bg_bauxite_mine.png",
}

## Full-screen backdrop on a negative CanvasLayer so it sits behind
## ALL Node2D children (location bar, mine area) and all positive layers.
func _build_backdrop() -> void:
	var cl      := CanvasLayer.new()
	cl.layer     = -1
	add_child(cl)

	_mine_backdrop              = TextureRect.new()
	_mine_backdrop.position     = Vector2.ZERO
	_mine_backdrop.size         = Vector2(SCREEN_W, SCREEN_H)
	_mine_backdrop.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_mine_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	cl.add_child(_mine_backdrop)

func _build_mine_area() -> void:
	# Dim overlay over backdrop
	var overlay      := ColorRect.new()
	overlay.color     = Color(0.0, 0.0, 0.0, 0.28)
	overlay.position  = Vector2(0, MINE_Y)
	overlay.size      = Vector2(SCREEN_W, MINE_H)
	add_child(overlay)

	# Node visual pool — MAX_NODES containers, shown/hidden by active_node_count
	for _i in MAX_NODES:
		var vis := _make_empty_node_vis()
		vis["container"].visible = false
		add_child(vis["container"])
		_node_visuals.append(vis)

	# Info strip pinned to bottom of mine area
	_lbl_mat_count                      = Label.new()
	_lbl_mat_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mat_count.position             = Vector2(0, MINE_Y + MINE_H - 80)
	_lbl_mat_count.size                 = Vector2(SCREEN_W, 34)
	_lbl_mat_count.add_theme_font_size_override("font_size", 18)
	add_child(_lbl_mat_count)

	_lbl_mine_rate                      = Label.new()
	_lbl_mine_rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mine_rate.position             = Vector2(0, MINE_Y + MINE_H - 44)
	_lbl_mine_rate.size                 = Vector2(SCREEN_W, 30)
	_lbl_mine_rate.add_theme_font_size_override("font_size", 13)
	_lbl_mine_rate.add_theme_color_override("font_color", C_DIM)
	add_child(_lbl_mine_rate)

	# Floating feedback label
	_lbl_feedback                      = Label.new()
	_lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_feedback.position             = Vector2(0, MINE_Y + 30)
	_lbl_feedback.size                 = Vector2(SCREEN_W, 44)
	_lbl_feedback.modulate.a           = 0.0
	_lbl_feedback.add_theme_font_size_override("font_size", 16)
	_lbl_feedback.add_theme_color_override("font_color", C_GOLD)
	add_child(_lbl_feedback)

	# Full-area tap button (sits over everything in the mine zone)
	var tap_btn      := Button.new()
	tap_btn.flat      = true
	tap_btn.position  = Vector2(0, MINE_Y)
	tap_btn.size      = Vector2(SCREEN_W, MINE_H)
	tap_btn.pressed.connect(_on_tap_node)
	add_child(tap_btn)

# ── Bottom bar (4 pinnable slots + MORE) ───────────────────────────────────
func _build_bottom_bar() -> void:
	_bottom_bar_cl        = CanvasLayer.new()
	_bottom_bar_cl.name   = "BottomBar"
	_bottom_bar_cl.layer  = 50
	add_child(_bottom_bar_cl)

	var bar_y   := SCREEN_H - BOTTOM_BAR_H
	var slot_w  := SCREEN_W / 5   # 144 px per slot (5 slots total)

	# Background
	var bg      := ColorRect.new()
	bg.color     = Color(0.07, 0.08, 0.12, 0.88)
	bg.position  = Vector2(0, bar_y)
	bg.size      = Vector2(SCREEN_W, BOTTOM_BAR_H)
	_bottom_bar_cl.add_child(bg)

	# Top border line
	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.position  = Vector2(0, bar_y)
	sep.size      = Vector2(SCREEN_W, 2)
	_bottom_bar_cl.add_child(sep)

	# Slot dividers (between each slot)
	for i in 4:
		var div      := ColorRect.new()
		div.color     = Color(0.22, 0.24, 0.34, 0.6)
		div.position  = Vector2(slot_w * (i + 1), bar_y + 10)
		div.size      = Vector2(1, BOTTOM_BAR_H - 20)
		_bottom_bar_cl.add_child(div)

	# MORE button — always slot 4 (rightmost)
	var more_x     := slot_w * 4
	var icon_sz    := 36
	var more_icon_x := more_x + (slot_w - icon_sz) / 2.0

	var more_icon      := ColorRect.new()
	more_icon.color     = Color(0.18, 0.20, 0.28)
	more_icon.position  = Vector2(more_icon_x, bar_y + 20)
	more_icon.size      = Vector2(icon_sz, icon_sz)
	_bottom_bar_cl.add_child(more_icon)

	var more_sym      := Label.new()
	more_sym.text      = "≡"
	more_sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	more_sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	more_sym.position  = Vector2(more_icon_x, bar_y + 20)
	more_sym.size      = Vector2(icon_sz, icon_sz)
	more_sym.add_theme_font_size_override("font_size", 22)
	more_sym.add_theme_color_override("font_color", C_TEXT)
	_bottom_bar_cl.add_child(more_sym)

	var more_lbl      := Label.new()
	more_lbl.text      = "MORE"
	more_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	more_lbl.position  = Vector2(more_x, bar_y + 60)
	more_lbl.size      = Vector2(slot_w, 24)
	more_lbl.add_theme_font_size_override("font_size", 11)
	more_lbl.add_theme_color_override("font_color", C_DIM)
	_bottom_bar_cl.add_child(more_lbl)

	var more_btn      := Button.new()
	more_btn.flat      = true
	more_btn.position  = Vector2(more_x, bar_y)
	more_btn.size      = Vector2(slot_w, BOTTOM_BAR_H)
	more_btn.pressed.connect(_on_menu_btn_pressed)
	_bottom_bar_cl.add_child(more_btn)

	# Build the 4 pinnable slots from saved preferences
	_rebuild_pin_slots()


# Clears and rebuilds the 4 dynamic pin slots from GameState.pinned_shortcuts.
func _rebuild_pin_slots() -> void:
	for n: Node in _pin_slot_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_pin_slot_nodes.clear()

	var bar_y  := SCREEN_H - BOTTOM_BAR_H
	var slot_w := SCREEN_W / 5   # 144 px
	var icon_sz := 36

	var pins: Array = GameState.pinned_shortcuts
	for i in mini(pins.size(), 4):
		var id: String      = pins[i]
		var def: Dictionary = _shortcut_def(id)
		if def.is_empty():
			continue
		var x        := slot_w * i
		var icon_x   := x + (slot_w - icon_sz) / 2.0

		var icon      := ColorRect.new()
		icon.color     = _shortcut_color(id)
		icon.position  = Vector2(icon_x, bar_y + 20)
		icon.size      = Vector2(icon_sz, icon_sz)
		_bottom_bar_cl.add_child(icon)
		_pin_slot_nodes.append(icon)

		var sym      := Label.new()
		sym.text      = def["symbol"]
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		sym.position  = Vector2(icon_x, bar_y + 20)
		sym.size      = Vector2(icon_sz, icon_sz)
		sym.add_theme_font_size_override("font_size", 18)
		sym.add_theme_color_override("font_color", Color.WHITE)
		_bottom_bar_cl.add_child(sym)
		_pin_slot_nodes.append(sym)

		var lbl      := Label.new()
		lbl.text      = def["label"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position  = Vector2(x, bar_y + 60)
		lbl.size      = Vector2(slot_w, 24)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", C_TEXT)
		_bottom_bar_cl.add_child(lbl)
		_pin_slot_nodes.append(lbl)

		var btn      := Button.new()
		btn.flat      = true
		btn.position  = Vector2(x, bar_y)
		btn.size      = Vector2(slot_w, BOTTOM_BAR_H)
		btn.pressed.connect(_on_shortcut_pressed.bind(id))
		_bottom_bar_cl.add_child(btn)
		_pin_slot_nodes.append(btn)

# ── Menu modal overlay ──────────────────────────────────────────────────────
func _build_menu_overlay() -> void:
	_menu_overlay         = CanvasLayer.new()
	_menu_overlay.name    = "MenuOverlay"
	_menu_overlay.layer   = 30
	_menu_overlay.visible = false
	add_child(_menu_overlay)

	# Dim background (tap to close)
	var dim      := ColorRect.new()
	dim.color     = Color(0, 0, 0, 0.72)
	dim.position  = Vector2.ZERO
	dim.size      = Vector2(SCREEN_W, SCREEN_H)
	_menu_overlay.add_child(dim)

	var dim_btn      := Button.new()
	dim_btn.flat      = true
	dim_btn.position  = Vector2.ZERO
	dim_btn.size      = Vector2(SCREEN_W, SCREEN_H)
	dim_btn.pressed.connect(_on_menu_close)
	_menu_overlay.add_child(dim_btn)

	# Card — 3×3 grid + SHOP + "Edit Quick Bar" strip at bottom
	var card_w   := 680
	var card_h   := 660
	var card_x   := float(SCREEN_W - card_w) / 2.0
	var card_y   := float(SCREEN_H - card_h) / 2.0

	var card      := ColorRect.new()
	card.color     = C_PANEL
	card.position  = Vector2(card_x, card_y)
	card.size      = Vector2(card_w, card_h)
	_menu_overlay.add_child(card)

	var card_top      := ColorRect.new()
	card_top.color     = C_ACCENT
	card_top.position  = Vector2(card_x, card_y)
	card_top.size      = Vector2(card_w, 4)
	_menu_overlay.add_child(card_top)

	# Menu items: 3 columns × 4 rows (MINE + 9 shortcuts = 10, padded to 12)
	var items: Array = [
		["MINE",     C_TIMBER,  _on_menu_mine],
		["BUILD",    C_ACCENT,  _on_menu_build],
		["CRAFT",    C_LUMBER,  _on_menu_craft],
		["SELL",     C_GOLD,    _on_menu_sell],
		["CREW",     C_GREEN,   _on_menu_crew],
		["SKYLINE",  C_STONE,   _on_menu_skyline],
		["UPGRADES", C_XP,      _on_menu_upgrades],
		["CONTRACT", C_GOLD,    _on_menu_contract],
		["SHOP",     C_GEM,     _on_shop_btn_pressed],
		["MISSIONS", C_GOLD,             _on_menu_missions],
		["TOOLBOX",  Color(0.9, 0.5, 0.2), _on_menu_toolbox],
	]
	var cols      := 3
	var rows      := 4
	var pad       := 16
	# Reserve 72 px at bottom for the Edit Bar strip
	var edit_zone := 72
	var item_w    := float(card_w - pad * (cols + 1)) / float(cols)
	var item_h    := float(card_h - 60 - pad * (rows + 1) - edit_zone) / float(rows)

	for i in items.size():
		var col     := i % cols
		@warning_ignore("integer_division")
		var row     := i / cols
		var item_x  := card_x + pad + col * (item_w + pad)
		var item_y  := card_y + 50 + pad + row * (item_h + pad)
		var label:  String   = items[i][0]
		var accent: Color    = items[i][1]
		var cb:     Callable = items[i][2]

		var ibg      := ColorRect.new()
		ibg.color     = C_CARD
		ibg.position  = Vector2(item_x, item_y)
		ibg.size      = Vector2(item_w, item_h)
		_menu_overlay.add_child(ibg)

		var ibar      := ColorRect.new()
		ibar.color     = accent
		ibar.position  = Vector2(item_x, item_y)
		ibar.size      = Vector2(item_w, 4)
		_menu_overlay.add_child(ibar)

		var ibtn      := Button.new()
		ibtn.flat      = true
		ibtn.text      = label
		ibtn.position  = Vector2(item_x, item_y)
		ibtn.size      = Vector2(item_w, item_h)
		ibtn.pressed.connect(cb)
		ibtn.add_theme_color_override("font_color", accent)
		ibtn.add_theme_font_size_override("font_size", 17)
		_menu_overlay.add_child(ibtn)

	# Edit Quick Bar strip at bottom of card
	var edit_y := card_y + 50 + pad + float(rows) * (item_h + pad)

	var edit_sep      := ColorRect.new()
	edit_sep.color     = C_BORDER
	edit_sep.position  = Vector2(card_x + pad, edit_y)
	edit_sep.size      = Vector2(card_w - pad * 2, 1)
	_menu_overlay.add_child(edit_sep)

	var edit_btn      := Button.new()
	edit_btn.flat      = true
	edit_btn.text      = "⚙  Edit Quick Bar"
	edit_btn.position  = Vector2(card_x + pad, edit_y + 8)
	edit_btn.size      = Vector2(card_w - pad * 2, 48)
	edit_btn.pressed.connect(_on_pin_edit_open)
	edit_btn.add_theme_color_override("font_color", C_DIM)
	edit_btn.add_theme_font_size_override("font_size", 14)
	_menu_overlay.add_child(edit_btn)


# ── Pin customiser panel (layer 28, between panels and menu) ────────────────
func _build_pin_panel() -> void:
	_pin_panel         = CanvasLayer.new()
	_pin_panel.name    = "PinPanel"
	_pin_panel.layer   = 28
	_pin_panel.visible = false
	add_child(_pin_panel)

	# Dim backdrop — tap to close
	var dim      := ColorRect.new()
	dim.color     = Color(0, 0, 0, 0.82)
	dim.position  = Vector2.ZERO
	dim.size      = Vector2(SCREEN_W, SCREEN_H)
	_pin_panel.add_child(dim)

	var dim_close      := Button.new()
	dim_close.flat      = true
	dim_close.position  = Vector2.ZERO
	dim_close.size      = Vector2(SCREEN_W, SCREEN_H)
	dim_close.pressed.connect(_on_pin_edit_close)
	_pin_panel.add_child(dim_close)

	# Card
	var card_w  := 680
	var card_h  := 540
	var card_x  := float(SCREEN_W - card_w) / 2.0   # 20
	var card_y  := float(SCREEN_H - card_h) / 2.0   # 370

	var card      := ColorRect.new()
	card.color     = C_PANEL
	card.position  = Vector2(card_x, card_y)
	card.size      = Vector2(card_w, card_h)
	_pin_panel.add_child(card)

	# Title bar
	var title_bar      := ColorRect.new()
	title_bar.color     = C_ACCENT.darkened(0.65)
	title_bar.position  = Vector2(card_x, card_y)
	title_bar.size      = Vector2(card_w, 52)
	_pin_panel.add_child(title_bar)

	var title_lbl      := Label.new()
	title_lbl.text      = "Customize Quick Bar"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	title_lbl.position  = Vector2(card_x, card_y)
	title_lbl.size      = Vector2(card_w, 52)
	title_lbl.add_theme_font_size_override("font_size", 17)
	title_lbl.add_theme_color_override("font_color", C_TEXT)
	_pin_panel.add_child(title_lbl)

	var hint_lbl      := Label.new()
	hint_lbl.text      = "Tap to pin / unpin  ·  4 slots available"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.position  = Vector2(card_x, card_y + 52)
	hint_lbl.size      = Vector2(card_w, 26)
	hint_lbl.add_theme_font_size_override("font_size", 12)
	hint_lbl.add_theme_color_override("font_color", C_DIM)
	_pin_panel.add_child(hint_lbl)

	# 4 × 2 shortcut grid  (8 shortcuts from SHORTCUT_DEFS)
	var cols     := 4
	var pad      := 14
	var tile_w   := float(card_w - pad * (cols + 1)) / float(cols)   # ≈152 px
	var tile_h   := 168.0
	var grid_y   := card_y + 86.0   # title(52) + hint(26) + gap(8)

	_pin_card_borders.clear()
	_pin_state_labels.clear()

	for i in SHORTCUT_DEFS.size():
		var col := i % cols
		@warning_ignore("integer_division")
		var row := i / cols
		var tx  := card_x + pad + col * (tile_w + pad)
		var ty  := grid_y + row * (tile_h + pad)
		var def: Dictionary = SHORTCUT_DEFS[i]

		var border      := ColorRect.new()
		border.color     = C_BORDER
		border.position  = Vector2(tx - 2, ty - 2)
		border.size      = Vector2(tile_w + 4, tile_h + 4)
		_pin_panel.add_child(border)
		_pin_card_borders.append(border)

		var tile      := ColorRect.new()
		tile.color     = C_CARD
		tile.position  = Vector2(tx, ty)
		tile.size      = Vector2(tile_w, tile_h)
		_pin_panel.add_child(tile)

		var icon_sz  := 48
		var icon_x   := tx + (tile_w - icon_sz) / 2.0

		var icon      := ColorRect.new()
		icon.color     = _shortcut_color(def["id"])
		icon.position  = Vector2(icon_x, ty + 14)
		icon.size      = Vector2(icon_sz, icon_sz)
		_pin_panel.add_child(icon)

		var sym      := Label.new()
		sym.text      = def["symbol"]
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		sym.position  = Vector2(icon_x, ty + 14)
		sym.size      = Vector2(icon_sz, icon_sz)
		sym.add_theme_font_size_override("font_size", 22)
		sym.add_theme_color_override("font_color", Color.WHITE)
		_pin_panel.add_child(sym)

		var name_lbl      := Label.new()
		name_lbl.text      = def["label"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position  = Vector2(tx, ty + 70)
		name_lbl.size      = Vector2(tile_w, 22)
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		_pin_panel.add_child(name_lbl)

		var pin_lbl      := Label.new()
		pin_lbl.text      = ""
		pin_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pin_lbl.position  = Vector2(tx, ty + 96)
		pin_lbl.size      = Vector2(tile_w, 20)
		pin_lbl.add_theme_font_size_override("font_size", 10)
		pin_lbl.add_theme_color_override("font_color", C_GREEN)
		_pin_panel.add_child(pin_lbl)
		_pin_state_labels.append(pin_lbl)

		var tile_btn      := Button.new()
		tile_btn.flat      = true
		tile_btn.position  = Vector2(tx, ty)
		tile_btn.size      = Vector2(tile_w, tile_h)
		tile_btn.pressed.connect(_on_pin_toggle.bind(def["id"]))
		_pin_panel.add_child(tile_btn)

	# DONE button
	var done_y   := grid_y + 2.0 * tile_h + pad + 12.0

	var done_btn      := Button.new()
	done_btn.text      = "DONE"
	done_btn.position  = Vector2(card_x + 20, done_y)
	done_btn.size      = Vector2(card_w - 40, 48)
	done_btn.add_theme_font_size_override("font_size", 16)
	done_btn.pressed.connect(_on_pin_edit_close)
	_apply_btn_style(done_btn, C_ACCENT.darkened(0.35))
	_pin_panel.add_child(done_btn)

	_update_pin_panel_state()


# ── Build panel ─────────────────────────────────────────────────────────────
func _build_build_panel() -> void:
	_build_panel         = CanvasLayer.new()
	_build_panel.name    = "BuildPanel"
	_build_panel.layer   = 20
	_build_panel.visible = false
	add_child(_build_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_build_panel.add_child(bg)

	var close_btn := _build_panel_header(_build_panel, "BUILD", C_ACCENT)
	close_btn.pressed.connect(_on_build_close)

	# Stage name label
	_lbl_build_stage                      = Label.new()
	_lbl_build_stage.text                 = ""
	_lbl_build_stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_build_stage.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_lbl_build_stage.position             = Vector2(16, 84)
	_lbl_build_stage.size                 = Vector2(SCREEN_W - 32, 56)
	_lbl_build_stage.add_theme_color_override("font_color", C_TEXT)
	_build_panel.add_child(_lbl_build_stage)

	# Building sprite (stage art)
	_building_sprite          = Sprite2D.new()
	_building_sprite.name     = "BuildingSprite"
	_building_sprite.centered = true
	_building_sprite.position = Vector2(360, 240)
	_building_sprite.scale    = Vector2(1.0, 1.0)
	_building_sprite.visible  = false
	_build_panel.add_child(_building_sprite)

	# Build power display
	_lbl_build_bp                      = Label.new()
	_lbl_build_bp.text                 = "Build Power: 0"
	_lbl_build_bp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_build_bp.position             = Vector2(0, 382)
	_lbl_build_bp.size                 = Vector2(SCREEN_W, 32)
	_lbl_build_bp.add_theme_color_override("font_color", C_ACCENT)
	_build_panel.add_child(_lbl_build_bp)

	var divider      := ColorRect.new()
	divider.color     = C_BORDER
	divider.position  = Vector2(20, 420)
	divider.size      = Vector2(SCREEN_W - 40, 2)
	_build_panel.add_child(divider)

	# ── Requirements section (stage NOT started) ────────────────────────────
	var req_title     := Label.new()
	req_title.text     = "Required Materials"
	req_title.position = Vector2(24, 432)
	req_title.size     = Vector2(400, 30)
	req_title.add_theme_color_override("font_color", C_DIM)
	_build_panel.add_child(req_title)

	_build_reqs_box          = VBoxContainer.new()
	_build_reqs_box.position = Vector2(20, 468)
	_build_reqs_box.size     = Vector2(SCREEN_W - 40, 300)
	_build_panel.add_child(_build_reqs_box)

	_btn_start_stage          = Button.new()
	_btn_start_stage.text     = "Start Stage  (consumes materials)"
	_btn_start_stage.position = Vector2(20, 780)
	_btn_start_stage.size     = Vector2(SCREEN_W - 40, 66)
	_btn_start_stage.pressed.connect(_on_start_stage_pressed)
	_apply_btn_style(_btn_start_stage, C_GREEN.darkened(0.35))
	_build_panel.add_child(_btn_start_stage)

	_lbl_cant_start                      = Label.new()
	_lbl_cant_start.text                 = "Not enough materials."
	_lbl_cant_start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cant_start.position             = Vector2(20, 858)
	_lbl_cant_start.size                 = Vector2(SCREEN_W - 40, 32)
	_lbl_cant_start.add_theme_color_override("font_color", C_RED)
	_lbl_cant_start.visible              = false
	_build_panel.add_child(_lbl_cant_start)

	# ── Progress section (stage IS started) ────────────────────────────────
	_build_prog_bg         = ColorRect.new()
	_build_prog_bg.color   = Color(0.10, 0.12, 0.18)
	_build_prog_bg.position = Vector2(20, 432)
	_build_prog_bg.size     = Vector2(SCREEN_W - 40, 26)
	_build_prog_bg.visible  = false
	_build_panel.add_child(_build_prog_bg)

	_build_prog_fill         = ColorRect.new()
	_build_prog_fill.color   = C_ACCENT
	_build_prog_fill.position = Vector2(20, 432)
	_build_prog_fill.size     = Vector2(0, 26)
	_build_prog_fill.visible  = false
	_build_panel.add_child(_build_prog_fill)

	_lbl_build_pct                      = Label.new()
	_lbl_build_pct.text                 = "0%"
	_lbl_build_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_build_pct.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_build_pct.position             = Vector2(20, 432)
	_lbl_build_pct.size                 = Vector2(SCREEN_W - 40, 26)
	_lbl_build_pct.add_theme_font_size_override("font_size", 13)
	_lbl_build_pct.add_theme_color_override("font_color", C_TEXT)
	_lbl_build_pct.visible              = false
	_build_panel.add_child(_lbl_build_pct)

	# Big "TAP TO BUILD" area
	var tap_bg      := ColorRect.new()
	tap_bg.color     = C_ACCENT.darkened(0.72)
	tap_bg.name      = "TapBuildBg"
	tap_bg.position  = Vector2(20, 474)
	tap_bg.size      = Vector2(SCREEN_W - 40, 500)
	tap_bg.visible   = false
	_build_panel.add_child(tap_bg)

	var tap_bar      := ColorRect.new()
	tap_bar.color     = C_ACCENT
	tap_bar.name      = "TapBuildBar"
	tap_bar.position  = Vector2(20, 474)
	tap_bar.size      = Vector2(SCREEN_W - 40, 4)
	tap_bar.visible   = false
	_build_panel.add_child(tap_bar)

	_btn_tap_build          = Button.new()
	_btn_tap_build.flat      = true
	_btn_tap_build.text      = "TAP TO BUILD"
	_btn_tap_build.position  = Vector2(20, 474)
	_btn_tap_build.size      = Vector2(SCREEN_W - 40, 500)
	_btn_tap_build.pressed.connect(_on_tap_build)
	_btn_tap_build.add_theme_color_override("font_color", C_ACCENT)
	_btn_tap_build.add_theme_font_size_override("font_size", 28)
	_btn_tap_build.visible   = false
	_build_panel.add_child(_btn_tap_build)

	_lbl_build_feedback                      = Label.new()
	_lbl_build_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_build_feedback.position             = Vector2(20, 588)
	_lbl_build_feedback.size                 = Vector2(SCREEN_W - 40, 40)
	_lbl_build_feedback.modulate.a           = 0.0
	_lbl_build_feedback.add_theme_color_override("font_color", C_ACCENT)
	_build_panel.add_child(_lbl_build_feedback)

# ── Crew overlay panel ──────────────────────────────────────────────────────
func _build_crew_panel() -> void:
	_crew_panel         = CanvasLayer.new()
	_crew_panel.name    = "CrewPanel"
	_crew_panel.layer   = 20
	_crew_panel.visible = false
	add_child(_crew_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_crew_panel.add_child(bg)

	var close_btn := _build_panel_header(_crew_panel, "CREW", C_ACCENT)
	close_btn.pressed.connect(_on_crew_close)

	_lbl_crew_bp                      = Label.new()
	_lbl_crew_bp.text                  = "Build Power: 0"
	_lbl_crew_bp.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_crew_bp.position              = Vector2(0, 88)
	_lbl_crew_bp.size                  = Vector2(SCREEN_W, 36)
	_lbl_crew_bp.add_theme_color_override("font_color", C_ACCENT)
	_crew_panel.add_child(_lbl_crew_bp)

	var templates := BuildDatabase.get_hireable_crew()

	# Scrollable area for cards (starts below the BP label)
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 130)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - 130 - BOTTOM_BAR_H)
	_crew_panel.add_child(scroll)

	_crew_scroll_content = Control.new()
	_crew_scroll_content.custom_minimum_size = Vector2(SCREEN_W, templates.size() * 210 + 20)
	scroll.add_child(_crew_scroll_content)

	for i in templates.size():
		_build_crew_card(templates[i], i)

	_build_crew_loc_picker()

func _build_crew_card(template: CrewMemberResource, idx: int) -> void:
	var card_y    := idx * 210 + 8
	var card_h    := 192
	var mat_color := _mat_color(template.material_type)

	var bg      := ColorRect.new()
	bg.color     = C_CARD
	bg.position  = Vector2(14, card_y)
	bg.size      = Vector2(SCREEN_W - 28, card_h)
	_crew_scroll_content.add_child(bg)

	var left_bar      := ColorRect.new()
	left_bar.color     = mat_color
	left_bar.position  = Vector2(14, card_y)
	left_bar.size      = Vector2(5, card_h)
	_crew_scroll_content.add_child(left_bar)

	# Avatar
	var av_bg      := ColorRect.new()
	av_bg.color     = mat_color.darkened(0.55)
	av_bg.position  = Vector2(28, card_y + 14)
	av_bg.size      = Vector2(58, 58)
	_crew_scroll_content.add_child(av_bg)

	var av_lbl     := Label.new()
	av_lbl.text     = template.display_name.left(1)
	av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	av_lbl.position = Vector2(28, card_y + 14)
	av_lbl.size     = Vector2(58, 58)
	av_lbl.add_theme_font_size_override("font_size", 26)
	av_lbl.add_theme_color_override("font_color", mat_color)
	_crew_scroll_content.add_child(av_lbl)

	# Name
	var name_lbl     := Label.new()
	name_lbl.text     = template.display_name
	name_lbl.position = Vector2(100, card_y + 12)
	name_lbl.size     = Vector2(300, 32)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	_crew_scroll_content.add_child(name_lbl)

	# Location badge (top-right)
	var loc_data := BuildDatabase.get_location(template.location_id)
	var loc_name: String = loc_data.get("display_name", template.location_id)
	var loc_lbl     := Label.new()
	loc_lbl.text     = loc_name
	loc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loc_lbl.position = Vector2(420, card_y + 14)
	loc_lbl.size     = Vector2(258, 26)
	loc_lbl.add_theme_font_size_override("font_size", 12)
	loc_lbl.add_theme_color_override("font_color", mat_color)
	_crew_scroll_content.add_child(loc_lbl)
	_crew_loc_labels.append(loc_lbl)

	# Rate label
	var rate_lbl     := Label.new()
	rate_lbl.text     = "%.1f %s/s at Lv.1" \
		% [template.base_speed_bonus, template.material_type.capitalize()]
	rate_lbl.position = Vector2(100, card_y + 50)
	rate_lbl.size     = Vector2(578, 28)
	rate_lbl.add_theme_color_override("font_color", C_DIM)
	_crew_scroll_content.add_child(rate_lbl)
	_crew_rate_labels.append(rate_lbl)

	# Level label
	var lvl_lbl     := Label.new()
	lvl_lbl.text     = "Not hired"
	lvl_lbl.position = Vector2(100, card_y + 90)
	lvl_lbl.size     = Vector2(220, 34)
	lvl_lbl.add_theme_color_override("font_color", C_DIM)
	_crew_scroll_content.add_child(lvl_lbl)
	_crew_level_labels.append(lvl_lbl)

	# Hire button
	var hire_btn     := Button.new()
	hire_btn.text     = "Hire  (%s cash)" % _fmt(template.hire_cost)
	hire_btn.position = Vector2(326, card_y + 88)
	hire_btn.size     = Vector2(350, 50)
	hire_btn.pressed.connect(_on_hire_pressed.bind(template.id))
	_apply_btn_style(hire_btn, C_GREEN.darkened(0.35))
	_crew_scroll_content.add_child(hire_btn)
	_crew_hire_btns.append(hire_btn)

	# Level-up button
	var lvlup_btn     := Button.new()
	lvlup_btn.text     = "Upgrade"
	lvlup_btn.position = Vector2(326, card_y + 88)
	lvlup_btn.size     = Vector2(218, 50)
	lvlup_btn.visible  = false
	lvlup_btn.pressed.connect(_on_levelup_pressed.bind(template.id))
	_apply_btn_style(lvlup_btn, C_GOLD.darkened(0.50), Color(0.12, 0.10, 0.02))
	_crew_scroll_content.add_child(lvlup_btn)
	_crew_levelup_btns.append(lvlup_btn)

	# Move (reassign location) button — visible only when hired
	var move_btn     := Button.new()
	move_btn.text     = "▶ MOVE"
	move_btn.position = Vector2(554, card_y + 88)
	move_btn.size     = Vector2(122, 50)
	move_btn.visible  = false
	move_btn.pressed.connect(_on_crew_move_pressed.bind(template.id))
	_apply_btn_style(move_btn, C_ACCENT.darkened(0.45))
	_crew_scroll_content.add_child(move_btn)
	_crew_move_btns.append(move_btn)

	# Progress bar
	var pbg     := ColorRect.new()
	pbg.color    = Color(0.10, 0.10, 0.16)
	pbg.position = Vector2(14, card_y + card_h - 14)
	pbg.size     = Vector2(SCREEN_W - 28, 10)
	_crew_scroll_content.add_child(pbg)

	var pfill     := ColorRect.new()
	pfill.color    = mat_color.darkened(0.2)
	pfill.position = Vector2(14, card_y + card_h - 14)
	pfill.size     = Vector2(0, 10)
	_crew_scroll_content.add_child(pfill)
	_crew_progress_fills.append(pfill)

# ── Crew location picker overlay ────────────────────────────────────────────
func _build_crew_loc_picker() -> void:
	_crew_loc_picker        = CanvasLayer.new()
	_crew_loc_picker.layer  = 25
	_crew_loc_picker.visible = false
	add_child(_crew_loc_picker)

	# Dim backdrop
	var dim      := ColorRect.new()
	dim.color     = Color(0.0, 0.0, 0.0, 0.65)
	dim.position  = Vector2.ZERO
	dim.size      = Vector2(SCREEN_W, SCREEN_H)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_crew_loc_picker.visible = false)
	_crew_loc_picker.add_child(dim)

	# Card
	const CW := 580
	const CH := 740
	var cx := (SCREEN_W - CW) / 2.0
	var cy := (SCREEN_H - CH) / 2.0

	var card      := ColorRect.new()
	card.color     = C_PANEL
	card.position  = Vector2(cx, cy)
	card.size      = Vector2(CW, CH)
	_crew_loc_picker.add_child(card)

	# Bolt-texture overlay
	var pt := load(PANEL_TEX_PATH) as Texture2D
	if pt:
		var np := NinePatchRect.new()
		np.texture             = pt
		np.position            = Vector2(cx, cy)
		np.size                = Vector2(CW, CH)
		np.patch_margin_left   = 16
		np.patch_margin_right  = 16
		np.patch_margin_top    = 16
		np.patch_margin_bottom = 16
		np.modulate            = Color(0.65, 0.70, 0.78, 0.18)
		_crew_loc_picker.add_child(np)

	# Top strip + title
	var strip      := ColorRect.new()
	strip.color     = C_ACCENT
	strip.position  = Vector2(cx, cy)
	strip.size      = Vector2(CW, 4)
	_crew_loc_picker.add_child(strip)

	var title      := Label.new()
	title.text      = "ASSIGN LOCATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position  = Vector2(cx, cy + 10)
	title.size      = Vector2(CW, 42)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_TEXT)
	_crew_loc_picker.add_child(title)

	var close_btn      := Button.new()
	close_btn.text      = "✕"
	close_btn.flat      = true
	close_btn.position  = Vector2(cx + CW - 50, cy + 8)
	close_btn.size      = Vector2(42, 34)
	close_btn.add_theme_color_override("font_color", C_DIM)
	close_btn.pressed.connect(func(): _crew_loc_picker.visible = false)
	_crew_loc_picker.add_child(close_btn)

	# Separator
	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.position  = Vector2(cx, cy + 54)
	sep.size      = Vector2(CW, 2)
	_crew_loc_picker.add_child(sep)

	# Location rows
	var row_y := cy + 62.0
	for loc_id: String in BuildDatabase.LOCATION_ORDER:
		var ld     := BuildDatabase.get_location(loc_id)
		var mat    := ld.get("material", "timber") as String
		var dname  := ld.get("display_name", loc_id) as String
		var col    := _mat_color(mat)

		var row_btn      := Button.new()
		row_btn.flat      = true
		row_btn.position  = Vector2(cx, row_y)
		row_btn.size      = Vector2(CW, 76)
		row_btn.pressed.connect(_on_crew_loc_selected.bind(loc_id))
		_crew_loc_picker.add_child(row_btn)

		# Colour strip
		var lstrip      := ColorRect.new()
		lstrip.color     = col
		lstrip.position  = Vector2(0, 10)
		lstrip.size      = Vector2(5, 56)
		row_btn.add_child(lstrip)

		# Location name
		var nlbl      := Label.new()
		nlbl.text      = dname
		nlbl.position  = Vector2(18, 10)
		nlbl.size      = Vector2(CW - 28, 34)
		nlbl.add_theme_font_size_override("font_size", 16)
		nlbl.add_theme_color_override("font_color", C_TEXT)
		row_btn.add_child(nlbl)

		# Material sub-label
		var mlbl      := Label.new()
		mlbl.text      = mat.replace("_", " ").capitalize()
		mlbl.position  = Vector2(18, 44)
		mlbl.size      = Vector2(CW - 28, 24)
		mlbl.add_theme_font_size_override("font_size", 12)
		mlbl.add_theme_color_override("font_color", col)
		row_btn.add_child(mlbl)

		# Divider
		var div      := ColorRect.new()
		div.color     = C_BORDER
		div.position  = Vector2(cx, row_y + 76)
		div.size      = Vector2(CW, 1)
		_crew_loc_picker.add_child(div)

		row_y += 77.0

func _on_crew_move_pressed(crew_id: String) -> void:
	_crew_loc_picker_for   = crew_id
	_crew_loc_picker.visible = true

func _on_crew_loc_selected(loc_id: String) -> void:
	_crew_loc_picker.visible = false
	if _crew_loc_picker_for.is_empty():
		return
	var member := _crew_member_dict(_crew_loc_picker_for)
	if member.is_empty():
		return
	var ld := BuildDatabase.get_location(loc_id)
	var mat: String = ld.get("material", "timber")
	member["location_id"]   = loc_id
	member["material_type"] = mat
	_crew_loc_picker_for = ""
	_update_crew_panel()

# ── Craft overlay panel ─────────────────────────────────────────────────────
func _build_craft_panel() -> void:
	_craft_panel         = CanvasLayer.new()
	_craft_panel.name    = "CraftPanel"
	_craft_panel.layer   = 20
	_craft_panel.visible = false
	add_child(_craft_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_craft_panel.add_child(bg)

	var close_btn := _build_panel_header(_craft_panel, "WORKSHOP", C_LUMBER)
	close_btn.pressed.connect(_on_craft_close)

	# Inventory grid: 4 rows × 4 columns
	# Rows 1-2 = raw materials, Rows 3-4 = refined
	var inv_bg      := ColorRect.new()
	inv_bg.color     = C_CARD
	inv_bg.position  = Vector2(14, 88)
	inv_bg.size      = Vector2(SCREEN_W - 28, 258)
	_craft_panel.add_child(inv_bg)

	var inv_title     := Label.new()
	inv_title.text     = "Inventory"
	inv_title.position = Vector2(28, 92)
	inv_title.size     = Vector2(200, 22)
	inv_title.add_theme_color_override("font_color", C_DIM)
	inv_title.add_theme_font_size_override("font_size", 12)
	_craft_panel.add_child(inv_title)

	# 16 materials: 8 raw (rows 1-2), 8 refined (rows 3-4)
	var inv_defs: Array = [
		["Timber",      C_TIMBER,     ],
		["Stone",       C_STONE,      ],
		["Sand",        C_SAND,       ],
		["Steel Ore",   C_STEEL_ORE,  ],
		["Clay",        C_CLAY,       ],
		["Copper Ore",  C_COPPER_ORE, ],
		["Limestone",   C_LIMESTONE,  ],
		["Bauxite",     C_BAUXITE,    ],
		["Lumber",      C_LUMBER,     ],
		["Concrete",    C_CONCRETE,   ],
		["Glass",       C_GLASS,      ],
		["Steel Beam",  C_STEEL_BEAM, ],
		["Brick",       C_BRICK,      ],
		["Copper Pipe", C_COPPER_PIPE,],
		["Plaster",     C_PLASTER,    ],
		["Aluminium",   C_ALUMINIUM,  ],
	]
	var inv_cell_w := float(SCREEN_W - 28) / 4.0
	for i in inv_defs.size():
		var row_y: int
		if   i < 4:  row_y = 112
		elif i < 8:  row_y = 164
		elif i < 12: row_y = 224
		else:        row_y = 276
		var col   := i % 4
		var lbl     := Label.new()
		lbl.text     = "%s\n0" % inv_defs[i][0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(14 + col * inv_cell_w, row_y)
		lbl.size     = Vector2(inv_cell_w, 48)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", inv_defs[i][1] as Color)
		_craft_panel.add_child(lbl)
		_craft_inv_lbls.append(lbl)

	# Dividers inside inventory box
	for sep_y: int in [160, 220, 272]:
		var row_sep      := ColorRect.new()
		row_sep.color     = C_BORDER
		row_sep.position  = Vector2(14, sep_y)
		row_sep.size      = Vector2(SCREEN_W - 28, 1)
		_craft_panel.add_child(row_sep)
	# Thicker divider between raw and refined groups
	var grp_sep      := ColorRect.new()
	grp_sep.color     = C_ACCENT.darkened(0.5)
	grp_sep.position  = Vector2(14, 216)
	grp_sep.size      = Vector2(SCREEN_W - 28, 3)
	_craft_panel.add_child(grp_sep)

	# Separator before recipe scroll
	var div      := ColorRect.new()
	div.color     = C_BORDER
	div.position  = Vector2(0, 352)
	div.size      = Vector2(SCREEN_W, 2)
	_craft_panel.add_child(div)

	# Recipe cards in ScrollContainer
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 358)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 358)
	_craft_panel.add_child(scroll)

	var vbox      := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(SCREEN_W, 0)
	scroll.add_child(vbox)

	var recipes: Array = [
		["timber",     "lumber",      3, C_LUMBER,      "Lumber",      "Timber"    ],
		["stone",      "concrete",    3, C_CONCRETE,    "Concrete",    "Stone"     ],
		["sand",       "glass",       3, C_GLASS,       "Glass",       "Sand"      ],
		["steel_ore",  "steel_beam",  3, C_STEEL_BEAM,  "Steel Beam",  "Steel Ore" ],
		["clay",       "brick",       3, C_BRICK,       "Brick",       "Clay"      ],
		["copper_ore", "copper_pipe", 3, C_COPPER_PIPE, "Copper Pipe", "Copper Ore"],
		["limestone",  "plaster",     3, C_PLASTER,     "Plaster",     "Limestone" ],
		["bauxite",    "aluminium",   3, C_ALUMINIUM,   "Aluminium",   "Bauxite"   ],
	]
	for r: Array in recipes:
		var raw_id:   String = r[0]
		var ref_id:   String = r[1]
		var cost:     int    = r[2]
		var accent:   Color  = r[3]
		var ref_name: String = r[4]
		var raw_name: String = r[5]

		var card      := ColorRect.new()
		card.color     = C_CARD
		card.custom_minimum_size = Vector2(SCREEN_W, 210)
		vbox.add_child(card)

		var left_bar      := ColorRect.new()
		left_bar.color     = accent
		left_bar.position  = Vector2(0, 0)
		left_bar.size      = Vector2(5, 210)
		card.add_child(left_bar)

		var ref_lbl     := Label.new()
		ref_lbl.text     = ref_name
		ref_lbl.position = Vector2(18, 12)
		ref_lbl.size     = Vector2(400, 36)
		ref_lbl.add_theme_font_size_override("font_size", 20)
		ref_lbl.add_theme_color_override("font_color", accent)
		card.add_child(ref_lbl)

		var recipe_lbl     := Label.new()
		recipe_lbl.text     = "%d %s  →  1 %s" % [cost, raw_name, ref_name]
		recipe_lbl.position = Vector2(18, 54)
		recipe_lbl.size     = Vector2(SCREEN_W - 36, 28)
		recipe_lbl.add_theme_color_override("font_color", C_DIM)
		card.add_child(recipe_lbl)

		var yield_lbl     := Label.new()
		yield_lbl.text     = "Will make: 0"
		yield_lbl.position = Vector2(18, 90)
		yield_lbl.size     = Vector2(SCREEN_W - 36, 28)
		yield_lbl.add_theme_color_override("font_color", C_TEXT)
		card.add_child(yield_lbl)
		_craft_yield_lbls.append(yield_lbl)

		var btn1     := Button.new()
		btn1.text     = "Craft 1"
		btn1.position = Vector2(18, 130)
		btn1.size     = Vector2(200, 62)
		btn1.pressed.connect(_on_craft_one.bind(raw_id, ref_id, cost))
		_apply_btn_style(btn1, accent.darkened(0.50))
		card.add_child(btn1)
		_craft1_btns.append(btn1)

		var btn_all     := Button.new()
		btn_all.text     = "Craft All"
		btn_all.position = Vector2(234, 130)
		btn_all.size     = Vector2(SCREEN_W - 252, 62)
		btn_all.pressed.connect(_on_craft_all.bind(raw_id, ref_id, cost))
		_apply_btn_style(btn_all, C_GREEN.darkened(0.35))
		card.add_child(btn_all)
		_craftall_btns.append(btn_all)

		var sep      := ColorRect.new()
		sep.color     = C_BORDER
		sep.custom_minimum_size = Vector2(SCREEN_W, 2)
		vbox.add_child(sep)

# ── Wall panel ──────────────────────────────────────────────────────────────
func _build_wall_panel() -> void:
	_wall_panel         = CanvasLayer.new()
	_wall_panel.name    = "WallPanel"
	_wall_panel.layer   = 25
	_wall_panel.visible = false
	add_child(_wall_panel)

	var bg      := ColorRect.new()
	bg.color     = Color(0.05, 0.04, 0.07, 0.98)
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_wall_panel.add_child(bg)

	var card      := ColorRect.new()
	card.color     = C_CARD
	card.position  = Vector2(36, 260)
	card.size      = Vector2(648, 480)
	_wall_panel.add_child(card)

	var top_bar      := ColorRect.new()
	top_bar.color     = C_RED
	top_bar.position  = Vector2(36, 260)
	top_bar.size      = Vector2(648, 5)
	_wall_panel.add_child(top_bar)

	_lbl_wall_title                      = Label.new()
	_lbl_wall_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_wall_title.position             = Vector2(56, 282)
	_lbl_wall_title.size                 = Vector2(608, 58)
	_lbl_wall_title.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_lbl_wall_title.add_theme_font_size_override("font_size", 22)
	_lbl_wall_title.add_theme_color_override("font_color", C_RED)
	_wall_panel.add_child(_lbl_wall_title)

	_lbl_wall_detail                      = Label.new()
	_lbl_wall_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_wall_detail.position             = Vector2(56, 360)
	_lbl_wall_detail.size                 = Vector2(608, 240)
	_lbl_wall_detail.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_lbl_wall_detail.add_theme_color_override("font_color", C_TEXT)
	_wall_panel.add_child(_lbl_wall_detail)

	var keep_btn     := Button.new()
	keep_btn.text     = "Keep Building"
	keep_btn.position = Vector2(56, 660)
	keep_btn.size     = Vector2(280, 60)
	keep_btn.pressed.connect(_on_wall_keep_pressed)
	_apply_btn_style(keep_btn, Color(0.18, 0.20, 0.32))
	_wall_panel.add_child(keep_btn)

	var crew_btn     := Button.new()
	crew_btn.text     = "Open Crew ->"
	crew_btn.position = Vector2(384, 660)
	crew_btn.size     = Vector2(280, 60)
	crew_btn.pressed.connect(_on_wall_crew_pressed)
	_apply_btn_style(crew_btn, C_GREEN.darkened(0.35))
	_wall_panel.add_child(crew_btn)

# ── Skyline overlay panel ───────────────────────────────────────────────────
func _build_skyline_panel() -> void:
	_skyline_panel         = CanvasLayer.new()
	_skyline_panel.name    = "SkylinePanel"
	_skyline_panel.layer   = 20
	_skyline_panel.visible = false
	add_child(_skyline_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_skyline_panel.add_child(bg)

	var close_btn := _build_panel_header(_skyline_panel, "SKYLINE", C_GOLD)
	close_btn.pressed.connect(_on_skyline_close)

	var sub      := Label.new()
	sub.text      = "All completed buildings:"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position  = Vector2(0, 86)
	sub.size      = Vector2(SCREEN_W, 34)
	sub.add_theme_color_override("font_color", C_DIM)
	_skyline_panel.add_child(sub)

	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 128)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 128 - 90)
	_skyline_panel.add_child(scroll)

	_skyline_list_box          = VBoxContainer.new()
	_skyline_list_box.position = Vector2.ZERO
	_skyline_list_box.size     = Vector2(SCREEN_W, 0)
	scroll.add_child(_skyline_list_box)

	# "New Contract" footer
	var nc_sep      := ColorRect.new()
	nc_sep.color     = C_BORDER
	nc_sep.position  = Vector2(0, SCREEN_H - BOTTOM_BAR_H - 90)
	nc_sep.size      = Vector2(SCREEN_W, 2)
	_skyline_panel.add_child(nc_sep)

	_btn_new_contract          = Button.new()
	_btn_new_contract.position = Vector2(60, SCREEN_H - BOTTOM_BAR_H - 84)
	_btn_new_contract.size     = Vector2(SCREEN_W - 120, 76)
	_btn_new_contract.add_theme_font_size_override("font_size", 17)
	_btn_new_contract.pressed.connect(_on_new_contract_pressed)
	_apply_btn_style(_btn_new_contract, C_GREEN.darkened(0.35))
	_skyline_panel.add_child(_btn_new_contract)

	_lbl_new_contract_locked          = Label.new()
	_lbl_new_contract_locked.text     = "Reach Level 10 to sign a New Contract"
	_lbl_new_contract_locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_new_contract_locked.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_new_contract_locked.position = Vector2(60, SCREEN_H - BOTTOM_BAR_H - 84)
	_lbl_new_contract_locked.size     = Vector2(SCREEN_W - 120, 76)
	_lbl_new_contract_locked.add_theme_color_override("font_color", C_DIM)
	_skyline_panel.add_child(_lbl_new_contract_locked)

# ── Sell overlay panel ─────────────────────────────────────────────────────
## Sell prices (cash per unit) — raw materials cheap, refined profitable
const SELL_PRICES: Dictionary = {
	"timber":      1, "stone":       1, "sand":        1, "steel_ore":   2,
	"clay":        2, "copper_ore":  2, "limestone":   2, "bauxite":     3,
	"lumber":      4, "concrete":    4, "glass":       6, "steel_beam":  8,
	"brick":       6, "copper_pipe": 8, "plaster":     6, "aluminium":  10,
}

func _build_sell_panel() -> void:
	_sell_panel         = CanvasLayer.new()
	_sell_panel.name    = "SellPanel"
	_sell_panel.layer   = 20
	_sell_panel.visible = false
	add_child(_sell_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_sell_panel.add_child(bg)

	var close_btn := _build_panel_header(_sell_panel, "SELL", C_GOLD)
	close_btn.pressed.connect(_on_sell_close)

	var sub      := Label.new()
	sub.text      = "Raw materials sell for less — craft first for more cash."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	sub.position  = Vector2(20, 84)
	sub.size      = Vector2(SCREEN_W - 40, 36)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_DIM)
	_sell_panel.add_child(sub)

	# All 8 materials in a scrollable VBox (compact cards)
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 128)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 128)
	_sell_panel.add_child(scroll)

	var vbox      := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(SCREEN_W, 0)
	scroll.add_child(vbox)

	var mat_defs: Array = [
		["timber",     "Timber",     C_TIMBER,     ],
		["stone",      "Stone",      C_STONE,      ],
		["sand",       "Sand",       C_SAND,       ],
		["steel_ore",  "Steel Ore",  C_STEEL_ORE,  ],
		["clay",       "Clay",       C_CLAY,       ],
		["copper_ore", "Copper Ore", C_COPPER_ORE, ],
		["limestone",  "Limestone",  C_LIMESTONE,  ],
		["bauxite",    "Bauxite",    C_BAUXITE,    ],
		["lumber",     "Lumber",     C_LUMBER,     ],
		["concrete",   "Concrete",   C_CONCRETE,   ],
		["glass",      "Glass",      C_GLASS,      ],
		["steel_beam", "Steel Beam", C_STEEL_BEAM, ],
		["brick",      "Brick",      C_BRICK,      ],
		["copper_pipe","Copper Pipe",C_COPPER_PIPE,],
		["plaster",    "Plaster",    C_PLASTER,    ],
		["aluminium",  "Aluminium",  C_ALUMINIUM,  ],
	]

	for md: Array in mat_defs:
		var mid: String   = md[0]
		var mname: String = md[1]
		var accent: Color = md[2]
		var price: int    = int(SELL_PRICES.get(mid, 1))

		var card      := ColorRect.new()
		card.color     = C_CARD
		card.custom_minimum_size = Vector2(SCREEN_W, 130)
		vbox.add_child(card)

		var left_bar      := ColorRect.new()
		left_bar.color     = accent
		left_bar.position  = Vector2(0, 0)
		left_bar.size      = Vector2(5, 130)
		card.add_child(left_bar)

		var name_lbl     := Label.new()
		name_lbl.text     = mname
		name_lbl.position = Vector2(18, 10)
		name_lbl.size     = Vector2(320, 32)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", accent)
		card.add_child(name_lbl)

		var price_lbl     := Label.new()
		price_lbl.text     = "$ %d / unit" % price
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.position = Vector2(360, 14)
		price_lbl.size     = Vector2(340, 24)
		price_lbl.add_theme_font_size_override("font_size", 13)
		price_lbl.add_theme_color_override("font_color", C_GOLD)
		card.add_child(price_lbl)

		var inv_lbl     := Label.new()
		inv_lbl.text     = "Have: 0"
		inv_lbl.position = Vector2(18, 46)
		inv_lbl.size     = Vector2(280, 26)
		inv_lbl.add_theme_font_size_override("font_size", 13)
		inv_lbl.add_theme_color_override("font_color", C_DIM)
		card.add_child(inv_lbl)
		_sell_inv_lbls.append(inv_lbl)

		var earn_lbl     := Label.new()
		earn_lbl.text     = "= $ 0"
		earn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		earn_lbl.position = Vector2(360, 46)
		earn_lbl.size     = Vector2(340, 26)
		earn_lbl.add_theme_font_size_override("font_size", 13)
		earn_lbl.add_theme_color_override("font_color", C_GOLD)
		card.add_child(earn_lbl)
		_sell_earn_lbls.append(earn_lbl)

		# Three sell buttons
		var btn_defs: Array  = [["Sell 1", 1], ["Sell 10", 10], ["Sell All", -1]]
		var btn_bgs:  Array  = [Color(0.18, 0.22, 0.36), Color(0.24, 0.30, 0.46), Color(0.52, 0.14, 0.14)]
		var btn_w := (SCREEN_W - 18 * 2 - 8 * 2) / 3.0
		for bi in btn_defs.size():
			var btn     := Button.new()
			btn.text     = btn_defs[bi][0]
			btn.position = Vector2(18 + bi * (btn_w + 8), 80)
			btn.size     = Vector2(btn_w, 40)
			btn.pressed.connect(_on_sell_pressed.bind(mid, int(btn_defs[bi][1])))
			btn.add_theme_font_size_override("font_size", 13)
			_apply_btn_style(btn, btn_bgs[bi])
			card.add_child(btn)

		var sep      := ColorRect.new()
		sep.color     = C_BORDER
		sep.custom_minimum_size = Vector2(SCREEN_W, 2)
		vbox.add_child(sep)

# ── Upgrades overlay panel ─────────────────────────────────────────────────
func _build_upgrades_panel() -> void:
	_upgrades_panel         = CanvasLayer.new()
	_upgrades_panel.name    = "UpgradesPanel"
	_upgrades_panel.layer   = 20
	_upgrades_panel.visible = false
	add_child(_upgrades_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_upgrades_panel.add_child(bg)

	var close_btn := _build_panel_header(_upgrades_panel, "UPGRADES", C_XP)
	close_btn.pressed.connect(_on_upgrades_close)

	var sub      := Label.new()
	sub.text      = "Unlocked by player level  ·  costs multiply ×2 per level"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position  = Vector2(0, 84)
	sub.size      = Vector2(SCREEN_W, 28)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_DIM)
	_upgrades_panel.add_child(sub)

	# Scrollable area for cards
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 116)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 116)
	_upgrades_panel.add_child(scroll)

	var list      := VBoxContainer.new()
	list.name      = "UpgradeList"
	list.position  = Vector2.ZERO
	list.size      = Vector2(SCREEN_W, 0)
	scroll.add_child(list)

	# Build one card per upgrade definition
	var all_upgrades := UpgradeDatabase.get_all()
	for i in all_upgrades.size():
		var u: Dictionary = all_upgrades[i]
		var card := _build_upgrade_card(list, u)
		_upgrade_cards.append(card)

func _build_upgrade_card(parent: VBoxContainer, u: Dictionary) -> Dictionary:
	var accent := C_XP

	var outer      := ColorRect.new()
	outer.color     = C_CARD
	outer.custom_minimum_size = Vector2(SCREEN_W, 130)
	parent.add_child(outer)

	var left_bar      := ColorRect.new()
	left_bar.color     = accent
	left_bar.position  = Vector2(0, 0)
	left_bar.size      = Vector2(5, 130)
	outer.add_child(left_bar)

	var lock_stripe      := ColorRect.new()
	lock_stripe.name      = "LockStripe"
	lock_stripe.color     = Color(0, 0, 0, 0.50)
	lock_stripe.position  = Vector2(0, 0)
	lock_stripe.size      = Vector2(SCREEN_W, 130)
	lock_stripe.visible   = false
	outer.add_child(lock_stripe)

	var name_lbl     := Label.new()
	name_lbl.text     = u["name"]
	name_lbl.position = Vector2(18, 10)
	name_lbl.size     = Vector2(460, 34)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", accent)
	outer.add_child(name_lbl)

	var unlock_lbl     := Label.new()
	unlock_lbl.text     = "Lv.%d" % int(u["unlock_level"])
	unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	unlock_lbl.position = Vector2(488, 10)
	unlock_lbl.size     = Vector2(220, 28)
	unlock_lbl.add_theme_font_size_override("font_size", 13)
	unlock_lbl.add_theme_color_override("font_color", C_DIM)
	outer.add_child(unlock_lbl)

	var desc_lbl     := Label.new()
	desc_lbl.text     = u["description"]
	desc_lbl.position = Vector2(18, 46)
	desc_lbl.size     = Vector2(SCREEN_W - 36, 28)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", C_DIM)
	outer.add_child(desc_lbl)

	var level_lbl     := Label.new()
	level_lbl.text     = "Level 0 / %d" % int(u["max_level"])
	level_lbl.position = Vector2(18, 76)
	level_lbl.size     = Vector2(300, 28)
	level_lbl.add_theme_color_override("font_color", C_TEXT)
	outer.add_child(level_lbl)

	var cost_lbl     := Label.new()
	cost_lbl.text     = ""
	cost_lbl.position = Vector2(18, 100)
	cost_lbl.size     = Vector2(440, 26)
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", C_GOLD)
	outer.add_child(cost_lbl)

	var btn     := Button.new()
	btn.text     = "Buy"
	btn.position = Vector2(530, 70)
	btn.size     = Vector2(168, 52)
	btn.pressed.connect(_on_upgrade_buy.bind(u["id"]))
	_apply_btn_style(btn, accent.darkened(0.50))
	outer.add_child(btn)

	# Spacer line between cards
	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.custom_minimum_size = Vector2(SCREEN_W, 2)
	parent.add_child(sep)

	return {
		"id":         u["id"],
		"outer":      outer,
		"lock":       lock_stripe,
		"name_lbl":   name_lbl,
		"level_lbl":  level_lbl,
		"cost_lbl":   cost_lbl,
		"btn":        btn,
	}

# ── Contract panel ─────────────────────────────────────────────────────────
func _build_contract_panel() -> void:
	_contract_panel         = CanvasLayer.new()
	_contract_panel.name    = "ContractPanel"
	_contract_panel.layer   = 20
	_contract_panel.visible = false
	add_child(_contract_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_contract_panel.add_child(bg)

	var close_btn := _build_panel_header(_contract_panel, "CONTRACT", C_GOLD)
	close_btn.pressed.connect(_on_contract_close)

	# Rep balance chip
	var rep_bg      := ColorRect.new()
	rep_bg.color     = C_CARD
	rep_bg.position  = Vector2(16, 88)
	rep_bg.size      = Vector2(SCREEN_W - 32, 52)
	_contract_panel.add_child(rep_bg)

	var rep_bar      := ColorRect.new()
	rep_bar.color     = C_GOLD
	rep_bar.position  = Vector2(16, 88)
	rep_bar.size      = Vector2(SCREEN_W - 32, 3)
	_contract_panel.add_child(rep_bar)

	_lbl_contract_rep = Label.new()
	_lbl_contract_rep.text      = "Reputation Points: 0 RP"
	_lbl_contract_rep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_contract_rep.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_lbl_contract_rep.position  = Vector2(16, 88)
	_lbl_contract_rep.size      = Vector2(SCREEN_W - 32, 52)
	_lbl_contract_rep.add_theme_color_override("font_color", C_GOLD)
	_lbl_contract_rep.add_theme_font_size_override("font_size", 18)
	_contract_panel.add_child(_lbl_contract_rep)

	# Scrollable body (artifacts + portfolio)
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 148)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 148)
	_contract_panel.add_child(scroll)

	var vbox      := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(SCREEN_W, 0)
	scroll.add_child(vbox)

	# ARTIFACTS section
	var art_hdr      := Label.new()
	art_hdr.text      = "ARTIFACTS"
	art_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_hdr.custom_minimum_size  = Vector2(SCREEN_W, 48)
	art_hdr.add_theme_color_override("font_color", C_GOLD)
	art_hdr.add_theme_font_size_override("font_size", 16)
	vbox.add_child(art_hdr)

	_artifact_cards = []
	for a: Dictionary in ArtifactDatabase.get_all():
		var card_dict := _build_artifact_card(vbox, a)
		_artifact_cards.append(card_dict)

	# Separator
	var sep_ctrl      := Control.new()
	sep_ctrl.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(sep_ctrl)

	var sep_line      := ColorRect.new()
	sep_line.color     = C_BORDER
	sep_line.custom_minimum_size = Vector2(SCREEN_W, 2)
	vbox.add_child(sep_line)

	var sep_ctrl2      := Control.new()
	sep_ctrl2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sep_ctrl2)

	# PORTFOLIO section
	var port_hdr      := Label.new()
	port_hdr.text      = "PORTFOLIO  (all-time builds)"
	port_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	port_hdr.custom_minimum_size  = Vector2(SCREEN_W, 48)
	port_hdr.add_theme_color_override("font_color", C_DIM)
	port_hdr.add_theme_font_size_override("font_size", 16)
	vbox.add_child(port_hdr)

	_portfolio_list_box      = VBoxContainer.new()
	_portfolio_list_box.custom_minimum_size = Vector2(SCREEN_W, 0)
	vbox.add_child(_portfolio_list_box)

	var bottom_sp      := Control.new()
	bottom_sp.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(bottom_sp)

func _build_artifact_card(parent: VBoxContainer, a: Dictionary) -> Dictionary:
	var aid: String = a["id"]

	var outer      := ColorRect.new()
	outer.color     = C_CARD
	outer.custom_minimum_size = Vector2(SCREEN_W, 130)
	parent.add_child(outer)

	var left_bar      := ColorRect.new()
	left_bar.color     = C_GOLD
	left_bar.position  = Vector2(0, 0)
	left_bar.size      = Vector2(5, 130)
	outer.add_child(left_bar)

	var name_lbl     := Label.new()
	name_lbl.text     = a["name"]
	name_lbl.position = Vector2(18, 10)
	name_lbl.size     = Vector2(440, 34)
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", C_GOLD)
	outer.add_child(name_lbl)

	var desc_lbl     := Label.new()
	desc_lbl.text     = a["description"]
	desc_lbl.position = Vector2(18, 46)
	desc_lbl.size     = Vector2(440, 28)
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", C_DIM)
	outer.add_child(desc_lbl)

	var level_lbl     := Label.new()
	level_lbl.text     = "Level 0 / %d" % int(a["max_level"])
	level_lbl.position = Vector2(18, 78)
	level_lbl.size     = Vector2(220, 28)
	level_lbl.add_theme_color_override("font_color", C_TEXT)
	outer.add_child(level_lbl)

	var cost_lbl     := Label.new()
	cost_lbl.text     = "Cost: 1 RP"
	cost_lbl.position = Vector2(242, 78)
	cost_lbl.size     = Vector2(220, 28)
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", C_GOLD)
	outer.add_child(cost_lbl)

	var btn     := Button.new()
	btn.text     = "Buy"
	btn.position = Vector2(524, 68)
	btn.size     = Vector2(184, 56)
	btn.pressed.connect(_on_artifact_buy.bind(aid))
	_apply_btn_style(btn, C_GOLD.darkened(0.52))
	outer.add_child(btn)

	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.custom_minimum_size = Vector2(SCREEN_W, 2)
	parent.add_child(sep)

	return {
		"id":        aid,
		"outer":     outer,
		"name_lbl":  name_lbl,
		"level_lbl": level_lbl,
		"cost_lbl":  cost_lbl,
		"btn":       btn,
	}

# ── Prestige confirm panel ──────────────────────────────────────────────────
func _build_prestige_confirm_panel() -> void:
	_prestige_confirm_panel         = CanvasLayer.new()
	_prestige_confirm_panel.name    = "PrestigeConfirmPanel"
	_prestige_confirm_panel.layer   = 35
	_prestige_confirm_panel.visible = false
	add_child(_prestige_confirm_panel)

	# Dark overlay
	var dim      := ColorRect.new()
	dim.color     = Color(0, 0, 0, 0.80)
	dim.position  = Vector2.ZERO
	dim.size      = Vector2(SCREEN_W, SCREEN_H)
	_prestige_confirm_panel.add_child(dim)

	# Card
	var card_w := 660
	var card_h := 560
	var card_x := (SCREEN_W - card_w) / 2
	var card_y := (SCREEN_H - card_h) / 2

	var card      := ColorRect.new()
	card.color     = C_PANEL
	card.position  = Vector2(card_x, card_y)
	card.size      = Vector2(card_w, card_h)
	_prestige_confirm_panel.add_child(card)

	var card_top      := ColorRect.new()
	card_top.color     = C_GREEN
	card_top.position  = Vector2(card_x, card_y)
	card_top.size      = Vector2(card_w, 4)
	_prestige_confirm_panel.add_child(card_top)

	# Title
	var title      := Label.new()
	title.text      = "SIGN NEW CONTRACT?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position  = Vector2(card_x, card_y + 18)
	title.size      = Vector2(card_w, 48)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_TEXT)
	_prestige_confirm_panel.add_child(title)

	var sub      := Label.new()
	sub.text      = "You'll move on to your next project."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position  = Vector2(card_x, card_y + 66)
	sub.size      = Vector2(card_w, 30)
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", C_DIM)
	_prestige_confirm_panel.add_child(sub)

	# Separator
	var sep1      := ColorRect.new()
	sep1.color     = C_BORDER
	sep1.position  = Vector2(card_x + 20, card_y + 104)
	sep1.size      = Vector2(card_w - 40, 2)
	_prestige_confirm_panel.add_child(sep1)

	# Rep earned
	_lbl_prestige_rep_earned = Label.new()
	_lbl_prestige_rep_earned.text      = "+0 Reputation Points"
	_lbl_prestige_rep_earned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_prestige_rep_earned.position  = Vector2(card_x, card_y + 116)
	_lbl_prestige_rep_earned.size      = Vector2(card_w, 38)
	_lbl_prestige_rep_earned.add_theme_font_size_override("font_size", 22)
	_lbl_prestige_rep_earned.add_theme_color_override("font_color", C_GOLD)
	_prestige_confirm_panel.add_child(_lbl_prestige_rep_earned)

	_lbl_prestige_new_rep = Label.new()
	_lbl_prestige_new_rep.text      = "New total: 0 RP"
	_lbl_prestige_new_rep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_prestige_new_rep.position  = Vector2(card_x, card_y + 158)
	_lbl_prestige_new_rep.size      = Vector2(card_w, 28)
	_lbl_prestige_new_rep.add_theme_font_size_override("font_size", 14)
	_lbl_prestige_new_rep.add_theme_color_override("font_color", C_DIM)
	_prestige_confirm_panel.add_child(_lbl_prestige_new_rep)

	# Separator
	var sep2      := ColorRect.new()
	sep2.color     = C_BORDER
	sep2.position  = Vector2(card_x + 20, card_y + 196)
	sep2.size      = Vector2(card_w - 40, 2)
	_prestige_confirm_panel.add_child(sep2)

	# Resets / keeps labels
	var resets_lbl      := Label.new()
	resets_lbl.text      = "RESETS:"
	resets_lbl.position  = Vector2(card_x + 28, card_y + 210)
	resets_lbl.size      = Vector2(card_w - 56, 26)
	resets_lbl.add_theme_font_size_override("font_size", 13)
	resets_lbl.add_theme_color_override("font_color", C_RED)
	_prestige_confirm_panel.add_child(resets_lbl)

	var resets_val      := Label.new()
	resets_val.text      = "Cash  ·  Materials  ·  Crew  ·  Upgrades  ·  Level"
	resets_val.position  = Vector2(card_x + 28, card_y + 236)
	resets_val.size      = Vector2(card_w - 56, 28)
	resets_val.add_theme_font_size_override("font_size", 14)
	resets_val.add_theme_color_override("font_color", C_TEXT)
	resets_val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prestige_confirm_panel.add_child(resets_val)

	var keeps_lbl      := Label.new()
	keeps_lbl.text      = "KEEPS:"
	keeps_lbl.position  = Vector2(card_x + 28, card_y + 280)
	keeps_lbl.size      = Vector2(card_w - 56, 26)
	keeps_lbl.add_theme_font_size_override("font_size", 13)
	keeps_lbl.add_theme_color_override("font_color", C_GREEN)
	_prestige_confirm_panel.add_child(keeps_lbl)

	var keeps_val      := Label.new()
	keeps_val.text      = "Gems  ·  Reputation Points  ·  Portfolio  ·  Artifacts"
	keeps_val.position  = Vector2(card_x + 28, card_y + 306)
	keeps_val.size      = Vector2(card_w - 56, 28)
	keeps_val.add_theme_font_size_override("font_size", 14)
	keeps_val.add_theme_color_override("font_color", C_TEXT)
	keeps_val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prestige_confirm_panel.add_child(keeps_val)

	# Separator
	var sep3      := ColorRect.new()
	sep3.color     = C_BORDER
	sep3.position  = Vector2(card_x + 20, card_y + 346)
	sep3.size      = Vector2(card_w - 40, 2)
	_prestige_confirm_panel.add_child(sep3)

	# Warning
	var warn      := Label.new()
	warn.text      = "This cannot be undone."
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn.position  = Vector2(card_x, card_y + 354)
	warn.size      = Vector2(card_w, 28)
	warn.add_theme_font_size_override("font_size", 13)
	warn.add_theme_color_override("font_color", C_DIM)
	_prestige_confirm_panel.add_child(warn)

	# CONFIRM button
	var confirm_btn     := Button.new()
	confirm_btn.text     = "SIGN CONTRACT"
	confirm_btn.position = Vector2(card_x + 20, card_y + 390)
	confirm_btn.size     = Vector2((card_w - 56) / 2, 80)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.pressed.connect(_on_prestige_confirmed)
	_apply_btn_style(confirm_btn, C_GREEN.darkened(0.30))
	_prestige_confirm_panel.add_child(confirm_btn)

	# CANCEL button
	var cancel_btn     := Button.new()
	cancel_btn.text     = "CANCEL"
	cancel_btn.position = Vector2(card_x + 36 + (card_w - 56) / 2, card_y + 390)
	cancel_btn.size     = Vector2((card_w - 56) / 2, 80)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_on_prestige_cancel)
	_apply_btn_style(cancel_btn, Color(0.18, 0.20, 0.30), C_DIM)
	_prestige_confirm_panel.add_child(cancel_btn)

func _update_contract_panel() -> void:
	_lbl_contract_rep.text = "Reputation Points: %d RP" % GameState.reputation_points

	# Update artifact cards
	for card: Dictionary in _artifact_cards:
		var aid: String    = card["id"]
		var a              := ArtifactDatabase.get_artifact(aid)
		var cur_level: int = int(GameState.artifacts.get(aid, 0))
		var max_level: int = int(a.get("max_level", 1))
		var maxed: bool    = cur_level >= max_level
		var cost: int      = ArtifactDatabase.get_cost(aid, cur_level)
		var can_buy: bool  = not maxed and GameState.reputation_points >= cost

		card["level_lbl"].text = "Level %d / %d" % [cur_level, max_level]
		if maxed:
			card["cost_lbl"].text = "MAXED"
			card["cost_lbl"].add_theme_color_override("font_color", C_GREEN)
			card["btn"].disabled  = true
			card["btn"].text      = "Max"
		else:
			card["cost_lbl"].text = "Cost: %d RP" % cost
			card["cost_lbl"].add_theme_color_override("font_color",
				C_GOLD if can_buy else C_DIM)
			card["btn"].disabled  = not can_buy
			card["btn"].text      = "Buy"

	# Rebuild portfolio list
	for child in _portfolio_list_box.get_children():
		child.queue_free()

	if GameState.portfolio.is_empty():
		var empty_lbl      := Label.new()
		empty_lbl.text      = "No completed buildings yet.\nSign your first New Contract to populate this."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.custom_minimum_size  = Vector2(SCREEN_W, 80)
		empty_lbl.add_theme_color_override("font_color", C_DIM)
		_portfolio_list_box.add_child(empty_lbl)
		return

	# Count occurrences by tier_id
	var counts: Dictionary = {}
	for entry: String in GameState.portfolio:
		counts[entry] = counts.get(entry, 0) + 1

	for tier_id: String in counts.keys():
		var t        := BuildDatabase.get_tier(tier_id)
		var row      := Label.new()
		row.text      = "  %s  ×%d" % [(t.get("name") if t.has("name") else tier_id), counts[tier_id]]
		row.custom_minimum_size = Vector2(SCREEN_W, 38)
		row.add_theme_color_override("font_color", C_TEXT)
		_portfolio_list_box.add_child(row)

# ── Shop overlay panel ─────────────────────────────────────────────────────
func _build_shop_panel() -> void:
	_shop_panel         = CanvasLayer.new()
	_shop_panel.name    = "ShopPanel"
	_shop_panel.layer   = 20
	_shop_panel.visible = false
	add_child(_shop_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_shop_panel.add_child(bg)

	var close_btn := _build_panel_header(_shop_panel, "SHOP", C_GEM)
	close_btn.pressed.connect(_on_shop_close)

	_lbl_shop_gems                      = Label.new()
	_lbl_shop_gems.text                  = "◆ 0  Gems"
	_lbl_shop_gems.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_shop_gems.position              = Vector2(0, 88)
	_lbl_shop_gems.size                  = Vector2(SCREEN_W, 40)
	_lbl_shop_gems.add_theme_color_override("font_color", C_GEM)
	_shop_panel.add_child(_lbl_shop_gems)

	var policy      := Label.new()
	policy.text      = "Gems are earned through play.\nEvery item here is optional and never required to progress."
	policy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	policy.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	policy.position  = Vector2(40, 138)
	policy.size      = Vector2(SCREEN_W - 80, 60)
	policy.add_theme_color_override("font_color", C_DIM)
	_shop_panel.add_child(policy)

	var card      := ColorRect.new()
	card.color     = C_CARD
	card.position  = Vector2(20, 218)
	card.size      = Vector2(SCREEN_W - 40, 200)
	_shop_panel.add_child(card)

	var card_top      := ColorRect.new()
	card_top.color     = C_GEM
	card_top.position  = Vector2(20, 218)
	card_top.size      = Vector2(SCREEN_W - 40, 4)
	_shop_panel.add_child(card_top)

	var item_name     := Label.new()
	item_name.text     = "Instant Stage Skip"
	item_name.position = Vector2(36, 230)
	item_name.size     = Vector2(SCREEN_W - 72, 38)
	item_name.add_theme_font_size_override("font_size", 18)
	item_name.add_theme_color_override("font_color", C_TEXT)
	_shop_panel.add_child(item_name)

	var item_desc     := Label.new()
	item_desc.text     = "Complete the current build stage instantly.\nMaterials are not consumed."
	item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_desc.position = Vector2(36, 274)
	item_desc.size     = Vector2(SCREEN_W - 72, 60)
	item_desc.add_theme_color_override("font_color", C_DIM)
	_shop_panel.add_child(item_desc)

	_btn_stage_skip          = Button.new()
	_btn_stage_skip.text     = "Buy  (10 Gems)"
	_btn_stage_skip.position = Vector2(36, 346)
	_btn_stage_skip.size     = Vector2(300, 58)
	_btn_stage_skip.pressed.connect(_on_stage_skip_pressed)
	_apply_btn_style(_btn_stage_skip, C_GEM.darkened(0.45))
	_shop_panel.add_child(_btn_stage_skip)

	var ad_card      := ColorRect.new()
	ad_card.color     = Color(0.09, 0.12, 0.10)
	ad_card.position  = Vector2(20, 440)
	ad_card.size      = Vector2(SCREEN_W - 40, 120)
	_shop_panel.add_child(ad_card)

	var ad_lbl      := Label.new()
	ad_lbl.text      = "Watch an optional ad for bonus Gems\n(Coming soon — always player-initiated, never forced)"
	ad_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	ad_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_lbl.position  = Vector2(36, 452)
	ad_lbl.size      = Vector2(SCREEN_W - 72, 100)
	ad_lbl.add_theme_color_override("font_color", C_DIM)
	_shop_panel.add_child(ad_lbl)

# ══════════════════════════════════════════════════════════════════════════
# Panel open / close
# ══════════════════════════════════════════════════════════════════════════

func _close_all_panels() -> void:
	_build_panel.visible           = false
	_crew_panel.visible            = false
	_craft_panel.visible           = false
	_sell_panel.visible            = false
	_wall_panel.visible            = false
	_skyline_panel.visible         = false
	_upgrades_panel.visible        = false
	_contract_panel.visible        = false
	_prestige_confirm_panel.visible = false
	_shop_panel.visible            = false
	_missions_panel.visible        = false
	_toolbox_panel.visible         = false
	_menu_overlay.visible          = false
	_loc_picker_panel.visible      = false
	_pin_panel.visible             = false

func _on_menu_btn_pressed() -> void:
	var opening := not _menu_overlay.visible
	_close_all_panels()
	_menu_overlay.visible = opening

func _on_menu_close() -> void:
	_menu_overlay.visible = false

# ── Quick-bar shortcut helpers ──────────────────────────────────────────────

## Return the Color accent for a given shortcut id.
func _shortcut_color(id: String) -> Color:
	match id:
		"build":    return C_ACCENT
		"crew":     return C_GREEN
		"craft":    return C_LUMBER
		"sell":     return C_GOLD
		"skyline":  return C_STONE
		"upgrades": return C_XP
		"contract": return C_GEM.darkened(0.3)
		"shop":     return C_GEM
		"missions": return C_GOLD
		"toolbox":  return Color(0.90, 0.50, 0.20)
		_:          return C_DIM

## Return the SHORTCUT_DEFS entry for id, or empty dict if not found.
func _shortcut_def(id: String) -> Dictionary:
	for def: Dictionary in SHORTCUT_DEFS:
		if def["id"] == id:
			return def
	return {}

## Dispatch a quick-bar shortcut tap to the correct panel-open function.
func _on_shortcut_pressed(id: String) -> void:
	match id:
		"build":    _on_menu_build()
		"crew":     _on_menu_crew()
		"craft":    _on_menu_craft()
		"sell":     _on_menu_sell()
		"skyline":  _on_menu_skyline()
		"upgrades": _on_menu_upgrades()
		"contract": _on_menu_contract()
		"shop":     _on_shop_btn_pressed()
		"missions": _on_menu_missions()
		"toolbox":  _on_menu_toolbox()
		"mine":     _on_menu_mine()

## Open the pin customiser panel (called from the "Edit Quick Bar" button).
func _on_pin_edit_open() -> void:
	_menu_overlay.visible = false
	_update_pin_panel_state()
	_pin_panel.visible = true

## Close the pin customiser panel.
func _on_pin_edit_close() -> void:
	_pin_panel.visible = false

## Toggle a shortcut's pinned state (max 4 pinned at once).
func _on_pin_toggle(id: String) -> void:
	var pins: Array = GameState.pinned_shortcuts
	if id in pins:
		if pins.size() > 1:
			pins.erase(id)
		else:
			_flash_feedback("Keep at least 1 shortcut pinned")
			return
	else:
		if pins.size() >= 4:
			_flash_feedback("Bar full — unpin one first")
			return
		pins.append(id)
	GameState.pinned_shortcuts = pins
	_update_pin_panel_state()
	_rebuild_pin_slots()
	SaveManager.save_game()

## Refresh border colours and "✓ PINNED" labels in the pin panel.
func _update_pin_panel_state() -> void:
	for i in SHORTCUT_DEFS.size():
		var def: Dictionary = SHORTCUT_DEFS[i]
		var pinned: bool = def["id"] in GameState.pinned_shortcuts
		_pin_card_borders[i].color = C_GREEN.darkened(0.3) if pinned else C_BORDER
		_pin_state_labels[i].text  = "✓ PINNED" if pinned else ""

# ── Menu navigation ─────────────────────────────────────────────────────────

func _on_menu_mine() -> void:
	_close_all_panels()

func _on_menu_build() -> void:
	_close_all_panels()
	_build_panel.visible = true
	_update_build_panel()

func _on_menu_craft() -> void:
	_close_all_panels()
	_craft_panel.visible = true
	_update_craft_panel()

func _on_menu_crew() -> void:
	_close_all_panels()
	_crew_panel.visible = true
	_update_crew_panel()

func _on_menu_skyline() -> void:
	_close_all_panels()
	_skyline_panel.visible = true
	_update_skyline_panel()

func _on_menu_sell() -> void:
	_close_all_panels()
	_sell_panel.visible = true
	_update_sell_panel()

func _on_sell_close() -> void:
	_sell_panel.visible = false

func _on_sell_pressed(mat_id: String, qty: int) -> void:
	var have: int  = GameState.materials.get(mat_id, 0)
	if have <= 0:
		return
	var sell_qty: int = have if qty == -1 else mini(qty, have)
	var price: int    = int(SELL_PRICES.get(mat_id, 1))
	var earned: int   = sell_qty * price
	GameState.materials[mat_id] = have - sell_qty
	GameState.cash              += earned
	MissionManager.add_progress("sell_cash", "", earned)
	_update_sell_panel()
	_update_hud()
	_flash_feedback("Sold %d %s  +$ %d" % [sell_qty, mat_id.capitalize(), earned])

func _update_sell_panel() -> void:
	var mats: Array[String] = [
		"timber",    "stone",      "sand",      "steel_ore",
		"clay",      "copper_ore", "limestone", "bauxite",
		"lumber",    "concrete",   "glass",     "steel_beam",
		"brick",     "copper_pipe","plaster",   "aluminium",
	]
	for i in mats.size():
		var have: int  = GameState.materials.get(mats[i], 0)
		var price: int = int(SELL_PRICES.get(mats[i], 1))
		_sell_inv_lbls[i].text  = "Have: %s" % _fmt(have)
		_sell_earn_lbls[i].text = "= $ %s" % _fmt(have * price)

func _on_menu_upgrades() -> void:
	_close_all_panels()
	_upgrades_panel.visible = true
	_update_upgrades_panel()

func _on_upgrades_close() -> void:
	_upgrades_panel.visible = false

func _on_menu_contract() -> void:
	_close_all_panels()
	_contract_panel.visible = true
	_update_contract_panel()

func _on_contract_close() -> void:
	_contract_panel.visible = false

func _on_skyline_new_contract_close() -> void:
	_skyline_panel.visible = false

func _on_new_contract_pressed() -> void:
	# Show prestige confirmation panel
	var rep := _calc_prestige_rep()
	_lbl_prestige_rep_earned.text = "+%d Reputation Points" % rep
	_lbl_prestige_new_rep.text    = "New total: %d RP" % (GameState.reputation_points + rep)
	_prestige_confirm_panel.visible = true

func _on_prestige_confirmed() -> void:
	var rep := _calc_prestige_rep()
	SaveManager.prestige_reset(rep)
	_prestige_confirm_panel.visible = false
	_skyline_panel.visible          = false
	_update_display()
	_update_skyline_panel()
	_update_contract_panel()
	_flash_feedback("New Contract signed!  +%d Rep" % rep)

func _on_prestige_cancel() -> void:
	_prestige_confirm_panel.visible = false

func _on_artifact_buy(artifact_id: String) -> void:
	var a := ArtifactDatabase.get_artifact(artifact_id)
	if a.is_empty():
		return
	var cur_level: int = int(GameState.artifacts.get(artifact_id, 0))
	if cur_level >= int(a["max_level"]):
		return
	var cost: int = ArtifactDatabase.get_cost(artifact_id, cur_level)
	if GameState.reputation_points < cost:
		return
	GameState.reputation_points          -= cost
	GameState.artifacts[artifact_id]      = cur_level + 1
	_update_contract_panel()
	_flash_feedback("%s  Lv.%d!" % [a["name"], cur_level + 1])

func _calc_prestige_rep() -> int:
	return int(round(3.0 * pow(1.084, float(GameState.player_level - 5))))


func _on_upgrade_buy(upgrade_id: String) -> void:
	var u := UpgradeDatabase.get_upgrade(upgrade_id)
	if u.is_empty():
		return
	var cur_level: int = int(GameState.upgrades.get(upgrade_id, 0))
	if cur_level >= int(u["max_level"]):
		return
	if int(u["unlock_level"]) > GameState.player_level:
		return
	var cost := UpgradeDatabase.get_cost(upgrade_id, cur_level)
	# Check and deduct — cash handled separately from materials
	for mat: String in cost:
		var needed: int = int(cost[mat])
		if mat == "cash":
			if GameState.cash < needed:
				return
		else:
			if GameState.materials.get(mat, 0) < needed:
				return
	for mat: String in cost:
		var needed: int = int(cost[mat])
		if mat == "cash":
			GameState.cash -= needed
		else:
			GameState.materials[mat] = GameState.materials.get(mat, 0) - needed
	var new_level: int = cur_level + 1
	GameState.upgrades[upgrade_id] = new_level

	# Extra Node Slot: bump active_node_count, pad arrays, spawn fresh wave
	if upgrade_id == "extra_node_slot":
		GameState.active_node_count = 1 + new_level
		for loc_id: String in GameState.location_nodes.keys():
			var nodes: Array = GameState.location_nodes[loc_id]
			var best := BuildDatabase.get_active_node(loc_id, GameState.player_level)
			while nodes.size() < GameState.active_node_count:
				if best.is_empty(): break
				var hp: float = _random_node_hp(float(best.get("hp", 10)))
				nodes.append({"node_id": best.get("id", ""), "hp": hp, "max_hp": hp})
		_refresh_mine_visuals(GameState.active_location_id)

	_update_upgrades_panel()
	_update_hud()
	_flash_feedback("%s  Lv.%d!" % [u["name"], new_level])

func _update_upgrades_panel() -> void:
	var all_upgrades := UpgradeDatabase.get_all()
	for i in _upgrade_cards.size():
		if i >= all_upgrades.size():
			break
		var u: Dictionary      = all_upgrades[i]
		var card: Dictionary   = _upgrade_cards[i]
		var uid: String        = u["id"]
		var cur_level: int     = int(GameState.upgrades.get(uid, 0))
		var max_level: int     = int(u["max_level"])
		var unlock_level: int  = int(u["unlock_level"])
		var locked: bool       = GameState.player_level < unlock_level
		var maxed: bool        = cur_level >= max_level

		(card["lock"] as ColorRect).visible = locked
		(card["level_lbl"] as Label).text   = "Level %d / %d" % [cur_level, max_level]

		if maxed:
			(card["cost_lbl"] as Label).text    = "MAXED"
			(card["cost_lbl"] as Label).add_theme_color_override("font_color", C_GREEN)
			(card["btn"] as Button).disabled    = true
			(card["btn"] as Button).text        = "Max"
		elif locked:
			(card["cost_lbl"] as Label).text    = "Unlock at player level %d" % unlock_level
			(card["cost_lbl"] as Label).add_theme_color_override("font_color", C_DIM)
			(card["btn"] as Button).disabled    = true
			(card["btn"] as Button).text        = "Locked"
		else:
			var cost := UpgradeDatabase.get_cost(uid, cur_level)
			var parts := PackedStringArray()
			var can_afford := true
			for mat: String in cost:
				var needed: int = int(cost[mat])
				var have: int
				if mat == "cash":
					have = GameState.cash
				else:
					have = GameState.materials.get(mat, 0)
				if have < needed:
					can_afford = false
				parts.append("%s %s" % [_fmt(needed), mat.capitalize()])
			(card["cost_lbl"] as Label).text = "Cost: " + "  ·  ".join(parts)
			(card["cost_lbl"] as Label).add_theme_color_override(
				"font_color", C_GOLD if can_afford else C_RED)
			(card["btn"] as Button).disabled = not can_afford
			(card["btn"] as Button).text     = "Buy"

func _on_shop_btn_pressed() -> void:
	var opening := not _shop_panel.visible
	_close_all_panels()
	if opening:
		_shop_panel.visible = true
		_update_shop_panel()

func _on_build_close() -> void:
	_build_panel.visible = false

func _on_crew_close() -> void:
	_crew_panel.visible = false

func _on_craft_close() -> void:
	_craft_panel.visible = false

func _on_skyline_close() -> void:
	_skyline_panel.visible = false

func _on_shop_close() -> void:
	_shop_panel.visible = false

# ══════════════════════════════════════════════════════════════════════════
# Mine screen logic
# ══════════════════════════════════════════════════════════════════════════

func _on_location_btn(loc_id: String) -> void:
	if GameState.active_location_id == loc_id:
		_loc_picker_panel.visible = false
		return
	GameState.active_location_id = loc_id
	_loc_picker_panel.visible = false
	_update_mine_screen()

func _on_tap_node() -> void:
	var mp := GameState.get_mine_power()
	_apply_node_damage(GameState.active_location_id, float(mp))

func _apply_node_damage(loc_id: String, dmg: float) -> void:
	var nodes: Array = GameState.location_nodes.get(loc_id, [])
	if nodes.is_empty():
		return
	# Damage ALL active (non-cleared) nodes simultaneously.
	var did_break := false
	for i in nodes.size():
		var nd: Dictionary = nodes[i]
		if nd.get("node_id", "") == "": continue   # cleared, waiting for wave
		var new_hp: float = float(nd.get("hp", 0.0)) - dmg
		if new_hp <= 0.0:
			_break_node(loc_id, i)
			did_break = true
		else:
			nd["hp"] = new_hp
			if loc_id == GameState.active_location_id:
				_flash_node_hit(i)
	if loc_id == GameState.active_location_id and not did_break:
		_update_mine_hps(loc_id)

func _break_node(loc_id: String, node_idx: int) -> void:
	var nodes: Array = GameState.location_nodes.get(loc_id, [])
	if node_idx >= nodes.size():
		return
	var nd: Dictionary  = nodes[node_idx]
	var node_id: String = nd.get("node_id", "")
	var node_data  := BuildDatabase.get_node_data(node_id)
	var loc_data   := BuildDatabase.get_location(loc_id)
	var mat: String = loc_data.get("material", "timber")

	var drop_qty: int  = int(node_data.get("drop_qty", 1)) if not node_data.is_empty() else 1
	var xp: float      = float(node_data.get("xp", 2))    if not node_data.is_empty() else 2.0
	var total_drop: int  = drop_qty + GameState.get_drop_bonus()
	var total_xp: float  = xp * GameState.get_xp_mult()

	GameState.materials[mat] = GameState.materials.get(mat, 0) + total_drop
	MissionManager.add_progress("collect_mat", mat, total_drop)
	MissionManager.add_progress("break_nodes", "", 1)
	_gain_xp(total_xp)

	if loc_id == GameState.active_location_id:
		_flash_feedback("+%d %s   +%.0f XP" % [total_drop, mat.capitalize(), total_xp])

	# Mark slot as cleared (empty) — hide it
	nodes[node_idx] = {"node_id": "", "hp": 0.0, "max_hp": 0.0}
	if loc_id == GameState.active_location_id and node_idx < _node_visuals.size():
		_node_visuals[node_idx]["container"].visible = false

	# Check if all slots are cleared — if so, spawn the next wave
	var all_clear := true
	for slot: Dictionary in nodes:
		if slot.get("node_id", "") != "":
			all_clear = false
			break
	if all_clear:
		_spawn_wave(loc_id)

	_update_hud()

## Spawn a fresh wave of nodes for a location with randomised HP.
func _spawn_wave(loc_id: String) -> void:
	var nodes: Array = GameState.location_nodes.get(loc_id, [])
	var best_node := BuildDatabase.get_active_node(loc_id, GameState.player_level)
	if best_node.is_empty():
		return
	var base_hp: float = float(best_node.get("hp", 10))
	for i in nodes.size():
		var hp: float = _random_node_hp(base_hp)
		nodes[i] = {"node_id": best_node.get("id", ""), "hp": hp, "max_hp": hp}
		# Reset position so each node gets a fresh scatter position
		if i < _node_visuals.size():
			_node_visuals[i]["pos"] = Vector2(-1.0, -1.0)
	if loc_id == GameState.active_location_id:
		_refresh_mine_visuals(loc_id)

## Returns a HP value in the range [base * 0.8, base * 1.2], rounded to int.
func _random_node_hp(base_hp: float) -> float:
	return roundf(base_hp * randf_range(0.8, 1.2))

func _gain_xp(amount: float) -> void:
	GameState.player_xp += amount
	var needed := BuildDatabase.get_xp_needed(GameState.player_level)
	while GameState.player_xp >= needed:
		GameState.player_xp -= needed
		GameState.player_level += 1
		needed = BuildDatabase.get_xp_needed(GameState.player_level)
		_on_level_up()
	_update_xp_bar()

func _on_level_up() -> void:
	# Upgrade any locations that now have a better node tier available.
	# Spawn a fresh wave for each so HP is re-randomised at the new tier.
	for loc_id: String in GameState.location_nodes.keys():
		var best := BuildDatabase.get_active_node(loc_id, GameState.player_level)
		if best.is_empty(): continue
		var nodes: Array = GameState.location_nodes[loc_id]
		var needs_upgrade := false
		for nd: Dictionary in nodes:
			if nd.get("node_id", "") != best.get("id", ""):
				needs_upgrade = true
				break
		if needs_upgrade:
			_spawn_wave(loc_id)
	_flash_feedback("LEVEL UP!   Lv. %d" % GameState.player_level)
	_update_hud()

# ══════════════════════════════════════════════════════════════════════════
# Worker tick
# ══════════════════════════════════════════════════════════════════════════

func _tick_workers(delta: float) -> void:
	if GameState.crew.is_empty():
		return
	for loc_id: String in BuildDatabase.LOCATION_ORDER:
		var rate := _worker_damage_rate(loc_id)
		if rate <= 0.0:
			continue
		_worker_dmg_accum[loc_id] = _worker_dmg_accum.get(loc_id, 0.0) + rate * delta
		if _worker_dmg_accum[loc_id] >= 1.0:
			var dmg := int(_worker_dmg_accum[loc_id])
			_worker_dmg_accum[loc_id] -= float(dmg)
			_apply_node_damage(loc_id, float(dmg))

func _worker_damage_rate(loc_id: String) -> float:
	var rate := 0.0
	for member: Dictionary in GameState.crew:
		if member.get("location_id", "") == loc_id:
			rate += float(member.get("base_speed_bonus", 0.1)) \
				* float(member.get("level", 1)) * 4.0
	# Apply Quick Crew upgrade multiplier
	return rate * GameState.get_worker_rate_mult()

# ══════════════════════════════════════════════════════════════════════════
# Build panel logic
# ══════════════════════════════════════════════════════════════════════════

func _on_start_stage_pressed() -> void:
	var stage := BuildDatabase.get_current_stage()
	if not stage:
		return
	# Check we have all required materials
	for mat: String in stage.required_materials:
		var need: int = int(stage.required_materials[mat])
		if GameState.materials.get(mat, 0) < need:
			return
	# Consume materials upfront
	for mat: String in stage.required_materials:
		var need: int = int(stage.required_materials[mat])
		GameState.materials[mat] = GameState.materials.get(mat, 0) - need
	# Start the stage
	GameState.current_building["stage_started"]  = true
	GameState.current_building["stage_progress"] = 0.0
	_update_build_panel()

func _on_tap_build() -> void:
	if not GameState.current_building.get("stage_started", false):
		return
	var stage := BuildDatabase.get_current_stage()
	if not stage:
		return

	# Build effort = sum of required quantities; each tap contributes build_power / effort
	var effort := 0
	for v in stage.required_materials.values():
		effort += int(v)
	effort = max(effort, 1)
	var bp: int = max(GameState.get_build_power(), 1)
	var inc := (float(bp) / float(effort)) * GameState.get_build_progress_mult()

	var progress: float = float(GameState.current_building.get("stage_progress", 0.0)) + inc
	GameState.current_building["stage_progress"] = minf(progress, 1.0)

	_flash_build_feedback("+%d BP" % bp)

	if progress >= 1.0:
		_complete_stage()
	else:
		_update_build_panel()

func _on_build_panel_opened() -> void:
	_update_build_panel()

# ══════════════════════════════════════════════════════════════════════════
# Stage / building logic
# ══════════════════════════════════════════════════════════════════════════

func _complete_stage() -> void:
	var stage := BuildDatabase.get_current_stage()
	if not stage:
		return

	var reward: int = int(float(25 + stage.stage_order * 10) * GameState.get_stage_cash_mult())
	GameState.cash += reward
	GameState.gems += 1
	MissionManager.add_progress("complete_stages", "", 1)

	var new_idx: int = int(GameState.current_building.get("stage_index", 0)) + 1
	GameState.current_building["stage_index"]   = new_idx
	GameState.current_building["stage_started"]  = false
	GameState.current_building["stage_progress"] = 0.0

	var tier := BuildDatabase.get_tier(GameState.current_building.get("tier_id", "shed"))
	if tier and new_idx >= tier.stages.size():
		_complete_building()
	else:
		_flash_feedback("Stage done!  +%d cash" % reward)
		_update_build_panel()
		_update_hud()

func _complete_building() -> void:
	var tier_id: String = GameState.current_building.get("tier_id", "shed")
	GameState.skyline.append(tier_id)
	GameState.cash += 100
	GameState.gems += 5

	var next_id := BuildDatabase.get_next_tier_id(tier_id)

	if next_id == "":
		# Max tier — loop on current
		GameState.current_building = {
			"tier_id": tier_id, "stage_index": 0,
			"stage_progress": 0.0, "stage_started": false
		}
		_flash_feedback("Building complete!  +100 cash\nSkyline: %d" % GameState.skyline.size())
		_update_build_panel()
		_update_hud()
		return

	var next_tier := BuildDatabase.get_tier(next_id)
	var bp        := GameState.get_build_power()

	if next_tier and bp >= next_tier.build_power_required:
		GameState.current_building = {
			"tier_id": next_id, "stage_index": 0,
			"stage_progress": 0.0, "stage_started": false
		}
		_flash_feedback("Building complete!  +100 cash\nNow: %s" % next_tier.display_name)
		_update_build_panel()
		_update_hud()
	else:
		GameState.current_building = {
			"tier_id": tier_id, "stage_index": 0,
			"stage_progress": 0.0, "stage_started": false
		}
		_flash_feedback("Building complete!  +100 cash")
		_update_build_panel()
		_update_hud()
		_show_wall_panel(next_id)

# ══════════════════════════════════════════════════════════════════════════
# Crew panel interaction
# ══════════════════════════════════════════════════════════════════════════

func _on_hire_pressed(id: String) -> void:
	var template := _crew_template(id)
	if not template or _is_hired(id) or GameState.cash < template.hire_cost:
		return
	GameState.cash -= template.hire_cost
	GameState.crew.append({
		"id":               id,
		"display_name":     template.display_name,
		"level":            1,
		"material_type":    template.material_type,
		"base_speed_bonus": template.base_speed_bonus,
		"location_id":      template.location_id,
	})
	_update_crew_panel()
	_update_hud()

func _on_levelup_pressed(id: String) -> void:
	var member   := _crew_member_dict(id)
	var template := _crew_template(id)
	if member.is_empty() or not template:
		return
	var level: int = int(member.get("level", 1))
	var cost: int  = template.hire_cost * level
	if GameState.cash < cost:
		return
	GameState.cash -= cost
	member["level"] = level + 1
	_update_crew_panel()
	_update_hud()

func _update_crew_panel() -> void:
	_lbl_crew_bp.text = "Build Power: %d" % GameState.get_build_power()
	var templates := BuildDatabase.get_hireable_crew()
	var fill_w    := float(SCREEN_W - 28)
	const MAX_LVL  := 10
	for i in templates.size():
		var tmpl   := templates[i]
		var hired  := _is_hired(tmpl.id)
		var member := _crew_member_dict(tmpl.id)
		var level: int = int(member.get("level", 1)) if hired else 1

		var rate: float = tmpl.base_speed_bonus * float(level)
		_crew_rate_labels[i].text = ("%.2f %s/s  (Lv.%d)" \
			% [rate, tmpl.material_type.capitalize(), level]) if hired else \
			("%.1f %s/s at Lv.1" % [tmpl.base_speed_bonus, tmpl.material_type.capitalize()])

		_crew_level_labels[i].text = ("Level %d" % level) if hired else "Not hired"
		_crew_level_labels[i].add_theme_color_override(
			"font_color", C_TEXT if hired else C_DIM)

		_crew_hire_btns[i].visible   = not hired
		_crew_hire_btns[i].disabled  = GameState.cash < tmpl.hire_cost

		var lvlup_cost: int           = tmpl.hire_cost * level
		_crew_levelup_btns[i].visible  = hired
		_crew_levelup_btns[i].text     = "Upgrade  (%s cash)" % _fmt(lvlup_cost)
		_crew_levelup_btns[i].disabled = GameState.cash < lvlup_cost

		_crew_progress_fills[i].size.x = fill_w * minf(float(level) / float(MAX_LVL), 1.0)

		# Location label + move button
		if i < _crew_loc_labels.size():
			if hired:
				var cur_loc: String = member.get("location_id", tmpl.location_id)
				var ld := BuildDatabase.get_location(cur_loc)
				var col := _mat_color(ld.get("material", tmpl.material_type))
				_crew_loc_labels[i].text = ld.get("display_name", cur_loc)
				_crew_loc_labels[i].add_theme_color_override("font_color", col)
			else:
				var ld := BuildDatabase.get_location(tmpl.location_id)
				_crew_loc_labels[i].text = ld.get("display_name", tmpl.location_id)
				_crew_loc_labels[i].add_theme_color_override("font_color", _mat_color(tmpl.material_type))
		if i < _crew_move_btns.size():
			_crew_move_btns[i].visible = hired

# ── Wall panel interaction ──────────────────────────────────────────────────
func _on_wall_keep_pressed() -> void:
	_wall_panel.visible = false

func _on_wall_crew_pressed() -> void:
	_wall_panel.visible = false
	_crew_panel.visible = true
	_update_crew_panel()

func _show_wall_panel(blocked_tier_id: String) -> void:
	var tier := BuildDatabase.get_tier(blocked_tier_id)
	if not tier:
		return
	var bp       := GameState.get_build_power()
	var required := tier.build_power_required
	_lbl_wall_title.text  = "BUILD POWER TOO LOW"
	_lbl_wall_detail.text = (
		"%s requires Build Power %d\n\nYour current Build Power: %d\n\n" \
		+ "Hire or level up your Crew to break through!"
	) % [tier.display_name, required, bp]
	_wall_panel.visible = true

# ── Skyline panel interaction ───────────────────────────────────────────────
func _update_skyline_panel() -> void:
	for child in _skyline_list_box.get_children():
		child.queue_free()

	if GameState.skyline.is_empty():
		var empty_lbl     := Label.new()
		empty_lbl.text     = "Nothing built yet.\nComplete a building to see it here."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.custom_minimum_size  = Vector2(SCREEN_W, 80)
		empty_lbl.add_theme_color_override("font_color", C_DIM)
		_skyline_list_box.add_child(empty_lbl)
		return

	for entry: String in GameState.skyline:
		var tier := BuildDatabase.get_tier(entry)
		var row  := HBoxContainer.new()
		row.custom_minimum_size = Vector2(SCREEN_W, 72)
		_skyline_list_box.add_child(row)

		var swatch      := ColorRect.new()
		swatch.color     = _tier_colour(entry)
		swatch.custom_minimum_size = Vector2(56, 56)
		row.add_child(swatch)

		var spacer      := Control.new()
		spacer.custom_minimum_size = Vector2(12, 0)
		row.add_child(spacer)

		var lbl      := Label.new()
		lbl.text      = tier.display_name if tier else entry
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size  = Vector2(580, 56)
		lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(lbl)

# ── Craft panel interaction ─────────────────────────────────────────────────
func _on_craft_one(raw_id: String, ref_id: String, cost: int) -> void:
	if GameState.materials.get(raw_id, 0) < cost:
		return
	GameState.materials[raw_id] = GameState.materials.get(raw_id, 0) - cost
	# Double Craft chance
	var yield_qty := 2 if randf() < GameState.get_double_craft_chance() else 1
	GameState.materials[ref_id] = GameState.materials.get(ref_id, 0) + yield_qty
	MissionManager.add_progress("craft_items", "", yield_qty)
	_update_craft_panel()

func _on_craft_all(raw_id: String, ref_id: String, cost: int) -> void:
	var have: int = GameState.materials.get(raw_id, 0)
	var made: int = have / cost
	if made <= 0:
		return
	GameState.materials[raw_id] = have - made * cost
	# Apply Double Craft chance per craft (approximated as average for bulk)
	var double_chance := GameState.get_double_craft_chance()
	var bonus_yield: int = 0
	for _i in made:
		if randf() < double_chance:
			bonus_yield += 1
	made += bonus_yield
	GameState.materials[ref_id] = GameState.materials.get(ref_id, 0) + made
	MissionManager.add_progress("craft_items", "", made)
	_update_craft_panel()

func _update_craft_panel() -> void:
	var inv_mats:  Array[String] = ["timber", "stone", "lumber", "concrete"]
	var inv_names: Array[String] = ["Timber", "Stone", "Lumber", "Concrete"]
	for i in inv_mats.size():
		_craft_inv_lbls[i].text = "%s\n%s" % [inv_names[i], _fmt(GameState.materials.get(inv_mats[i], 0))]

	var raw_ids:   Array[String] = ["timber", "stone"]
	var ref_ids:   Array[String] = ["lumber", "concrete"]
	var costs:     Array[int]    = [3, 3]
	for i in 2:
		var have: int     = GameState.materials.get(raw_ids[i], 0)
		var can_make: int = have / costs[i]
		_craft_yield_lbls[i].text  = "Will make: %s" % _fmt(can_make)
		_craft1_btns[i].disabled   = have < costs[i]
		_craftall_btns[i].disabled = have < costs[i]

# ── Shop panel interaction ──────────────────────────────────────────────────
func _update_shop_panel() -> void:
	_lbl_shop_gems.text      = "◆ %d  Gems" % GameState.gems
	_btn_stage_skip.disabled = GameState.gems < 10 or \
		not GameState.current_building.get("stage_started", false) or \
		BuildDatabase.get_current_stage() == null

func _on_stage_skip_pressed() -> void:
	if not GameState.current_building.get("stage_started", false):
		return
	var stage := BuildDatabase.get_current_stage()
	if not stage or GameState.gems < 10:
		return
	GameState.gems -= 10
	GameState.current_building["stage_progress"] = 1.0
	_shop_panel.visible = false
	_complete_stage()

# ══════════════════════════════════════════════════════════════════════════
# Missions panel
# ══════════════════════════════════════════════════════════════════════════

func _build_missions_panel() -> void:
	_missions_panel         = CanvasLayer.new()
	_missions_panel.name    = "MissionsPanel"
	_missions_panel.layer   = 22
	_missions_panel.visible = false
	add_child(_missions_panel)

	var bg      := ColorRect.new()
	bg.color     = C_PANEL
	bg.position  = Vector2.ZERO
	bg.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H)
	_missions_panel.add_child(bg)

	var close_btn := _build_panel_header(_missions_panel, "MISSIONS", C_GOLD)
	close_btn.pressed.connect(func() -> void: _missions_panel.visible = false)

	# Scrollable content
	var scroll      := ScrollContainer.new()
	scroll.position  = Vector2(0, 82)
	scroll.size      = Vector2(SCREEN_W, SCREEN_H - BOTTOM_BAR_H - 82)
	_missions_panel.add_child(scroll)

	var vbox      := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.custom_minimum_size = Vector2(SCREEN_W, 0)
	scroll.add_child(vbox)

	# ── Daily section ─────────────────────────────────────────────────────
	var daily_hdr := _make_mission_section_header(vbox, "DAILY MISSIONS", C_GOLD)
	_lbl_daily_countdown = daily_hdr

	for i in MissionManager.DAILY_COUNT:
		_mission_card_refs.append(_make_mission_card(vbox, true, i))

	# ── Weekly section ────────────────────────────────────────────────────
	var weekly_hdr := _make_mission_section_header(vbox, "WEEKLY MISSIONS", C_GEM)
	_lbl_weekly_countdown = weekly_hdr

	for i in MissionManager.WEEKLY_COUNT:
		_mission_card_refs.append(_make_mission_card(vbox, false, i))

	# Bottom padding
	var pad      := Control.new()
	pad.custom_minimum_size = Vector2(SCREEN_W, 24)
	vbox.add_child(pad)

## Returns the countdown Label so we can store it.
func _make_mission_section_header(parent: VBoxContainer, title: String, accent: Color) -> Label:
	var hdr      := ColorRect.new()
	hdr.color     = Color(0.07, 0.08, 0.14)
	hdr.custom_minimum_size = Vector2(SCREEN_W, 56)
	parent.add_child(hdr)

	var strip      := ColorRect.new()
	strip.color     = accent
	strip.position  = Vector2(0, 0)
	strip.size      = Vector2(SCREEN_W, 3)
	hdr.add_child(strip)

	var title_lbl      := Label.new()
	title_lbl.text      = title
	title_lbl.position  = Vector2(16, 8)
	title_lbl.size      = Vector2(360, 40)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", accent)
	hdr.add_child(title_lbl)

	var countdown_lbl      := Label.new()
	countdown_lbl.text      = ""
	countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	countdown_lbl.position  = Vector2(0, 18)
	countdown_lbl.size      = Vector2(SCREEN_W - 16, 24)
	countdown_lbl.add_theme_font_size_override("font_size", 13)
	countdown_lbl.add_theme_color_override("font_color", C_DIM)
	hdr.add_child(countdown_lbl)

	return countdown_lbl

## Build one mission card placeholder; returns refs dict so _update can fill it.
func _make_mission_card(parent: VBoxContainer, is_daily: bool, slot_idx: int) -> Dictionary:
	var card      := ColorRect.new()
	card.color     = C_CARD
	card.custom_minimum_size = Vector2(SCREEN_W, 110)
	parent.add_child(card)

	# Left accent strip (filled in during update)
	var strip      := ColorRect.new()
	strip.color     = C_BORDER
	strip.position  = Vector2(0, 0)
	strip.size      = Vector2(5, 110)
	card.add_child(strip)

	# Separator line at bottom
	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.position  = Vector2(5, 108)
	sep.size      = Vector2(SCREEN_W - 5, 2)
	card.add_child(sep)

	# Mission label (2 lines)
	var desc_lbl      := Label.new()
	desc_lbl.text      = "…"
	desc_lbl.position  = Vector2(18, 10)
	desc_lbl.size      = Vector2(SCREEN_W - 200, 42)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", C_TEXT)
	card.add_child(desc_lbl)

	# Reward label
	var reward_lbl      := Label.new()
	reward_lbl.text      = ""
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward_lbl.position  = Vector2(SCREEN_W - 210, 10)
	reward_lbl.size      = Vector2(194, 30)
	reward_lbl.add_theme_font_size_override("font_size", 14)
	reward_lbl.add_theme_color_override("font_color", C_GOLD)
	card.add_child(reward_lbl)

	# Progress bar background
	var bar_bg      := ColorRect.new()
	bar_bg.color     = C_BORDER
	bar_bg.position  = Vector2(18, 57)
	bar_bg.size      = Vector2(SCREEN_W - 180, 14)
	card.add_child(bar_bg)

	# Progress bar fill
	var bar_fill      := ColorRect.new()
	bar_fill.color     = C_GOLD
	bar_fill.position  = Vector2(18, 57)
	bar_fill.size      = Vector2(0, 14)
	card.add_child(bar_fill)

	# Progress text
	var prog_lbl      := Label.new()
	prog_lbl.text      = "0 / 0"
	prog_lbl.position  = Vector2(18, 73)
	prog_lbl.size      = Vector2(SCREEN_W - 180, 22)
	prog_lbl.add_theme_font_size_override("font_size", 12)
	prog_lbl.add_theme_color_override("font_color", C_DIM)
	card.add_child(prog_lbl)

	# Claim button
	var claim_btn      := Button.new()
	claim_btn.text      = "CLAIM"
	claim_btn.position  = Vector2(SCREEN_W - 158, 52)
	claim_btn.size      = Vector2(142, 46)
	claim_btn.disabled  = true
	card.add_child(claim_btn)
	var refs := {
		"desc_lbl":   desc_lbl,
		"reward_lbl": reward_lbl,
		"bar_fill":   bar_fill,
		"bar_bg":     bar_bg,
		"prog_lbl":   prog_lbl,
		"claim_btn":  claim_btn,
		"strip":      strip,
		"is_daily":   is_daily,
		"slot_idx":   slot_idx,
		"mission_id": "",
	}
	claim_btn.pressed.connect(func() -> void: _on_mission_claim(refs))
	return refs

func _update_missions_panel() -> void:
	if not _missions_panel:
		return

	# Rebuild card refs list if missions were regenerated (id changed)
	var all_missions: Array = GameState.daily_missions + GameState.weekly_missions
	for i in _mission_card_refs.size():
		if i >= all_missions.size():
			break
		var m: Dictionary = all_missions[i]
		var refs: Dictionary = _mission_card_refs[i]

		# Update mission_id for claim callback
		refs["mission_id"] = m["id"]

		# Accent colour by type
		var accent: Color = C_GOLD
		match m["type"]:
			"break_nodes":     accent = C_STONE
			"craft_items":     accent = C_LUMBER
			"complete_stages": accent = C_ACCENT
			"sell_cash":       accent = C_GEM
			"collect_mat":     accent = _mat_color(m.get("mat", ""))
		refs["strip"].color = accent

		refs["desc_lbl"].text   = MissionManager.mission_label(m)
		refs["reward_lbl"].text = MissionManager.reward_label(m)

		var prog: int   = int(m["progress"])
		var tgt: int    = int(m["target"])
		var ratio: float = float(prog) / float(maxi(tgt, 1))
		var bar_w: float = refs["bar_bg"].size.x * ratio
		refs["bar_fill"].size  = Vector2(bar_w, 14)
		refs["bar_fill"].color = C_GREEN if ratio >= 1.0 else accent
		refs["prog_lbl"].text  = "%s / %s" % [_fmt(prog), _fmt(tgt)]

		var done: bool = prog >= tgt
		refs["claim_btn"].disabled = not done or bool(m.get("claimed", false))
		refs["claim_btn"].text     = "✓ DONE" if bool(m.get("claimed", false)) else "CLAIM"

	# Countdown labels
	if _lbl_daily_countdown:
		_lbl_daily_countdown.text = "Resets in %s" % MissionManager.time_until_string(GameState.daily_reset_at)
	if _lbl_weekly_countdown:
		_lbl_weekly_countdown.text = "Resets in %s" % MissionManager.time_until_string(GameState.weekly_reset_at)

func _on_mission_claim(refs: Dictionary) -> void:
	var mid: String = refs["mission_id"]
	if MissionManager.try_claim(mid):
		_update_hud()
		_flash_feedback("Mission complete! Reward claimed.")

func _on_menu_missions() -> void:
	_close_all_panels()
	_update_missions_panel()
	_missions_panel.visible = true

# ══════════════════════════════════════════════════════════════════════════
# Toolbox Panel
# ══════════════════════════════════════════════════════════════════════════

func _build_toolbox_panel() -> void:
	# ── Layout constants (bottom sheet — mine area stays visible above) ────
	# Sheet covers bottom ~42% of screen: 3 rows of items + detail + header
	const COLS      := 3
	const CELL_W    := 240
	const CELL_H    := 80
	const ITEMS_H   := CELL_H * 3                          # 240 (3 rows)
	const HEADER_H  := 44
	const DETAIL_H  := 196
	const SHEET_H   : int = HEADER_H + ITEMS_H + DETAIL_H # 480
	const SHEET_Y   : int = SCREEN_H - BOTTOM_BAR_H - SHEET_H  # 700
	const C_ORANGE  := Color(0.90, 0.50, 0.20)

	_toolbox_panel         = CanvasLayer.new()
	_toolbox_panel.name    = "ToolboxPanel"
	_toolbox_panel.layer   = 23
	_toolbox_panel.visible = false
	add_child(_toolbox_panel)

	# Semi-transparent scrim above sheet (tap to close)
	var scrim      := ColorRect.new()
	scrim.color     = Color(0.0, 0.0, 0.0, 0.45)
	scrim.position  = Vector2(0, MINE_Y)
	scrim.size      = Vector2(SCREEN_W, SHEET_Y - MINE_Y)
	_toolbox_panel.add_child(scrim)
	var scrim_btn      := Button.new()
	scrim_btn.flat      = true
	scrim_btn.position  = Vector2(0, MINE_Y)
	scrim_btn.size      = Vector2(SCREEN_W, SHEET_Y - MINE_Y)
	_toolbox_panel.add_child(scrim_btn)
	scrim_btn.pressed.connect(func() -> void: _toolbox_panel.visible = false)

	# Sheet background
	var bg      := ColorRect.new()
	bg.color     = Color(0.09, 0.10, 0.15, 0.98)
	bg.position  = Vector2(0, SHEET_Y)
	bg.size      = Vector2(SCREEN_W, SHEET_H)
	_toolbox_panel.add_child(bg)

	# Orange top strip
	var top_strip      := ColorRect.new()
	top_strip.color     = C_ORANGE
	top_strip.position  = Vector2(0, SHEET_Y)
	top_strip.size      = Vector2(SCREEN_W, 3)
	_toolbox_panel.add_child(top_strip)

	# Drag handle
	var handle      := ColorRect.new()
	handle.color     = C_ORANGE.darkened(0.3)
	handle.position  = Vector2(SCREEN_W / 2 - 24, SHEET_Y + 8)
	handle.size      = Vector2(48, 4)
	_toolbox_panel.add_child(handle)

	# Title
	var title      := Label.new()
	title.text      = "TOOLBOX"
	title.position  = Vector2(16, SHEET_Y + 6)
	title.size      = Vector2(400, HEADER_H - 6)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_ORANGE)
	_toolbox_panel.add_child(title)

	# Close button
	var close_btn      := Button.new()
	close_btn.flat      = true
	close_btn.text      = "✕"
	close_btn.position  = Vector2(SCREEN_W - 56, SHEET_Y + 4)
	close_btn.size      = Vector2(48, HEADER_H - 4)
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", C_DIM)
	_toolbox_panel.add_child(close_btn)
	close_btn.pressed.connect(func() -> void: _toolbox_panel.visible = false)

	# Separator below header
	var sep      := ColorRect.new()
	sep.color     = C_BORDER
	sep.position  = Vector2(0, SHEET_Y + HEADER_H - 1)
	sep.size      = Vector2(SCREEN_W, 1)
	_toolbox_panel.add_child(sep)

	# ── Item grid ─────────────────────────────────────────────────────────
	var GRID_TOP : int = SHEET_Y + HEADER_H
	var items        := ToolboxDatabase.get_all()
	_toolbox_cells.clear()
	for idx: int in items.size():
		var item : Dictionary = items[idx]
		var col  := idx % COLS
		var row  := idx / COLS
		_make_toolbox_cell(_toolbox_panel, item, idx,
			Vector2(col * CELL_W, GRID_TOP + row * CELL_H), CELL_W, CELL_H)

	# ── Detail section ────────────────────────────────────────────────────
	var DET_Y : int = GRID_TOP + ITEMS_H

	var det_sep      := ColorRect.new()
	det_sep.color     = C_BORDER
	det_sep.position  = Vector2(0, DET_Y)
	det_sep.size      = Vector2(SCREEN_W, 1)
	_toolbox_panel.add_child(det_sep)

	var det_bg      := ColorRect.new()
	det_bg.color     = Color(0.07, 0.08, 0.12)
	det_bg.position  = Vector2(0, DET_Y + 1)
	det_bg.size      = Vector2(SCREEN_W, DETAIL_H - 1)
	_toolbox_panel.add_child(det_bg)

	_lbl_tb_item_name = Label.new()
	_lbl_tb_item_name.text      = "Select an item"
	_lbl_tb_item_name.position  = Vector2(16, DET_Y + 8)
	_lbl_tb_item_name.size      = Vector2(SCREEN_W - 32, 28)
	_lbl_tb_item_name.add_theme_font_size_override("font_size", 16)
	_lbl_tb_item_name.add_theme_color_override("font_color", Color.WHITE)
	_toolbox_panel.add_child(_lbl_tb_item_name)

	_lbl_tb_item_desc = Label.new()
	_lbl_tb_item_desc.text      = ""
	_lbl_tb_item_desc.position  = Vector2(16, DET_Y + 38)
	_lbl_tb_item_desc.size      = Vector2(SCREEN_W - 32, 36)
	_lbl_tb_item_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_tb_item_desc.add_theme_font_size_override("font_size", 13)
	_lbl_tb_item_desc.add_theme_color_override("font_color", C_DIM)
	_toolbox_panel.add_child(_lbl_tb_item_desc)

	_lbl_tb_item_count = Label.new()
	_lbl_tb_item_count.text      = ""
	_lbl_tb_item_count.position  = Vector2(16, DET_Y + 76)
	_lbl_tb_item_count.size      = Vector2(SCREEN_W - 32, 22)
	_lbl_tb_item_count.add_theme_font_size_override("font_size", 13)
	_lbl_tb_item_count.add_theme_color_override("font_color", C_TEXT)
	_toolbox_panel.add_child(_lbl_tb_item_count)

	_btn_tb_use = Button.new()
	_btn_tb_use.text     = "USE"
	_btn_tb_use.position = Vector2(12, DET_Y + DETAIL_H - 58)
	_btn_tb_use.size     = Vector2(336, 48)
	_btn_tb_use.add_theme_font_size_override("font_size", 16)
	_btn_tb_use.disabled = true
	_toolbox_panel.add_child(_btn_tb_use)
	_btn_tb_use.pressed.connect(_on_use_item)

	_btn_tb_buy = Button.new()
	_btn_tb_buy.text     = "BUY  ◆1"
	_btn_tb_buy.position = Vector2(360, DET_Y + DETAIL_H - 58)
	_btn_tb_buy.size     = Vector2(348, 48)
	_btn_tb_buy.add_theme_font_size_override("font_size", 16)
	_btn_tb_buy.disabled = true
	_toolbox_panel.add_child(_btn_tb_buy)
	_btn_tb_buy.pressed.connect(_on_buy_item)


func _make_toolbox_cell(parent: Node, item: Dictionary, _idx: int,
		pos: Vector2, w: int, h: int) -> void:
	# Compact 80px cell: 36×36 symbol square + name/cost to the right + count badge
	var rarity_col : Color  = ToolboxDatabase.rarity_color(item.get("rarity", "common"))
	var item_col   : Color  = item.get("color", Color.WHITE)
	var item_id    : String = item.get("id", "")

	var cell_bg      := ColorRect.new()
	cell_bg.color     = C_CARD
	cell_bg.position  = pos + Vector2(1, 1)
	cell_bg.size      = Vector2(w - 2, h - 2)
	parent.add_child(cell_bg)

	# Rarity top strip
	var border      := ColorRect.new()
	border.color     = rarity_col
	border.position  = pos + Vector2(1, 1)
	border.size      = Vector2(w - 2, 3)
	parent.add_child(border)

	# Symbol square (centred vertically in cell)
	var SYM  := 38
	var sy   := int(pos.y) + (h - SYM) / 2
	var sym_bg      := ColorRect.new()
	sym_bg.color     = item_col.darkened(0.55)
	sym_bg.position  = Vector2(pos.x + 10, sy)
	sym_bg.size      = Vector2(SYM, SYM)
	parent.add_child(sym_bg)

	var sym_lbl      := Label.new()
	sym_lbl.text      = item.get("symbol", "?")
	sym_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	sym_lbl.position  = Vector2(pos.x + 10, sy)
	sym_lbl.size      = Vector2(SYM, SYM)
	sym_lbl.add_theme_font_size_override("font_size", 18)
	sym_lbl.add_theme_color_override("font_color", item_col)
	parent.add_child(sym_lbl)

	# Name (top half of right area)
	var name_lbl      := Label.new()
	name_lbl.text      = item.get("name", "")
	name_lbl.position  = pos + Vector2(56, 12)
	name_lbl.size      = Vector2(w - 66, 26)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	parent.add_child(name_lbl)

	# Cost (below name)
	var cost_lbl      := Label.new()
	cost_lbl.text      = "◆%d" % item.get("gem_cost", 1)
	cost_lbl.position  = pos + Vector2(56, 40)
	cost_lbl.size      = Vector2(w - 66, 20)
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color", C_GEM)
	parent.add_child(cost_lbl)

	# Count badge (bottom-right)
	var badge_bg      := ColorRect.new()
	badge_bg.color     = Color(0.08, 0.10, 0.16)
	badge_bg.position  = pos + Vector2(w - 36, h - 24)
	badge_bg.size      = Vector2(32, 20)
	parent.add_child(badge_bg)

	var count_lbl      := Label.new()
	count_lbl.text      = "0"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.position  = pos + Vector2(w - 36, h - 24)
	count_lbl.size      = Vector2(32, 20)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.add_theme_color_override("font_color", C_GOLD)
	parent.add_child(count_lbl)

	# Cell separator line (right edge)
	var divider      := ColorRect.new()
	divider.color     = C_BORDER
	divider.position  = pos + Vector2(w - 1, 0)
	divider.size      = Vector2(1, h)
	parent.add_child(divider)

	# Bottom separator line
	var divider_b      := ColorRect.new()
	divider_b.color     = C_BORDER
	divider_b.position  = pos + Vector2(0, h - 1)
	divider_b.size      = Vector2(w, 1)
	parent.add_child(divider_b)

	# Tap button
	var btn      := Button.new()
	btn.flat      = true
	btn.position  = pos
	btn.size      = Vector2(w, h)
	parent.add_child(btn)
	btn.pressed.connect(func() -> void:
		_toolbox_selected = item_id
		_update_toolbox_panel()
	)

	_toolbox_cells.append({
		"item_id":   item_id,
		"cell_bg":   cell_bg,
		"count_lbl": count_lbl,
	})


func _update_toolbox_panel() -> void:
	for ref: Dictionary in _toolbox_cells:
		var iid : String    = ref["item_id"]
		var cnt : int       = int(GameState.inventory.get(iid, 0))
		ref["count_lbl"].text = str(cnt)
		var bg  : ColorRect = ref["cell_bg"]
		bg.color = Color(0.20, 0.22, 0.30) if iid == _toolbox_selected else C_CARD

	if _toolbox_selected.is_empty():
		_lbl_tb_item_name.text  = "Select an item"
		_lbl_tb_item_desc.text  = ""
		_lbl_tb_item_count.text = ""
		_btn_tb_use.disabled    = true
		_btn_tb_buy.disabled    = true
		return

	var item := ToolboxDatabase.get_item(_toolbox_selected)
	if item.is_empty():
		return

	var owned : int = int(GameState.inventory.get(_toolbox_selected, 0))
	var cost  : int = int(item.get("gem_cost", 1))

	_lbl_tb_item_name.text = item.get("name", "")
	_lbl_tb_item_name.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	_lbl_tb_item_desc.text  = item.get("desc", "")
	_lbl_tb_item_count.text = "Owned: %d" % owned

	_btn_tb_use.text     = "USE  (%d owned)" % owned
	_btn_tb_use.disabled = owned <= 0

	_btn_tb_buy.text     = "BUY  ◆%d" % cost
	_btn_tb_buy.disabled = GameState.gems < cost


func _on_use_item() -> void:
	if _toolbox_selected.is_empty(): return
	var owned : int = int(GameState.inventory.get(_toolbox_selected, 0))
	if owned <= 0: return

	var item := ToolboxDatabase.get_item(_toolbox_selected)
	if item.is_empty(): return

	GameState.inventory[_toolbox_selected] = owned - 1

	var effect   : String = item.get("effect", "")
	var duration : int    = int(item.get("duration", 0))
	var mult     : float  = float(item.get("mult", 1.0))
	var flat     : int    = int(item.get("flat", 0))

	if effect == "instant_wave":
		var loc_id : String = GameState.active_location_id
		var nodes  : Array  = GameState.location_nodes.get(loc_id, [])
		for i: int in nodes.size():
			nodes[i] = {"node_id": "", "hp": 0.0, "max_hp": 0.0}
		_spawn_wave(loc_id)
		_refresh_mine_visuals(loc_id)
		_flash_feedback("TNT! Wave cleared instantly.")
	elif duration > 0:
		var expires_at := Time.get_unix_time_from_system() + float(duration)
		GameState.active_boosts[effect] = {
			"mult":       mult,
			"flat":       flat,
			"expires_at": expires_at,
		}
		_update_boost_strip()
		_flash_feedback("%s active for %ds!" % [item.get("name", ""), duration])

	_update_toolbox_panel()
	_update_hud()


func _on_buy_item() -> void:
	if _toolbox_selected.is_empty(): return
	var item := ToolboxDatabase.get_item(_toolbox_selected)
	if item.is_empty(): return

	var cost : int = int(item.get("gem_cost", 1))
	if GameState.gems < cost: return

	GameState.gems -= cost
	var iid : String = item.get("id", "")
	GameState.inventory[iid] = int(GameState.inventory.get(iid, 0)) + 1

	_update_toolbox_panel()
	_update_hud()


func _on_menu_toolbox() -> void:
	_close_all_panels()
	if _toolbox_selected.is_empty() and not ToolboxDatabase.get_all().is_empty():
		_toolbox_selected = ToolboxDatabase.get_all()[0].get("id", "")
	_update_toolbox_panel()
	_toolbox_panel.visible = true


# ══════════════════════════════════════════════════════════════════════════
# Boost strip (thin overlay showing active boost timers)
func _build_toolbox_float_btn() -> void:
	const BTN_W    := 60
	const BTN_H    := 60
	const MARGIN   := 10
	const BTN_X    : int = SCREEN_W - BTN_W - MARGIN          # 650
	const BTN_Y    : int = MINE_Y + MINE_H - BTN_H - MARGIN - 90  # above info strip

	_toolbox_float_cl        = CanvasLayer.new()
	_toolbox_float_cl.name   = "ToolboxFloat"
	_toolbox_float_cl.layer  = 9    # above boost strip (8), below HUD (10)
	add_child(_toolbox_float_cl)

	# Orange background square
	var bg      := ColorRect.new()
	bg.color     = Color(0.90, 0.50, 0.20)
	bg.position  = Vector2(BTN_X, BTN_Y)
	bg.size      = Vector2(BTN_W, BTN_H)
	_toolbox_float_cl.add_child(bg)

	# Inner dark inset
	var inset      := ColorRect.new()
	inset.color     = Color(0.0, 0.0, 0.0, 0.22)
	inset.position  = Vector2(BTN_X + 3, BTN_Y + 3)
	inset.size      = Vector2(BTN_W - 6, BTN_H - 6)
	_toolbox_float_cl.add_child(inset)

	# Symbol
	var lbl      := Label.new()
	lbl.text      = "⚒"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.position  = Vector2(BTN_X, BTN_Y)
	lbl.size      = Vector2(BTN_W, BTN_H)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	_toolbox_float_cl.add_child(lbl)

	# "TOOLS" sub-label
	var sub      := Label.new()
	sub.text      = "TOOLS"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position  = Vector2(BTN_X - MARGIN, BTN_Y + BTN_H + 2)
	sub.size      = Vector2(BTN_W + MARGIN * 2, 18)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.90, 0.60, 0.30))
	_toolbox_float_cl.add_child(sub)

	# Tap button covering the square
	var btn      := Button.new()
	btn.flat      = true
	btn.position  = Vector2(BTN_X, BTN_Y)
	btn.size      = Vector2(BTN_W, BTN_H)
	_toolbox_float_cl.add_child(btn)
	btn.pressed.connect(_on_menu_toolbox)

# ══════════════════════════════════════════════════════════════════════════

func _build_boost_strip() -> void:
	_boost_strip         = CanvasLayer.new()
	_boost_strip.name    = "BoostStrip"
	_boost_strip.layer   = 8
	_boost_strip.visible = false
	add_child(_boost_strip)

	var strip_bg      := ColorRect.new()
	strip_bg.color     = Color(0.05, 0.06, 0.10, 0.88)
	strip_bg.position  = Vector2(0, MINE_Y)
	strip_bg.size      = Vector2(SCREEN_W, 28)
	_boost_strip.add_child(strip_bg)

	_boost_chip_box = HBoxContainer.new()
	_boost_chip_box.position = Vector2(6, MINE_Y + 4)
	_boost_chip_box.size     = Vector2(SCREEN_W - 12, 20)
	_boost_chip_box.add_theme_constant_override("separation", 6)
	_boost_strip.add_child(_boost_chip_box)


func _update_boost_strip() -> void:
	if not _boost_chip_box: return

	for child: Node in _boost_chip_box.get_children():
		_boost_chip_box.remove_child(child)
		child.queue_free()

	var now        := Time.get_unix_time_from_system()
	var has_active := false

	for effect_type: String in GameState.active_boosts.keys():
		var b       : Dictionary = GameState.active_boosts[effect_type]
		var expires : float      = float(b.get("expires_at", 0))
		if now >= expires:
			continue
		has_active = true
		var secs_left : int = int(expires - now)

		var chip_color := Color(0.60, 0.60, 0.70)
		var chip_sym   := effect_type.left(1).to_upper()
		for it: Dictionary in ToolboxDatabase.get_all():
			if it.get("effect", "") == effect_type:
				chip_color = it.get("color", chip_color)
				chip_sym   = it.get("symbol", chip_sym)
				break

		var chip      := ColorRect.new()
		chip.color     = chip_color.darkened(0.55)
		chip.custom_minimum_size = Vector2(72, 20)
		_boost_chip_box.add_child(chip)

		var chip_lbl      := Label.new()
		chip_lbl.text      = "%s %ds" % [chip_sym, secs_left]
		chip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		chip_lbl.position  = Vector2.ZERO
		chip_lbl.size      = Vector2(72, 20)
		chip_lbl.add_theme_font_size_override("font_size", 12)
		chip_lbl.add_theme_color_override("font_color", chip_color)
		chip.add_child(chip_lbl)

	_boost_strip.visible = has_active

# ══════════════════════════════════════════════════════════════════════════
# Display refresh
# ══════════════════════════════════════════════════════════════════════════

func _update_display() -> void:
	_update_hud()
	_update_mine_screen()
	if _craft_panel and _craft_panel.visible:
		_update_craft_panel()
	if _build_panel and _build_panel.visible:
		_update_build_panel()

func _update_hud() -> void:
	_lbl_cash.text  = "$ %s"   % _fmt(GameState.cash)
	_lbl_gems.text  = "◆ %s"   % _fmt(GameState.gems)
	_lbl_level.text = "Lv. %d" % GameState.player_level
	_update_xp_bar()

func _update_xp_bar() -> void:
	var needed := BuildDatabase.get_xp_needed(GameState.player_level)
	var pct    := minf(GameState.player_xp / needed, 1.0)
	_xp_bar_fill.size.x = float(SCREEN_W) * pct
	if _lbl_xp:
		_lbl_xp.text = "%s / %s XP" % [_fmt(int(GameState.player_xp)), _fmt(int(needed))]

func _update_mine_screen() -> void:
	var loc_id   := GameState.active_location_id
	var loc_data := BuildDatabase.get_location(loc_id)
	var mat: String = loc_data.get("material", "timber")
	var accent      := _mat_color(mat)

	# Backdrop + full visual rebuild when location changes
	if loc_id != _last_backdrop_loc:
		_last_backdrop_loc = loc_id
		var bg_path: String = BACKDROP_PATHS.get(loc_id, "")
		if bg_path != "" and ResourceLoader.exists(bg_path):
			_mine_backdrop.texture = load(bg_path)
		else:
			_mine_backdrop.texture = null
		# Reset positions so nodes scatter fresh on the new backdrop
		for vis: Dictionary in _node_visuals:
			vis["pos"] = Vector2(-1.0, -1.0)
		_refresh_mine_visuals(loc_id)

	# Location bar
	_lbl_active_loc.text = loc_data.get("display_name", loc_id)
	_lbl_active_loc.add_theme_color_override("font_color", accent)
	_loc_bar_accent.color = accent

	# Fast path: just update HP bars (shapes don't change per tick)
	_update_mine_hps(loc_id)

	# Info strip
	var mat_count: int = GameState.materials.get(mat, 0)
	_lbl_mat_count.text = "%s: %s" % [mat.capitalize(), _fmt(mat_count)]
	_lbl_mat_count.add_theme_color_override("font_color", accent)
	var mp    := GameState.get_mine_power()
	var wrate := _worker_damage_rate(loc_id)
	_lbl_mine_rate.text = "Mine Power: %d  ·  Workers: %.1f HP/s" % [mp, wrate]

func _update_build_panel() -> void:
	var tier := BuildDatabase.get_tier(GameState.current_building.get("tier_id", "shed"))
	var idx:  int = int(GameState.current_building.get("stage_index", 0))
	var stage     := BuildDatabase.get_current_stage()
	var started:  bool = GameState.current_building.get("stage_started", false)
	var progress: float = float(GameState.current_building.get("stage_progress", 0.0))

	# Stage header label
	if tier and stage:
		_lbl_build_stage.text = "%s   Stage %d / %d\n%s" \
			% [tier.display_name, idx + 1, tier.stages.size(), stage.display_name]
	elif tier:
		_lbl_build_stage.text = "%s — All stages complete!" % tier.display_name
	else:
		_lbl_build_stage.text = ""

	# Building sprite (atlas for houses, hidden for shed)
	var art := _get_stage_texture(
		GameState.current_building.get("tier_id", "shed"), idx)
	if art:
		_building_sprite.texture = art
		_building_sprite.visible = true
	else:
		_building_sprite.visible = false

	# Build Power stat
	_lbl_build_bp.text = "Build Power: %d" % GameState.get_build_power()

	if started:
		# Progress view
		_build_reqs_box.visible  = false
		_btn_start_stage.visible = false
		_lbl_cant_start.visible  = false
		_build_prog_bg.visible   = true
		_build_prog_fill.visible = true
		_lbl_build_pct.visible   = true
		_btn_tap_build.visible   = true
		# Show the two sibling nodes (tap bg + accent bar) that are children of the panel
		if _build_panel.get_node_or_null("TapBuildBg"):
			_build_panel.get_node("TapBuildBg").visible   = true
		if _build_panel.get_node_or_null("TapBuildBar"):
			_build_panel.get_node("TapBuildBar").visible  = true

		var prog_w := float(SCREEN_W - 40) * progress
		_build_prog_fill.size.x = prog_w
		_lbl_build_pct.text     = "%d%%" % int(progress * 100)
	else:
		# Requirements view
		_build_reqs_box.visible  = true
		_build_prog_bg.visible   = false
		_build_prog_fill.visible = false
		_lbl_build_pct.visible   = false
		_btn_tap_build.visible   = false
		if _build_panel.get_node_or_null("TapBuildBg"):
			_build_panel.get_node("TapBuildBg").visible  = false
		if _build_panel.get_node_or_null("TapBuildBar"):
			_build_panel.get_node("TapBuildBar").visible = false

		# Rebuild requirement rows
		for child in _build_reqs_box.get_children():
			child.queue_free()

		if stage:
			var can_afford := true
			for mat: String in stage.required_materials:
				var need: int = int(stage.required_materials[mat])
				var have: int = GameState.materials.get(mat, 0)
				if have < need:
					can_afford = false
				var accent := _mat_color(mat)

				var row_lbl     := Label.new()
				var tick        := " ✓" if have >= need else ""
				row_lbl.text     = "%s: %s / %s%s" % [mat.capitalize(), _fmt(have), _fmt(need), tick]
				row_lbl.custom_minimum_size = Vector2(SCREEN_W - 40, 36)
				row_lbl.add_theme_color_override("font_color", C_GREEN if have >= need else accent)
				_build_reqs_box.add_child(row_lbl)

				var bar_bg     := ColorRect.new()
				bar_bg.color    = Color(0.10, 0.10, 0.16)
				bar_bg.custom_minimum_size = Vector2(SCREEN_W - 40, 12)
				_build_reqs_box.add_child(bar_bg)

				var bar_fill     := ColorRect.new()
				bar_fill.color    = accent.darkened(0.15)
				var pct           := minf(float(have) / float(need), 1.0)
				bar_fill.custom_minimum_size = Vector2((SCREEN_W - 40) * pct, 12)
				_build_reqs_box.add_child(bar_fill)

				# Spacer
				var spacer     := Control.new()
				spacer.custom_minimum_size = Vector2(0, 8)
				_build_reqs_box.add_child(spacer)

			_btn_start_stage.visible  = can_afford
			_lbl_cant_start.visible   = not can_afford

			# Check build power gate
			if can_afford and tier:
				var bp       := GameState.get_build_power()
				var required := tier.build_power_required
				if bp < required:
					_btn_start_stage.visible = false
					_lbl_cant_start.visible  = true
					_lbl_cant_start.text     = ("Build Power too low: need %d, have %d" \
						% [required, bp])
				else:
					_lbl_cant_start.text = "Not enough materials."
		else:
			_btn_start_stage.visible = false
			_lbl_cant_start.visible  = false

# ══════════════════════════════════════════════════════════════════════════
# Helpers
# ══════════════════════════════════════════════════════════════════════════

func _fmt(n: int) -> String:
	if n >= 1_000_000_000:
		return "%.1fB" % (float(n) / 1_000_000_000.0)
	elif n >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	elif n >= 10_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return "%d" % n

func _mat_color(mat_id: String) -> Color:
	match mat_id:
		"timber":     return C_TIMBER
		"stone":      return C_STONE
		"sand":       return C_SAND
		"steel_ore":  return C_STEEL_ORE
		"clay":       return C_CLAY
		"copper_ore": return C_COPPER_ORE
		"limestone":  return C_LIMESTONE
		"bauxite":    return C_BAUXITE
		"lumber":     return C_LUMBER
		"concrete":   return C_CONCRETE
		"glass":      return C_GLASS
		"steel_beam": return C_STEEL_BEAM
		"copper_pipe":return C_COPPER_PIPE
		_:            return C_TEXT

func _tier_colour(tier_id: String) -> Color:
	match tier_id:
		"shed":            return Color(0.55, 0.45, 0.28)
		"single_house":    return Color(0.35, 0.55, 0.70)
		"two_story_house": return Color(0.50, 0.35, 0.70)
		_:                 return Color(0.50, 0.50, 0.50)

func _get_stage_texture(tier_id: String, stage_idx: int) -> AtlasTexture:
	match tier_id:
		"single_house":    return _atlas_region(stage_idx, 0)
		"two_story_house": return _atlas_region(stage_idx, 1)
	return null

func _atlas_region(col: int, row: int) -> AtlasTexture:
	if not _house_sheet_tex:
		_house_sheet_tex = load(_HOUSE_SHEET_PATH) as Texture2D
	if not _house_sheet_tex:
		return null
	var atlas        := AtlasTexture.new()
	atlas.atlas       = _house_sheet_tex
	atlas.filter_clip = true
	var w := 284 if col == 4 else _CELL_W
	atlas.region = Rect2(col * _CELL_W, row * _CELL_H, w, _CELL_H)
	return atlas

func _is_hired(id: String) -> bool:
	return not _crew_member_dict(id).is_empty()

func _crew_member_dict(id: String) -> Dictionary:
	for m: Dictionary in GameState.crew:
		if m.get("id", "") == id:
			return m
	return {}

func _crew_template(id: String) -> CrewMemberResource:
	for t in BuildDatabase.get_hireable_crew():
		if t.id == id:
			return t
	return null

func _flash_feedback(msg: String) -> void:
	if _feedback_tween:
		_feedback_tween.kill()
	_lbl_feedback.text = msg
	_feedback_tween    = create_tween()
	_feedback_tween.tween_property(_lbl_feedback, "modulate:a", 1.0, 0.06)
	_feedback_tween.tween_interval(1.5)
	_feedback_tween.tween_property(_lbl_feedback, "modulate:a", 0.0, 0.5)

func _flash_build_feedback(msg: String) -> void:
	if not _lbl_build_feedback:
		return
	var tw := create_tween()
	_lbl_build_feedback.text = msg
	tw.tween_property(_lbl_build_feedback, "modulate:a", 1.0, 0.05)
	tw.tween_interval(0.6)
	tw.tween_property(_lbl_build_feedback, "modulate:a", 0.0, 0.3)


# ── Offline gains summary ──────────────────────────────────────────────────
func _build_offline_popup() -> void:
	_offline_popup        = CanvasLayer.new()
	_offline_popup.layer  = 45
	_offline_popup.visible = false
	add_child(_offline_popup)

	# Dark dim
	var dim := ColorRect.new()
	dim.color    = Color(0.0, 0.0, 0.0, 0.82)
	dim.position = Vector2.ZERO
	dim.size     = Vector2(SCREEN_W, SCREEN_H)
	_offline_popup.add_child(dim)

	# Panel card
	const CARD_W := 600
	const CARD_H := 560
	const CARD_X := (SCREEN_W - CARD_W) / 2
	const CARD_Y := (SCREEN_H - CARD_H) / 2

	var card_bg := ColorRect.new()
	card_bg.color    = Color(0.08, 0.09, 0.13, 0.98)
	card_bg.position = Vector2(CARD_X, CARD_Y)
	card_bg.size     = Vector2(CARD_W, CARD_H)
	_offline_popup.add_child(card_bg)

	# Bolt-texture overlay on card
	var pt := load(PANEL_TEX_PATH) as Texture2D
	if pt:
		var np := NinePatchRect.new()
		np.texture             = pt
		np.position            = Vector2(CARD_X, CARD_Y)
		np.size                = Vector2(CARD_W, CARD_H)
		np.patch_margin_left   = 16
		np.patch_margin_right  = 16
		np.patch_margin_top    = 16
		np.patch_margin_bottom = 16
		np.modulate            = Color(0.80, 0.85, 0.90, 0.30)
		_offline_popup.add_child(np)

	# Gold top strip
	var strip := ColorRect.new()
	strip.color    = C_GOLD
	strip.position = Vector2(CARD_X, CARD_Y)
	strip.size     = Vector2(CARD_W, 4)
	_offline_popup.add_child(strip)

	# Header
	var hdr := Label.new()
	hdr.text                    = "WELCOME BACK"
	hdr.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	hdr.position                = Vector2(CARD_X, CARD_Y + 12)
	hdr.size                    = Vector2(CARD_W, 50)
	hdr.add_theme_font_size_override("font_size", 26)
	hdr.add_theme_color_override("font_color", C_GOLD)
	_offline_popup.add_child(hdr)

	# Separator under header
	var sep := ColorRect.new()
	sep.color    = C_GOLD.darkened(0.4)
	sep.position = Vector2(CARD_X, CARD_Y + 64)
	sep.size     = Vector2(CARD_W, 2)
	_offline_popup.add_child(sep)

	# Time-away label
	_lbl_offline_time                    = Label.new()
	_lbl_offline_time.text               = ""
	_lbl_offline_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_offline_time.position           = Vector2(CARD_X, CARD_Y + 74)
	_lbl_offline_time.size               = Vector2(CARD_W, 34)
	_lbl_offline_time.add_theme_font_size_override("font_size", 15)
	_lbl_offline_time.add_theme_color_override("font_color", Color(0.65, 0.68, 0.80))
	_offline_popup.add_child(_lbl_offline_time)

	# "MATERIALS COLLECTED" sub-header
	var sub := Label.new()
	sub.text                    = "MATERIALS COLLECTED"
	sub.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	sub.position                = Vector2(CARD_X, CARD_Y + 116)
	sub.size                    = Vector2(CARD_W, 28)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.50, 0.52, 0.65))
	_offline_popup.add_child(sub)

	# Rows container
	_offline_rows_box                   = VBoxContainer.new()
	_offline_rows_box.position          = Vector2(CARD_X + 36, CARD_Y + 150)
	_offline_rows_box.size              = Vector2(CARD_W - 72, 310)
	_offline_rows_box.add_theme_constant_override("separation", 8)
	_offline_popup.add_child(_offline_rows_box)

	# COLLECT button
	var btn      := Button.new()
	btn.text      = "COLLECT"
	btn.flat      = false
	btn.position  = Vector2(CARD_X + (CARD_W - 240) / 2, CARD_Y + CARD_H - 76)
	btn.size      = Vector2(240, 54)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.04, 0.04, 0.06))
	var bs := StyleBoxFlat.new()
	bs.bg_color                   = C_GOLD
	bs.corner_radius_top_left     = 6
	bs.corner_radius_top_right    = 6
	bs.corner_radius_bottom_left  = 6
	bs.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", bs)
	var bs_h := bs.duplicate() as StyleBoxFlat
	bs_h.bg_color = C_GOLD.lightened(0.2)
	btn.add_theme_stylebox_override("hover", bs_h)
	btn.pressed.connect(_on_offline_collect)
	_offline_popup.add_child(btn)


func _show_offline_popup(summary: Dictionary) -> void:
	# Clear old rows
	for ch in _offline_rows_box.get_children():
		ch.queue_free()

	# Time string
	var secs  := int(summary.elapsed)
	var hours := secs / 3600
	var mins  := (secs % 3600) / 60
	if hours > 0:
		_lbl_offline_time.text = "You were away for %dh %dm" % [hours, mins]
	else:
		_lbl_offline_time.text = "You were away for %d minutes" % mins

	# Material accent colour map
	var mat_cols := {
		"timber":     C_TIMBER,
		"stone":      C_STONE,
		"lumber":     C_LUMBER,
		"concrete":   C_CONCRETE,
		"sand":       C_SAND,
		"steel_ore":  C_STEEL_ORE,
		"glass":      C_GLASS,
		"steel_beam": C_STEEL_BEAM,
	}

	for mat: String in summary.gains:
		var amount := int(summary.gains[mat])
		var col: Color = mat_cols.get(mat, C_GOLD)

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 42)

		# Colour swatch
		var swatch := ColorRect.new()
		swatch.color               = col
		swatch.custom_minimum_size = Vector2(6, 36)
		row.add_child(swatch)

		# Gap
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(12, 0)
		row.add_child(gap)

		# Material name
		var name_lbl := Label.new()
		name_lbl.text                  = mat.replace("_", " ").capitalize()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(name_lbl)

		# Amount
		var amt_lbl := Label.new()
		amt_lbl.text                 = "+%d" % amount
		amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		amt_lbl.add_theme_font_size_override("font_size", 16)
		amt_lbl.add_theme_color_override("font_color", col)
		row.add_child(amt_lbl)

		_offline_rows_box.add_child(row)

	_offline_popup.visible = true


func _on_offline_collect() -> void:
	_offline_popup.visible = false
	OfflineProgressCalculator.clear_offline_summary()
	_update_display()


func _check_offline_summary() -> void:
	var summary := OfflineProgressCalculator.get_offline_summary()
	if summary.gains.is_empty():
		return
	_show_offline_popup(summary)
