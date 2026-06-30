# Project Contractor — Progress Log

---

## 2026-06-26 — Phase 0 Complete

### Completed this session
- Created full folder structure per Build Brief spec (all 10 leaf folders confirmed)
- Created placeholder brand assets in `assets/ui_theme/`:
  - `logo_placeholder.png` (256×128, navy)
  - `app_icon_placeholder.png` (256×256, gold)
  - `shop_chest_icon_placeholder.png` (128×128, green)
  - All three imported by Godot (`.import` sidecar files present)
- Created `scripts/autoload/GameState.gd` — stub (`extends Node`, comment only)
- Configured `project.godot`:
  - Portrait orientation (`window/handheld/orientation="portrait"`)
  - 720×1280 viewport
  - Mobile renderer (`renderer/rendering_method="mobile"`, `config/features` includes `"Mobile"`)
  - `GameState` registered as autoload singleton
  - `scenes/main/Main.tscn` set as main scene (Node2D root, no children)
- Connected Godot project folder to Cowork file access (`D:\Godot\Projects\projectcontractor`)

### Phase 0 checkpoint status
✅ Project boots in Godot editor with correct mobile/portrait settings  
✅ GameState autoload registered  
✅ Placeholder assets imported  
⏳ Real device/export check deferred to Phase 6 (no Android template yet)

### Next step
~~Awaiting Phase 0 confirmation~~ — confirmed. Phase 1 complete (see below).

---

## 2026-06-26 — Phase 1 Complete

### Completed this session
- Defined 4 Resource classes in `scripts/data/`:
  - `MaterialResource` — id, display_name, icon, base_value
  - `BuildStageResource` — id, display_name, required_materials (Dictionary), stage_order
  - `BuildingTierResource` — id, display_name, stages (Array[BuildStageResource]), build_power_required, unlock_condition
  - `CrewMemberResource` — id, display_name, base_speed_bonus, hire_cost, level, material_type
- Implemented full `GameState` autoload: cash, gems, materials, crew, current_building, skyline, last_saved_timestamp
- Implemented `SaveManager` autoload: save/load to `user://save.json`, 30s autosave, save on pause/quit
- Implemented `OfflineProgressCalculator` autoload: credits idle material gains on launch (capped 12h), emits `offline_gains_applied` signal
- Registered all three autoloads in `project.godot` in correct dependency order (GameState → SaveManager → OfflineProgressCalculator)

### Phase 1 checkpoint — how to verify
1. Open the project in Godot and hit **Play (F5)** — no errors in the Output panel
2. Stop the game, wait 10+ seconds, run again
3. The Output panel should print: `OfflineProgressCalculator: +{"timber": N} after Xs offline`
4. The `user://save.json` file should appear in Godot's user data folder

### Next step
~~Awaiting user confirmation~~ — confirmed. Phase 2 complete (see below).

---

## 2026-06-26 — Phase 2 Complete

### Completed this session
- Created `scripts/data/BuildDatabase.gd` autoload: defines Garden Shed (4 stages) inline as BuildingTierResource/BuildStageResource instances. Registered between GameState and SaveManager in project.godot.
- Updated `scripts/autoload/OfflineProgressCalculator.gd`: stores offline gains in `_last_gains`/`_last_elapsed` instead of emitting signal immediately in `_ready()` (timing fix). Added `get_offline_summary()` and `clear_offline_summary()` for polling from Main.
- Wrote `scenes/main/Main.gd`: full Phase 2 scene built entirely in code.
  - Top HUD bar: Cash, Gems, Timber, Stone counts (CanvasLayer)
  - Build site: ground ColorRect + building ColorRect (lerps brown -> grey as stages complete)
  - Two tap Buttons: Timber Pile and Stone Pile, +5 per tap
  - Stage progression: auto-completes when materials >= required; consumes materials, awards cash, advances stage_index
  - Building complete: appends tier_id to skyline, +100 cash, resets to stage 0
  - Tween pop on stage/building complete; fade feedback label on every tap
  - Bottom stage panel: per-material have/need counts with tick marks
  - Offline summary polled from OfflineProgressCalculator on _ready()
- Updated `scenes/main/Main.tscn`: attached Main.gd via ext_resource reference.
- Autoload order: GameState -> BuildDatabase -> SaveManager -> OfflineProgressCalculator

### Garden Shed stage data
Stage 1: Site Clearance (timber 20) | Stage 2: Foundations (stone 30, timber 10)
Stage 3: Wall Framing (timber 40, stone 10) | Stage 4: Roof & Finish (timber 20, stone 15)

### Phase 2 checkpoint — how to verify
1. Play (F5) — no errors in Output
2. Tap Timber Pile / Stone Pile — HUD increments by 5 per tap
3. Gather 20 timber — stage auto-advances, building rect lightens, feedback appears
4. Complete all 4 stages — "Building complete!" message, skyline count +1, resets to stage 1
5. Stop + restart — material counts and stage index restored from save

### Next step
~~Awaiting user confirmation~~ — confirmed. Phase 3 complete (see below).

---

## 2026-06-26 — Phase 3 Complete

### Completed this session
- Added crew templates to `scripts/data/BuildDatabase.gd`:
  - Old Bob — Timber, hire 40 cash, 0.5/s per level
  - Granite Pete — Stone, hire 50 cash, 0.5/s per level
  - Nimble Nick — Timber (premium), hire 90 cash, 1.0/s per level
  - New `get_hireable_crew()` method returns the template list
- Replaced Phase 1 stub in `OfflineProgressCalculator._get_idle_rates()` with real crew-based rate calculation (empty dict if no crew hired)
- Rewrote `scenes/main/Main.gd` with full Phase 3 crew system:
  - `_process()` tick: accumulates fractional materials from crew rates each frame
  - CREW button (y=705) toggles full-screen crew overlay panel
  - Crew panel: 3 cards (one per template) showing name, material type, rate, level
  - Hire button (if not hired, disabled if insufficient cash)
  - Level-up button (if hired): cost = hire_cost * current_level; updates rate label
  - `_update_crew_panel()` refreshes all card state after any hire/level-up
  - Crew panel auto-closes when user taps X or CREW button again

### Crew rates reference
| Crew | Material | Base rate | Level 2 | Level 3 |
|------|----------|-----------|---------|---------|
| Old Bob | Timber | 0.5/s | 1.0/s | 1.5/s |
| Granite Pete | Stone | 0.5/s | 1.0/s | 1.5/s |
| Nimble Nick | Timber | 1.0/s | 2.0/s | 3.0/s |

Level-up cost: hire_cost * current_level (Bob L1->L2: 40 cash, L2->L3: 80 cash, etc.)

### Phase 3 checkpoint — how to verify
1. Play (F5), tap CREW button — panel opens with 3 crew cards
2. Hire Old Bob (40 cash) — hire button hides, level-up button appears, HUD cash drops by 40
3. Close crew panel — building rect should slowly lighten on its own as Bob gathers timber
4. Leave idle 10+ minutes (or adjust system clock) — on relaunch, offline gains should match Bob's rate × elapsed time
5. Level up Bob in crew panel — rate label updates, subsequent gains increase

### Next step
~~Awaiting user confirmation~~ -- confirmed. Phase 4 complete (see below).

---

## 2026-06-26 -- Phase 4 Complete

### Completed this session
- Added `get_build_power()` to `GameState.gd`: sum of hired crew levels x 1.0 (linear MVP placeholder per Build Brief; multiplier field noted for future exponential tuning per GDD Section 9)
- Added to `BuildDatabase.gd`:
  - `TIER_ORDER = ["shed", "single_house", "two_story_house"]`
  - `get_next_tier_id()` -- returns next tier id or "" if at max
  - Tier 2: **Single-Storey House** (build_power_required=3, 5 stages)
  - Tier 3: **Two-Storey House** (build_power_required=8, 5 stages)
- Rewrote `scenes/main/Main.gd` with full Phase 4 additions:
  - `_complete_building()` now checks next tier BP gate; advances or shows wall panel
  - **Wall panel** (CanvasLayer 25): shown when BP < required; displays tier name, BP needed vs current; "Keep Building" dismisses, "Open Crew" opens crew panel
  - **Skyline panel** (CanvasLayer 20): shows every completed building as a coloured swatch + name row; "nothing built yet" state handled; opened via SKYLINE button
  - CREW and SKYLINE buttons repositioned side-by-side (y=712)
  - `_update_building_visual()` now uses `_tier_colour()` as the base colour per tier, lerped to grey as stages complete (visual distinction between Shed/House/Two-Storey)

### Tier data summary
| Tier | BP Required | Stages | Total Timber | Total Stone |
|------|-------------|--------|-------------|-------------|
| Shed | 0 | 4 | 90 | 55 |
| Single-Storey House | 3 | 5 | 175 | 130 |
| Two-Storey House | 8 | 5 | 280 | 135 |

### Phase 4 checkpoint -- how to verify
1. Complete the Shed with BP < 3 -- wall panel should appear ("Build Power Too Low")
2. Hire/level crew to reach BP 3 -- complete another Shed -- should advance to Single-Storey House
3. Complete Single-Storey House with BP < 8 -- wall panel again
4. Reach BP 8 via crew upgrades -- break through to Two-Storey House
5. Open SKYLINE button -- shows all completed buildings as coloured rows
6. Complete Two-Storey House -- loops on it (max tier for MVP); skyline grows

### Next step
~~Awaiting user confirmation~~ -- confirmed. Phase 5 complete (see below).

---

## 2026-06-26 -- Phase 5 Complete

### Completed this session
- **Gem earning wired**: +1 Gem per stage completion, +5 Gems on building completion (placeholder rates, easy to tune)
- **Shop panel added** to `Main.gd` (CanvasLayer 20):
  - Accessible only via SHOP button tap -- never auto-opened
  - Gems balance display at top
  - Policy notice: "Gems are earned through play. Every item here is optional and never required to progress."
  - Item: **Instant Stage Skip** (10 Gems) -- advances stage_index without consuming materials; disabled if < 10 Gems or no stage in progress
  - Rewarded-ad placeholder card (non-functional, labelled "always player-initiated, never forced") for future integration reference
  - Skip-to-building-complete closes shop before showing wall panel (avoids z-order conflict)
- **CREW / SHOP / SKYLINE buttons** repositioned as three equal buttons centred across 720px
- All panel close logic updated so each button closes the other panels

### Policy compliance audit (release-blocking check per Build Brief)

Reviewed every `.visible = true` call site in Main.gd:

| What opens | Trigger | Contains purchase prompt? | Verdict |
|---|---|---|---|
| Crew panel | Player taps CREW button | No | PASS |
| Shop panel | Player taps SHOP button | Yes (inside Shop only) | PASS |
| Skyline panel | Player taps SKYLINE button | No | PASS |
| Wall panel | Building completed + BP too low | No (gameplay message only) | PASS |
| Crew panel (from wall) | Player taps "Open Crew" on wall | No | PASS |
| Feedback label flash | Tap / stage complete / offline | No | PASS (non-blocking) |

No forced interstitials. No purchase prompts outside Shop. No overlays appear unprompted from timers or signals. The wall panel triggers from game progress (building complete) but contains zero monetisation content -- it is the intended progression wall, not an ad.

### Phase 5 checkpoint -- how to verify
1. Play -- SHOP button opens Shop panel; closing returns cleanly to gameplay
2. Complete stages -- Gems increment (+1/stage, +5/building)
3. Accumulate 10 Gems -- "Buy (10 Gems)" button enables; pressing it advances current stage without consuming materials
4. Confirm no purchase popup ever appears without tapping SHOP first
5. Confirm wall panel (when it appears) has no "buy" language -- only "Upgrade your Crew"

### Next step
~~Awaiting user confirmation~~ -- confirmed. Phase 6 in progress (see below).

---

## 2026-06-28 -- Phase 6 Complete ✅

### Confirmed complete
- Android export working (Compatibility renderer, LDPlayer)
- Force-quit stress test passed — save/restore holds under abrupt close
- SFX deprioritised — not needed for MVP
- MVP Definition of Done checkpoint passed (full loop confirmed by user)

### Post-MVP additions completed in earlier sessions (beyond original Phase 6 scope)
- Prestige / New Contract system (rep points, artifacts, portfolio, contract count)
- Tiers 4–8: Apartment Block, Retail Unit, Office Block, High-Rise, Skyscraper (BP gates 20/40/70/110/160)
- New materials: sand, steel_ore + refined glass, steel_beam
- New mining locations: Sand Pit, Steel Yard (4 nodes each)
- New crew: Sandy Walsh (sand), Iron Mike (steel_ore)
- Workshop crafting expanded to 4 recipes / 8-material inventory
- Sell panel expanded to all 8 materials
- CONTRACT panel: artifact shop + all-time portfolio view
- ArtifactDatabase autoload + 5 permanent artifacts
- Offline calculator updated to apply worker rate mult + drop bonus
- All GDScript warnings resolved (integer division, unused variables)

### Open art blocker (non-blocking for play, blocking for store submission)
- Stage-number text baked into ModernHouseA.png cells conflicts with in-game stage UI — clean art needed before release

---

## 2026-06-26 -- Phase 6 In Progress

### Completed this session
- **ModernHouseA.png atlas wired into build display** (`scenes/main/Main.gd`):
  - Added `Sprite2D` (`_building_sprite`) at centre (360, 320), scale 1.2 — fills the build area from HUD to tap buttons
  - Added `_get_stage_texture(tier_id, stage_idx)` and `_atlas_region(col, row)` helpers
  - `ModernHouseA.png` grid: 5×2, 281×384px per cell (last column 284px); row 0 = Single-Storey House stages 0–4, row 1 = Two-Storey House stages 0–4
  - `_update_building_visual()` shows Sprite2D + AtlasTexture for house tiers, ColorRect for shed (no art yet)
  - `_pop_building()` tween targets the visible node with correct base scale per node type
  - Atlas texture loaded once on first use (`_house_sheet_tex` cache); `filter_clip = true` prevents cell bleed

### What's still needed for Phase 6

**Art still required from user:**
- Garden Shed stages (4 images) -- keeps ColorRect placeholder until provided
- Two-Storey House art is covered by ModernHouseA.png row 1

**Remaining Phase 6 tasks:**
- Logo / branding on main screen (MainLogoWText.png, BannerLogo.png)
- HUD icon art (ShopIcon.png and Settings Icon.png wired in)
- Placeholder SFX (tap feedback, stage-complete, building-complete) via programmatic AudioStreamWAV tones
- Android export setup + real device smoke-test (user performs)
- Force-quit stress test (user performs)
- MVP Definition of Done checkpoint (full loop: fresh install → Shed → wall → crew → Tier 2 → Skyline → close/reopen → offline gains → Shop policy check)

- **Crew rate rebalance**: Granite Pete raised to 1.0/s stone, hire cost 75 (was 0.5/s, 50). All-crew ratio now 1.5:1 timber:stone, matching material demand across all tiers.
- **Branding wired in**:
  - `BannerLogo.png` (211×54) displayed in left 260px of the HUD bar (STRETCH_KEEP_ASPECT_CENTERED). Stats row shifted to occupy the remaining 460px.
  - `MainLogoWText.png` (1600×409) shown on a 2.5s splash screen (CanvasLayer 30) on every launch — navy background, logo centred, tap anywhere to skip, fades out automatically.
- **Pre-ship art blocker noted**: Stage-number labels baked into `ModernHouseA.png` cells ("Stage 7" etc.) are visible simultaneously with the game's own "Stage 2/5" UI text. Clean asset versions without baked text are required before MVP sign-off.

### What's still needed for Phase 6
- Garden Shed stage art (4 images) — still awaiting from user
- Placeholder SFX (tap feedback, stage-complete, building-complete) via programmatic AudioStreamWAV tones
- Android export setup + real device smoke-test (user performs)
- Force-quit stress test (user performs)
- MVP Definition of Done checkpoint

- **UI/UX overhaul complete** — `scenes/main/Main.gd` fully rewritten with IOM-inspired dark theme:
  - Dark colour palette (`C_BG`, `C_PANEL`, `C_CARD`, `C_BORDER`, per-resource accent colours)
  - HUD: colour-coded stat chips (gold/cyan/amber/grey) with BannerLogo retained left
  - Build site: dark background, tap buttons styled as accent-bordered coloured cards
  - Stage info panel: two material-requirement progress bars (Timber + Stone) with live fill
  - Bottom tab bar (CanvasLayer 50 — always on top over panels): CREW / SHOP / SKYLINE with active-tab indicator bar + colour highlight
  - Crew panel: IOM-style cards — avatar initial, material accent border, rate label, level label, green Hire / gold Upgrade buttons, level-progress bar at card bottom
  - Wall panel: dark red accent/border, danger title in red
  - Skyline panel: gold header border, ScrollContainer so list can grow
  - Shop panel: cyan header border, styled item card, all policy text retained
  - All game logic (tap, crew tick, stage/tier advancement, shop, offline gains) unchanged

### What's still needed for Phase 6
- Garden Shed stage art (4 images) — still awaiting from user
- Placeholder SFX (tap feedback, stage-complete, building-complete) via programmatic AudioStreamWAV tones
- Android export setup + real device smoke-test (user performs)
- Force-quit stress test (user performs)
- MVP Definition of Done checkpoint

### Next step
~~Awaiting confirmation~~ — Phase 6 complete, post-MVP work ongoing.

---

## 2026-06-28 — Post-MVP: Pinnable Quick Bar + Active Material HUD

### Completed this session
- **Bottom bar redesign**: Replaced MENU + SHOP two-button layout with 5-slot pinnable bar
  - Slots 0–3: dynamically built from `GameState.pinned_shortcuts` (Array, max 4)
  - Slot 4: permanent "MORE" button (☰) that opens the full menu overlay
  - Each slot: coloured icon square (code-drawn placeholder) + label
  - Slot dividers render between all 5 slots
- **Pin customiser panel** (CanvasLayer 28): 4×2 grid of all 8 available shortcuts
  - Tap to pin/unpin; green border = pinned, grey = not pinned
  - "✓ PINNED" badge on active tiles
  - DONE button + tap-dim-to-close
  - Accessible via "⚙ Edit Quick Bar" in the MORE menu
- **8 available shortcuts** (`SHORTCUT_DEFS` const): BUILD, CREW, CRAFT, SELL, SKYLINE, UPGRADES, CONTRACT, SHOP
  - Default pins: BUILD, CREW, CRAFT, SELL
  - Each shortcut has a colour and single-character placeholder icon (B/C/W/$/S/+/R/◆)
- **HUD 4th chip**: active material count — e.g. "28\nTimber" coloured to match active-location material
  - Shows count + material name below; refreshes on every `_update_hud()` call
  - HUD now has 4 equal chips across 520 px (chip_w = 130 px each)
- **Menu overlay 3×3 layout**: expanded from 2×4 to 3×3 (added SHOP as 9th item), card_h 640→660
- **Persistence**: `GameState.pinned_shortcuts` saved/loaded in SaveManager; survives prestige
- **`_close_all_panels()`**: now also hides `_pin_panel`

### Files changed
- `scripts/autoload/GameState.gd` — added `pinned_shortcuts`
- `scripts/autoload/SaveManager.gd` — save/load/fresh-state for `pinned_shortcuts`
- `scenes/main/Main.gd` — `SHORTCUT_DEFS`, `_lbl_active_mat`, `_bottom_bar_cl`, `_pin_panel`, `_pin_slot_nodes`, `_pin_card_borders`, `_pin_state_labels`; new functions: `_rebuild_pin_slots`, `_build_pin_panel`, `_shortcut_color`, `_shortcut_def`, `_on_shortcut_pressed`, `_on_pin_edit_open/close`, `_on_pin_toggle`, `_update_pin_panel_state`

### Parser errors fixed (2026-06-28 — session 2)
During previous session, a large Edit accidentally deleted ~700 lines of Main.gd and the file was reconstructed from `git show HEAD`. This restored pre-commit functions but lost post-commit ones. The following fixes were applied:
1. `var pinned: bool = ...` — fixed type-inference error at `_update_pin_panel_state()` (was `var pinned :=`)
2. Inserted missing functions before `_build_shop_panel()`: `_build_contract_panel`, `_build_artifact_card`, `_build_prestige_confirm_panel`, `_update_contract_panel` — all recovered from JSONL transcript
3. Replaced old `_update_mine_screen()` (used deleted `_loc_btns`/`_loc_indicators`) with correct redesigned version (uses `_lbl_active_loc`, `_loc_bar_accent`, `_mine_backdrop`, `_loc_picker_panel`) — also recovered from transcript

All 9 Godot parser errors should now be resolved.

### Next step
Build the game in Godot and test in LDPlayer:
1. Confirm 0 parser errors in Godot editor
2. Bottom bar shows 4 coloured icon buttons (BUILD/CREW/CRAFT/SELL) + MORE
3. Tapping BUILD/CREW/CRAFT/SELL opens correct panel
4. Tapping MORE opens the 3×3 menu overlay (9 items + "⚙ Edit Quick Bar")
5. Tapping "⚙ Edit Quick Bar" opens pin customiser
6. Toggle a pin — slot immediately updates
7. HUD top-right chip shows active material count and name

---

## 2026-06-28 — UI Polish session (continued)

### Completed this session
- **Bottom bar icons**: reduced icon_sz 44→36, recentred vertically (icon y bar+20, label y bar+60, label h 24)
- **HUD stat chips**: removed card background boxes; kept only a 3px accent underline per chip
- **XP bar live text**: added `_lbl_xp` member var; `_update_xp_bar()` now overlays "%d / %d XP" text on the bar
- **Panel headers redesigned**: added `_build_panel_header(parent, title, accent)` helper and `_apply_btn_style(btn, bg, fg, radius)` helper; all 8 panels (BUILD, CREW, WORKSHOP, SKYLINE, SELL, UPGRADES, CONTRACT, SHOP) now use one-line header calls with coloured top strip, separator, centred title, and styled ✕ close button
- **Location picker bug fixed**: removed `_loc_picker_panel.visible = false` from `_update_mine_screen()` — now only hidden in `_on_location_btn()` so it doesn't close when workers are active
- **CRITICAL FILE RECOVERY**: Python bulk-replacement scripts (for panel headers) truncated `Main.gd` to 2931 lines — lost all functions after `_complete_building()`. Recovered by splicing current file head (lines 1–2930) with git HEAD tail (from the Crew panel separator onwards). All missing functions restored. `_update_xp_bar` patched with `_lbl_xp` fix after splice. File now 3380 lines, 107 functions.

### Currently in progress / left mid-task
- File recovery is complete. Godot needs to reload and confirm 0 parser errors.

### Next step
Commit current work, then continue UI polish or gameplay features.

---

## 2026-06-28 — Multi-node mine screen

### Completed this session
- **GameState**: `location_nodes[loc_id]` changed from single `{node_id, hp}` dict to `Array[{node_id, hp}]`. Added `active_node_count: int = 1` (upgradeable).
- **BuildDatabase**: `get_default_location_nodes()` now returns Array format.
- **SaveManager**: saves/loads `active_node_count`; migrates old single-dict save format to array on load; pads arrays to `active_node_count` on load.
- **Main.gd — mine area rewrite**:
  - Removed single centered card (ColorRect box). Old vars gone: `_node_border`, `_node_rect`, `_node_accent_bar`, `_lbl_node_symbol`, `_lbl_node_name`, `_hp_bar_bg`, `_hp_bar_fill`, `_lbl_hp_left`, `_lbl_hp_right`.
  - Added `MAX_NODES = 5` visual pool (`_node_visuals: Array`).
  - Themed shapes per material (code-drawn ColorRect stacks): timber → layered pine tree, stone → rock pile, sand → pyramid mound, steel_ore → industrial tower.
  - Each node visual has its own mini HP bar (96px wide, colour-coded green/gold/red).
  - `_refresh_mine_visuals()`: rebuilds all node shapes, assigns random scattered positions within mine area using grid+jitter.
  - `_update_mine_hps()`: fast path (HP bars only) called every damage tick.
  - `_flash_node_hit()`: bounce-scale tween on hit node.
  - `_apply_node_damage()`: targets lowest-HP node (focus-fire model).
  - `_break_node()`: respawns in-place at new random position, calls `_refresh_mine_visuals()`.
  - `_on_level_up()`: upgrades all node types, resets visual positions for fresh scatter.
  - `_update_mine_screen()`: calls `_refresh_mine_visuals()` on location change (resets positions), `_update_mine_hps()` on every tick.
  - Info strip (mat count + mine rate) pinned to bottom of mine area.

### Next step (from previous session)
1. Load in Godot — confirm 0 parser errors
2. Test on LDPlayer: nodes appear scattered, HP bars deplete, nodes respawn at new positions on break
3. Add "Extra Node" upgrade to UPGRADES panel (increments `GameState.active_node_count`, pads `location_nodes` arrays, calls `_refresh_mine_visuals`)

---

## 2026-06-29 — Panel texture + offline gains popup

### Completed this session
- **`PANEL_TEX_PATH` constant** added: `res://assets/sprites/ui/panel_grey_bolts_detail_a.svg`
- **`_build_panel_header()` updated**: now adds a full-panel `NinePatchRect` (9-patch margins 16px, modulate `Color(0.65,0.70,0.78,0.14)`) behind every panel header, giving all 8 panels a subtle industrial bolt-corner texture overlay.
- **Offline gains popup** (`_build_offline_popup`, `_show_offline_popup`, `_on_offline_collect`):
  - Built at startup (CanvasLayer layer 45), replaces the old one-liner `_flash_feedback` call.
  - Shows a centred card (600×560) with the bolt-texture NinePatchRect at higher opacity (0.30).
  - Gold "WELCOME BACK" header + accent strip.
  - Time-away line: "You were away for Xh Ym" or "X minutes".
  - Per-material rows: colour swatch, material name, `+N` amount in material's accent colour.
  - Gold "COLLECT" button dismisses popup and calls `_update_display()`.
  - `_check_offline_summary()` reduced to 3 lines — just calls `_show_offline_popup()`.
- File grew from 3474 → 3674 lines (no truncation).

### Currently in progress / left mid-task
Nothing — implementation complete. Needs Godot reload + LDPlayer test.

### Next step
1. Close Main.gd in Godot editor (prevents truncation race), then reopen project.
2. Confirm 0 parser errors.
3. Test offline popup: close game, wait 15 s, reopen — "WELCOME BACK" popup should appear with gained materials.
4. Still pending: "Extra Node Slot" upgrade in UPGRADES panel.
5. Still pending: git commit for this session.

---

## 2026-06-29 — Sprite system, crew reassignment, number formatting, missions

### Completed this session

**Sprite system (lumber yard + stone quarry)**
- `NODE_SPRITES` const: 12-entry arrays for `timber` and `stone` (small/tall/thin × NE/NW/SE/SW PNGs)
- `_setup_node_vis()` now picks a random path from the pool, loads it as `Texture2D`, spawns a `Sprite2D` child with `randf_range(0.8, 1.3)` scale instead of a `ColorRect` shape stack
- `_make_empty_node_vis()` adds `"sprite": null` to the ref dict; HP bar pushed to y=72, label to y=86
- Sprite scale bug fixed (initial 0.16–0.26 was too small; 512×512 canvas has small content area)

**Visual tweaks to nodes**
- `_flash_node_hit()`: tween durations slowed to 0.12 / 0.22 s (was 0.06 / 0.10)
- `_update_mine_hp_bar()`: label shows HP number (`"%d" % int(hp)`) instead of node name; label colour forced to `Color.WHITE`

**Location picker colour-coding**
- `_mat_color()` extended to all 13 materials (was only 4)
- Material name label and accent strip in SELECT LOCATION panel now use `_mat_color(mat_id)` for per-material colouring

**Crew panel scroll + card layout**
- `ScrollContainer` (y=130, h=SCREEN_H-130-BOTTOM_BAR_H) wrapping a `Control` added to `_build_crew_panel()`
- `_crew_scroll_content` holds all cards; `custom_minimum_size` set to `templates.size() * 210 + 20` height
- `card_y` changed from `135 + idx*210` → `idx*210 + 8`; all `add_child` calls rerouted to `_crew_scroll_content`
- Level-up button width: 350 → 218 px

**Crew reassignment UI**
- Added "▶ MOVE" button (x=554, w=122) to each hired crew card
- `_build_crew_loc_picker()`: new CanvasLayer (layer=25) — full-screen dim + card + bolt-texture + title + 8 location rows each with colour strip
- `_on_crew_move_pressed(crew_id)` / `_on_crew_loc_selected(loc_id)`: updates `member["location_id"]` and `member["material_type"]` in GameState.crew
- `_update_crew_panel()` refreshes `_crew_loc_labels` and `_crew_move_btns` visibility

**All 9 crew registered in BuildDatabase**
- Restored missing `_register_crew()` (file was truncated at line 366): copper_carl, lime_larry, boxy_dave added alongside existing 6
- Locations: lumber_yard (old_bob, nimble_nick), stone_quarry (granite_pete), sand_pit (sandy_walsh), steel_yard (iron_mike), clay_pit (clay_molly), copper_mine (copper_carl), limestone_quarry (lime_larry), bauxite_mine (boxy_dave)

**Number formatting (`_fmt`)**
- `_fmt(n: int) -> String`: thresholds at 10K/1M/1B with one decimal place
- Applied to: HUD cash/gems, XP bar, mine mat count, sell panel (have + earnings), craft panel (inventory + yield), build requirements (have/need), upgrade costs, crew hire/upgrade text

**Daily / weekly missions**
- `MissionManager.gd` autoload: 10-entry daily pool + 8-entry weekly pool; picks 3 daily / 2 weekly via deterministic RNG seeded to day/week number; auto-resets at UTC midnight / Sunday midnight
- `GameState`: `daily_missions`, `weekly_missions`, `daily_reset_at`, `weekly_reset_at` vars added
- `SaveManager`: saves and loads all four mission vars; `_init_fresh_state` leaves them at defaults for MissionManager to populate
- `MissionManager` registered as autoload after ArtifactDatabase in project.godot
- `SHORTCUT_DEFS`: `"missions"` entry added (symbol M, gold colour); MORE menu expanded to 3×4 (10 items)
- `_build_missions_panel()`: CanvasLayer layer=22, scrollable VBox, section headers with countdown labels, 5 mission cards (3 daily, 2 weekly) with progress bar, reward label, CLAIM button
- `_update_missions_panel()`: fills cards from `GameState.daily_missions + weekly_missions`; accent colours per mission type; CLAIM button enables when progress ≥ target
- Progress hooks added: `_break_node()` → `collect_mat + break_nodes`, `_complete_stage()` → `complete_stages`, `_on_sell_pressed()` → `sell_cash`, `_on_craft_one/all()` → `craft_items`
- Countdown labels refresh every second while missions panel is open (via `_process`)

### Currently in progress / left mid-task
Nothing — all above is complete.

### Next step
1. Open Godot, confirm 0 parser errors
2. Test missions: open MISSIONS from quick bar or MORE menu, daily/weekly missions should appear
3. Break nodes → check collect_mat / break_nodes progress increments
4. CLAIM a completed mission → cash/gems awarded
5. Commit once testing passes
6. ~~Pending: "Extra Node Slot" upgrade wiring in UPGRADES panel~~ — Done (see below)

---

## 2026-06-29 — Extra Node Slot upgrade

### Completed this session
- Added `extra_node_slot` to `UpgradeDatabase.UPGRADES`: unlock level 7, max 4 levels, +1 node/level, base cost 60 timber + 40 stone (doubles per level)
- Post-buy hook in `_on_upgrade_buy()`: when `upgrade_id == "extra_node_slot"`, sets `GameState.active_node_count = 1 + new_level`, pads all location node arrays with best available nodes for the player's current level, then calls `_refresh_mine_visuals()` to show the new slot immediately
- `SaveManager` already saves/loads `active_node_count` and pads arrays on load — no changes needed there
- Cap enforced by `max_level: 4` matching `MAX_NODES = 5` in Main.gd

### Next step
Test in Godot: reach player level 7, open UPGRADES, buy Extra Node Slot — a second node should appear on the mine screen immediately. Buy again for 3, 4, 5 nodes.

---

## 2026-06-29 — Toolbox / Inventory system

### Completed this session

**Supporting autoloads (all new)**
- `ToolboxDatabase.gd`: defines 8 consumable items (energy_drink, speed_brew, rush_contract, xp_crystal, material_surge, cash_surge, tnt_charge, mega_blast) — each with effect type, mult/flat, duration, gem cost, symbol, rarity, colour
- `GameState.gd`: added `inventory: Dictionary` (item_id → count) and `active_boosts: Dictionary` (effect_type → {mult, flat, expires_at}); added `get_boost_mult()` / `get_boost_flat()` helpers that auto-expire stale entries; wired all 6 stat helpers to apply boosts (`get_mine_power`, `get_worker_rate_mult`, `get_drop_bonus`, `get_xp_mult`, `get_build_power`, `get_stage_cash_mult`)
- `SaveManager.gd`: saves/loads `inventory` and `active_boosts`; `_init_fresh_state` zeroes both
- `project.godot`: `ToolboxDatabase` registered after `MissionManager` in autoload order

**Main.gd — TOOLBOX panel (new functions)**
- `_build_toolbox_panel()`: CanvasLayer layer=23; 3-column × 3-row item grid (240×110 per cell) + detail footer; header colour `(0.90, 0.50, 0.20)`
- `_make_toolbox_cell()`: per-item cell with rarity left-strip, coloured symbol square, name/cost labels, count badge (bottom-right), invisible tap button that sets `_toolbox_selected`
- `_update_toolbox_panel()`: refreshes count badges, selection highlight (blue tint), detail footer (name in item colour, desc, owned count, USE/BUY buttons with correct enable states)
- `_on_use_item()`: consumes 1 from inventory; for `instant_wave` clears all current-location node slots and calls `_spawn_wave()`; for timed boosts writes to `GameState.active_boosts` with `expires_at`
- `_on_buy_item()`: deducts gems, increments `inventory[item_id]`
- `_on_menu_toolbox()`: `_close_all_panels()` + auto-selects first item + shows panel

**Main.gd — Boost strip (thin overlay)**
- `_build_boost_strip()`: CanvasLayer layer=8 (below HUD), 28px strip at `MINE_Y`; `HBoxContainer` for chips
- `_update_boost_strip()`: rebuilds chips from `GameState.active_boosts`; each chip shows symbol + seconds remaining in item's colour; strip hidden when no boosts active; called on item use and every 1 s from `_process()`

**MORE menu / shortcuts**
- `SHORTCUT_DEFS` now has 12 entries including `"toolbox"` (orange)
- MORE menu grid expanded to 3×4 (11 items): MINE, BUILD, CRAFT, SELL, CREW, SKYLINE, UPGRADES, CONTRACT, SHOP, MISSIONS, TOOLBOX

### Currently in progress / left mid-task
Nothing — all functions implemented.

### Next step
1. Open Godot, confirm 0 parser errors
2. Open TOOLBOX from the MORE menu or quick bar — 8 item cells should appear in a 3-column grid
3. Tap a cell — detail footer updates with item name, desc, owned count; BUY button shows gem cost
4. Buy an item (need gems) — count badge increments, USE button enables
5. Use a timed boost — boost strip appears at top of mine area with countdown chip
6. Use TNT Charge — all nodes clear and respawn immediately
7. Commit once testing passes

---

## 2026-06-29 — Toolbox float button + integer division fixes

### Completed this session
- **Floating TOOLS button**: CanvasLayer layer=9 (below HUD, above boost strip), positioned bottom-right of mine area; orange 60×60 square with ⚒ symbol and "TOOLS" sub-label; taps open the toolbox panel
- **Toolbox redesigned as bottom sheet**: panel now covers bottom 42% of screen (SHEET_Y=700, SHEET_H=480) leaving mine visible above; scrim above is tappable to dismiss; matches IOM visual style
- **Toolbox cells redesigned**: compact 80px cells — rarity strip at top (not left), 38×38 symbol square centred, right/bottom border separators, count badge bottom-right
- **Integer division**: 22 warnings → 0 across Main.gd and MissionManager.gd (18 in first pass, 5 more in second)
  - Pattern: `/2` → `/2.0`, `/ int` → `int(/ float(int))`
  - Unused variable `ref_ids` renamed to `_ref_ids`; unused `node_name` param renamed to `_node_name`
- **Git committed** (phase checkpoint): clean commit message referencing toolbox phase

---

## 2026-06-29 — Blueprint & Permit system

### Completed this session

**New files**
- `scripts/autoload/BlueprintDatabase.gd`: 23 blueprints (8 raw materials, 4 refined, 8 buildings, 3 general) + 4 permits; `FRAGMENTS_PER_LEVEL=[3,5,8,12,20]`, `BONUS_PER_LEVEL=0.08`; public API: `get_blueprint`, `get_all_by_category`, `get_permit`, `fragments_for_next_level`, `total_bonus`, `mat_drop_id`, `building_drop_id`, `craft_drop_id`

**Updated autoloads**
- `GameState.gd`: added `blueprints: Dictionary` (bp_id → {level, fragments}), `permits: Array`; helpers `get_mat_yield_mult(mat_id)`, `get_building_cash_mult(tier_id)`, `has_permit(permit_id)`
- `SaveManager.gd`: saves/loads `blueprints` and `permits`; `_init_fresh_state` zeroes both
- `BuildDatabase.gd`: added `TIER_PERMIT_REQUIRED` const dict (tiers 4–8 → their permit); `get_permit_required(tier_id)`, `is_tier_unlocked(tier_id)` helpers
- `project.godot`: `BlueprintDatabase` registered after `ToolboxDatabase`

**Main.gd changes**
- `SHORTCUT_DEFS`: `"blueprints"` added (📐 symbol, cyan colour)
- Member vars: `_blueprints_panel`, `_bp_scroll_content`
- `_ready()`: calls `_build_blueprints_panel()`
- `_close_all_panels()`: hides `_blueprints_panel`
- `_shortcut_color()` + `_on_shortcut_pressed()` + `_on_menu_blueprints()` added
- `_break_node()`: 15% chance to call `_award_blueprint_fragment(mat_drop_id(mat))`
- `_complete_stage()`: 30% chance to call `_award_blueprint_fragment(building_drop_id(tier_id))`
- `_on_craft_one()`: 20% chance to call `_award_blueprint_fragment(craft_drop_id(ref_id))`
- `_complete_building()`: calls `_check_permit_awards()` after skyline.append; permit gating added to tier-advance check via `BuildDatabase.is_tier_unlocked(next_id)`
- `_build_blueprints_panel()`: full-screen CanvasLayer 22 with header + ScrollContainer
- `_update_blueprints_panel()`: rebuilds all 23 blueprint cards in 2-col grid per category + 4 permit cards; level dots, fragment bar, rarity colours, permit completion progress bar
- `_award_blueprint_fragment(bp_id)`: adds 1 fragment, levels up on threshold, shows flash feedback
- `_check_permit_awards()`: iterates PERMITS, counts skyline completions of unlock_tier, awards permit if ≥ required

### Currently in progress / left mid-task
Nothing — all functions implemented.

### Next step
1. Open Godot, confirm 0 parser errors
2. Open BLUEPRINTS from MORE menu or quick bar — panel should show 4 category sections + permits
3. Break a node — 15% chance; flash "Blueprint levelled up!" on threshold
4. Complete 3 Two-Storey Houses — "Permit earned! Commercial Permit" flash; Apartment Block and Retail Unit now accessible
5. Confirm permit wall shows for locked tiers (no permit yet) and bypasses once earned
6. Commit once testing passes

---

## 2026-06-29 — Build section overhaul (IOM Obelisk-inspired)

### Completed this session

**Goal:** Make the BUILD section feel like a meaningful main goal rather than a passive side task.

**BuildDatabase.gd**
- Added `TIER_REWARDS` const dict — per-tier tables with `stage_cash_base`, `stage_gems`, `complete_cash`, `complete_gems`, `first_gems`, `income_per_min`
  - Scales from Shed (100 cash/stage, 2/min income) to Skyscraper (80k cash/stage, 3000/min income)
- Added `get_tier_rewards(tier_id) -> Dictionary` helper

**GameState.gd**
- Added `var first_completions: Array` (permanent; survives prestige)
- Added `get_property_income_rate() -> float` — sums `income_per_min` for every tier in `skyline`

**SaveManager.gd**
- Saves/loads `first_completions` in `save_game` + `load_game` + `_init_fresh_state`
- NOT reset in `prestige_reset()` (permanent like artifacts)

**Main.gd**
- New member vars: `_lbl_build_cooldown`, `_lbl_property_income`, `_property_income_accum`, `_build_panel_timer`
- `_build_build_panel()`: added cooldown label (y=780, amber, replaces start button during cooldown) + property income label (y=960, dim, always visible when panel open)
- `_process()`: calls `_tick_property_income(delta)`; refreshes cooldown label every second while build panel is open
- `_complete_stage()`: scaled cash + gems from `TIER_REWARDS`; applies 10-min site prep cooldown (`stage_cooldown_until = now + 600`)
- `_complete_building()`: scaled cash + gems; awards one-time `first_gems` bonus on tier's first-ever completion; appends to `first_completions`
- `_on_start_stage_pressed()`: blocked if `stage_cooldown_until > now`
- `_update_build_panel()`: shows cooldown label + countdown during site prep; property income rate always shown; buttons hidden during cooldown
- `_tick_property_income(delta)`: accumulates fractional cash per frame, awards whole cash chunks, calls `_update_hud()`
- `_refresh_build_cooldown_label()`: formats MM:SS countdown; auto-triggers `_update_build_panel()` when cooldown expires

### Currently in progress / left mid-task
Nothing — all 4 features implemented.

### Next step
1. Open Godot — confirm 0 parser errors
2. Complete a stage — verify scaled reward (not flat 25–65 cash), check cooldown label appears with countdown
3. Wait or temporarily reduce cooldown to 0 — verify start button returns
4. Complete a full shed — verify bigger cash/gems reward; "⭐ First build bonus" flash on first-ever shed
5. Build a second shed — confirm no first bonus the second time
6. Check BUILD panel footer shows "🏘 Build your skyline..." or income rate once shed in skyline
7. Commit once all checks pass

---

## 2026-06-30 — Skyline panel rebuild + backdrop spawn fixes

### Completed this session

**Skyline panel overhaul (Main.gd)**
- Added `_lbl_skyline_stats: Label` member var
- `_build_skyline_panel()`: stats label stored (replaces anonymous `sub` label); scroll starts at y=134
- `_update_skyline_panel()` fully rewritten:
  - Summary stats row: "X buildings • +X/min income" + all-time portfolio line
  - Buildings grouped by tier (first-seen order) with ×count badge
  - Each card: tier-colour accent bar, building name, count badge (amber), tier/income sub-line, ⭐ First build badge (gold), 🔨 Building now… indicator for active tier
  - Portfolio footer section if prior-contract buildings exist
- `_complete_building()`: calls `_update_skyline_panel()` immediately if panel is open

**Tree spawn area (Main.gd)**
- Added `LOCATION_SPAWN_BOUNDS` const dict; `_random_mine_pos()` uses location-specific Rect2 bounds
- Lumber Yard bounds: `Rect2(140, 360, 400, 310)` — inner rectangle of soil diamond, keeps trees off surrounding grass
- Tree sprite scale reduced to `randf_range(0.40, 0.60)` to match backdrop tree size

### Currently in progress / left mid-task
Nothing.

### Next step
1. Open Godot — confirm 0 parser errors
2. Open SKYLINE panel — check stats summary, cards show tier/income/count/first-build badge correctly
3. Complete another building while Skyline is open — confirm it updates live
4. Start new contract (prestige) — confirm "All-time portfolio" footer appears on next run
5. Commit once verified

---

## 2026-06-30 — Branching skill tree

### Completed this session

**SkillDatabase.gd** (new autoload, registered in project.godot)
- 15 skill nodes across 3 branches (Carpentry / Masonry / M&E), 5 nodes each
- Linear prerequisites (node N requires node N-1)
- 1 SP per skill, 1 SP awarded per player level-up
- Effects: mine_power_pct, worker_rate_pct, build_progress_pct, stage_cash_pct, double_craft_chance, drop_bonus, build_power_pct, xp_pct
- Public API: get_branch(), get_skill(), get_all(), can_purchase(), get_total_effect_bonus()

**GameState.gd**
- Added `skill_points: int` and `skill_tree: Dictionary`
- Added `get_skill_bonus(effect) -> float` (delegates to SkillDatabase)
- Wired skill bonuses into ALL 7 multiplier functions:
  - get_mine_power() — mine_power_pct
  - get_worker_rate_mult() — worker_rate_pct
  - get_drop_bonus() — drop_bonus
  - get_xp_mult() — xp_pct
  - get_stage_cash_mult() — stage_cash_pct
  - get_build_power() — build_power_pct
  - get_double_craft_chance() — double_craft_chance
  - get_build_progress_mult() — build_progress_pct

**SaveManager.gd**
- Saves/loads skill_points + skill_tree
- Both zeroed in _init_fresh_state() and prestige_reset()
- skill_tree resets on prestige (skills are per-contract, SP resets too)

**Main.gd — UPGRADES panel overhaul**
- Added GENERAL / SKILLS tab buttons below panel header (y=82)
- GENERAL tab: existing upgrade cards (unchanged)
- SKILLS tab: 3-column layout (one column per branch)
  - SP counter row at top: "Skill Points available: N"
  - Per branch: coloured header (name + subtitle) + 5 stacked skill cards + ▼ arrows
  - Skill cards: name, desc, state bar, 1 SP cost, BUY button
  - Purchased: green state bar, "✓ Learned", button disabled
  - Unlockable: accent bar, "1 SP" in gold, BUY enabled
  - Locked: grey bar, "Locked"/"Need SP", disabled
- `_on_skill_buy(skill_id)`: deducts SP, marks tree, refreshes tab, flashes skill name
- `_on_level_up()`: awards +1 SP, flash message updated to include "(+1 SP)"
- `_update_skills_tab()` called when opening upgrades, switching to SKILLS tab, after buy, after level-up

### Currently in progress / left mid-task
All changes implemented. Needs Godot reload + test.

### Next step
1. Open Godot — confirm 0 parser errors
2. Level up a few times — check SP counter increases in UPGRADES > SKILLS
3. Buy first node in each branch — verify unlocked states cascade correctly
4. Confirm bought skills actually affect gameplay (mine hits harder, worker rate increases, etc.)
5. Prestige → confirm skill_tree and skill_points both reset to 0
6. Commit once verified

---

## 2026-06-30 — Trade Shows

### Completed this session

**TradeShowDatabase.gd** (new autoload, registered in project.godot)
- 4 rotating events: Foundation Fair, High Rise Showcase, Materials Expo, Blueprint Awards
- 7-day duration each (28-day full cycle, back-to-back)
- 3 tasks per event; task types: complete_builds_any, break_nodes, earn_stage_cash, complete_tier_min
- 3 reward tiers per event (gems only): T1=20-30, T2=45-65, T3=80-120 gems scaling by event difficulty
- `tier_index()` helper uses BuildDatabase.TIER_ORDER for complete_tier_min comparisons

**GameState.gd**
- Added `trade_show_state: Dictionary` (event_index, expires_at, task_progress, claimed_rewards)

**SaveManager.gd**
- Saves/loads trade_show_state; resets in _init_fresh_state() and prestige_reset()

**project.godot**
- Registered TradeShowDatabase after InspectionDatabase

**Main.gd**
- SHORTCUT_DEFS: added "tradeshow" (★ symbol, gold color)
- Menu overlay: added "TRADE SHOW" entry
- _shortcut_color() / _on_shortcut_pressed(): wired
- _close_all_panels(): hides _tradeshow_panel
- Member vars: _tradeshow_panel, _lbl_ts_event_name, _lbl_ts_desc, _lbl_ts_timer, _ts_task_cards, _ts_reward_cards, _ts_panel_timer
- _process(): refreshes trade show timer label every second while panel is open
- Progress hooks:
  - _complete_building() → _ts_progress("complete_builds_any") + _ts_progress("complete_tier_min")
  - _break_node() → _ts_progress("break_nodes")
  - _complete_stage() → _ts_progress("earn_stage_cash")
- _build_tradeshow_panel(): full-screen panel with event header, 3 task cards, 3 reward tier cards
- _ts_start_new_event(): advances event_index, resets progress + claimed_rewards, sets expires_at
- _ts_is_active() / _ts_ensure_active(): guard called before any panel update or progress write
- _ts_progress(type, value, tier_id): increments matching task progress, refreshes panel if open
- _ts_completed_task_count(): counts fully completed tasks for reward unlock gating
- _update_tradeshow_panel(): fills event name/desc/timer, task progress bars + done badges, reward claim buttons
- _refresh_ts_timer_label(): Xd Xh Xm countdown format
- _on_ts_claim(tier_idx): awards gems, marks reward as claimed, flashes feedback
- _on_menu_tradeshow(): close all panels → ensure active → update → show

### Currently in progress / left mid-task
All changes implemented. Needs Godot reload + test.

### Next step
1. Open Godot — confirm 0 parser errors
2. Open TRADE SHOW from menu or ★ shortcut — see current event name, 7-day countdown, 3 tasks
3. Complete a building → task "Complete X buildings" increments
4. Break nodes → task "Break X nodes" increments
5. Complete a Two-Storey House → "complete_tier_min" task increments if event has one
6. Claim T1 reward (1 task done) → gems added, button changes to ✓ Claimed
7. Wait for event expiry (or temporarily shorten EVENT_DURATION_DAYS to 0.001 for testing) → new event starts
8. Prestige → trade_show_state resets
9. Commit once verified

---

## 2026-06-30 — Site Inspections

### Completed this session

**InspectionDatabase.gd** (new autoload, registered in project.godot)
- 16 inspections: 2 per tier × 8 tiers
- Condition types: "no_skip" (Clean Build — no gem stage-skip) and "speed" (Fast Track — under time limit)
- Speed limits: 2× minimum cooldown time per tier (e.g. Shed 60 min, Skyscraper 180 min)
- Rewards: blueprint fragments (for that tier's building blueprint) + gems — scale with tier difficulty

**GameState.gd**
- Added `completed_inspections: Array` (permanent, survives prestige like first_completions)

**SaveManager.gd**
- Saves/loads `completed_inspections` in save_game + load_game + _init_fresh_state
- NOT reset in prestige_reset() (permanent across all contracts)

**project.godot**
- Registered `InspectionDatabase` after SkillDatabase

**Main.gd**
- `_on_start_stage_pressed()`: records `build_started_at` timestamp and initialises `gem_skips_used = 0` in `current_building` when first stage (index 0) starts — only once per build
- `_on_stage_skip_pressed()`: increments `current_building["gem_skips_used"]` on every gem skip
- `_complete_building()`: calls `_check_inspections(tier_id)` before resetting current_building
- `_check_inspections(tier_id)`: evaluates all uncompleted inspections for the tier, marks them done, calls `_grant_blueprint_fragments()`, awards gems, shows flash feedback
- `_grant_blueprint_fragments(bp_id, count)`: silent multi-fragment award with correct level-up loop
- MISSIONS panel: added "SITE INSPECTIONS" section below Weekly Missions with a subtitle explaining permanence; 16 inspection cards; green accent strip + "✓ PASSED" badge on completion
- `_make_inspection_card()`: builds one card (tier label, name, desc, reward, done badge)
- `_update_inspections_section()`: refreshes all card colours and done badges
- `_on_menu_missions()`: calls `_update_inspections_section()` when panel opens

### Currently in progress / left mid-task
All changes implemented. Needs Godot reload + test.

### Next step (superseded — see Trade Shows below)
1. Open Godot — confirm 0 parser errors
2. Open MISSIONS panel — scroll to bottom to see SITE INSPECTIONS section with 16 cards
3. Start a Shed build WITHOUT using gem skip → complete it → "Inspection Passed: Clean Build" flash; open MISSIONS → Shed Clean Build shows ✓ PASSED
4. Start another Shed build, use gem skip → complete → confirm Clean Build is not re-awarded (already passed) and Speed build doesn't trigger (no timestamp set trick)
5. Check blueprint fragments were actually awarded (BLUEPRINTS panel → Shed Blueprint level/fragments increased)
6. Confirm completed_inspections survives prestige
7. Commit once verified
