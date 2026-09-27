# Project Contractor — Progress Log

## Session 11 — 2026-09-27

### Completed
- **Animated icons in exports**: the MORE-menu icons and the chest/delivery opening popup listed frames with `DirAccess`, which finds no `.png` files in an APK (only the `.import` remaps are packed). Both now share `_load_anim_frames()`, which uses `ResourceLoader.list_directory()`. New test `test_anim_frames_load_without_source_pngs` rebuilds the exported layout (`.import` files only) and checks the frames load in order (17 tests).

### Next Step
- Install Godot 4.7.1 export templates (only 4.6.1 installed), then build an APK and confirm the animated icons play on device.

## Session 10 — 2026-09-27

### Completed
- **Godot 4.7.1 upgrade**: project runs with no parse/runtime errors. Full code audit done.
- **Test suite**: `tests/test_runner.gd` (16 headless tests, isolated test save). Excluded from export.
- **Save safety**: saves write to `save.json.tmp` then swap in; the previous save is kept as `save.bak.json`. Unreadable saves are copied to `save.corrupt.json` and the game restores from the backup instead of starting fresh.
- **Save types**: counts (materials, upgrades, utilities, missions, blueprints, crew levels, trade show) reload as ints — UTILS badges no longer show "200.0".
- **Bug fixes**:
  - Contract panel crashed once the portfolio was non-empty (`t.has()` on a Resource).
  - Prestige left `active_node_count` at the old value; now resets, and load derives it from the Extra Node Slot level (repairs existing saves).
  - Trade Show rewards could be re-claimed after prestige; trade show state now survives prestige.
  - Copper blueprint id was `bp_copper` but the material is `copper_ore`, so it never dropped.
  - Material blueprints (+8%/level yield) were never applied; now apply to node drops, crafting and offline gains via `GameState.roll_yield()`.
  - Experienced Crew artifact had no effect; hires now start at `get_crew_start_level()`.
  - Site Inspection fragment rewards were discarded before 15 buildings; now always granted.

### Next Step
- Install Godot 4.7.1 export templates (only 4.6.1 installed).
- Replace `DirAccess` icon-frame listing with `ResourceLoader.list_directory()` before the next APK build (source PNGs aren't in exports).

## Session 9 — 2026-07-07

### Completed
- **Const→var fixes**: Five local `const` variables inside functions (`SY`, `SH`, `BY`, `NW_Y`, `POP_Y`) that referenced now-`var` layout constants were changed to `var`. Cleared downstream "Nil operand" Vector2 errors.
- **Colour palette consolidation**: Reduced accent colours to 3 — Primary `C_GOLD`, Alert `C_ALERT` (costs/warnings), gem currency `C_GEM`. All panel headers unified to `C_GOLD`. `_shortcut_color()` collapsed to always return `C_GOLD`. Added `C_ALERT = Color(1.00, 0.45, 0.15)` constant.
- **MORE menu icon-grid redesign (IOM-style)**: `_rebuild_menu_items()` completely replaced with a 4-column icon grid using sections (DAILY WORK / PROGRESS / ITEMS & MORE). Each cell has an 82×82px icon background with a gold top bar, icon/initials, and name label. Locked items shown dimmed.
- **SHOP item added to menu**: `_on_menu_shop()` added; SHOP item in DAILY WORK section with chest icon.
- **Animated chest icon (SHOP)**: SHOP icon path changed from static PNG to `res://assets/sprites/ui/menu/chest/` (animation directory). Icon rendering now detects paths ending with `/` and builds an `AnimatedSprite2D` from all PNGs in the directory (sorted alphabetically = frame order). 10 fps, looping. Falls back to static TextureRect or initials if animation fails. 11 frames at `assets/sprites/ui/menu/chest/Metal Chest - frame  0N.png`.

### Additional work (session 9 continued)
- **Animated chest fixed**: `AnimatedSprite2D` (Node2D) inside Control caused invisible sprite. Replaced with `TextureRect` + `Timer` (pure Control nodes). Shows frame 0 on open, starts cycling on tap.
- **Chest icon moved to CHEST button** (not SHOP — user correction).
- **Icon size reduced 25%**: `anim_sf * 0.75` applied to animated icon scale.
- **Chest opening popup**: New `_show_animated_opening_popup(anim_dir, reward_lines, accent)` — plays animation centred on screen, rewards below, COLLECT button. Plays once at 5fps (0.2s/frame), holds last frame. Both vintage chest and delivery pallet use it.
- **Delivery animation**: Added `assets/sprites/ui/menu/delivery/` (5 frames: Golden Chest 3). DELIVERY menu icon and pallet opening popup both use it.
- **DELIVERY menu icon** wired to `res://assets/sprites/ui/menu/delivery/` (animated).
- **BLUEPRINTS icon**: Static `blueprints/blueprint.png`.
- **SELL icon**: Static `sell/sell.png`.
- **Gem HUD chip**: Replaced `◆` text symbol with `sell.png` icon (TextureRect, left side of chip) + right-aligned number label. `_update_hud()` now writes plain number (no ◆ prefix).

### In Progress / Next Step
- Open Godot — confirm 0 parser errors.
- Check HUD: gem chip should show sell.png icon + number.
- Open MORE menu: DELIVERY, CHEST show animations on tap; BLUEPRINTS and SELL show static icons.
- Open CHEST → OPEN: animated chest plays once, rewards below.
- Git commit once confirmed.

---

## Session 8 — 2026-07-06

### Completed
- **DPI-aware UI scaling**: Added `var UI_SCALE: float = 1.0` class var to Main.gd.
- In `_ready()`, compute `UI_SCALE = clamp(screen_get_dpi() / 300.0, 1.0, 1.5)`.
  - S24 Ultra (~500 DPI): UI_SCALE ≈ 1.5 → elements 50% larger.
  - Desktop/editor (~96 DPI): clamped to 1.0, no change.
- Changed `HUD_H`, `BOTTOM_BAR_H`, `LOC_BAR_H`, `MINE_Y` from `const` to `var`.
- `BOTTOM_BAR_H` and `HUD_H` scaled by `UI_SCALE` (HUD capped at 1.25×) in `_ready()`.
- `MINE_Y` and `MINE_H` recomputed after scaling.
- Added `_apply_global_font_scale()`: post-build scan that multiplies all explicit
  `font_size` overrides on Labels and Buttons by `UI_SCALE`. Called after `_apply_global_font()`.

### In Progress / Next Step
- Build and test on S24 Ultra to confirm UI elements are now a comfortable physical size.
- If still too small, increase the `300.0` divisor in the UI_SCALE formula (lower value → larger scale).
- If too large, increase the divisor or reduce the `1.5` cap.
- Consider git commit once confirmed working on device.


---

## 2026-07-06 (session 7) — Mobile UI scaling fix (Samsung S24 Ultra)

### Problem
UI and buttons appeared far smaller on device than in the Godot editor. Root cause: Godot was either not applying the canvas_items stretch correctly, or `DisplayServer.window_get_size()` was returning physical pixels (1440×3088) which caused UI coordinate mismatch.

### Completed

**project.godot**
- Added `window/size/mode=4` (exclusive fullscreen) — bypasses Samsung OneUI window chrome and forces true fullscreen
- Added `window/dpi/allow_hidpi=true` — Godot now renders at the native device resolution without OS-level downsampling
- Added `window/stretch/scale=1.0` (explicit, was defaulting implicitly)

**Main.gd — `_ready()`**
- Replaced `DisplayServer.window_get_size()` with `get_viewport().get_visible_rect().size`
- Added `await get_tree().process_frame` before reading so the viewport is fully sized before any UI builds
- `get_visible_rect().size` always returns logical viewport coordinates after stretch scaling — correct on all screen densities without any manual calculation
- Old manual formula `SCREEN_H = int(win.y * 720 / win.x)` removed

### Next step
1. Export APK and test on S24 Ultra — UI should fill the full screen at correct proportions
2. If still small: check Android export settings → Architectures (arm64), and verify `window/size/mode=4` takes effect
3. Git commit once confirmed working

## 2026-07-05 (session 6) — Locked upgrade hiding, skill tree icon redesign

### Completed this session

**Main.gd — locked upgrades now hidden (GENERAL tab)**
- Previously: locked upgrades showed a dim overlay with "Locked" text
- Now: locked cards + their separator lines are hidden entirely (`visible = false`) until the player hits the unlock level
- Added `"sep"` key to `_upgrade_card` dict so both the card and its separator toggle together

**Main.gd — skill tree redesigned (SKILLS tab)**
- Replaced tall rectangular cards (92px each, very crowded) with compact icon nodes
- Each node: 76×76px three-layer icon (shadow bg → coloured border → dark fill) + name label below
- State colours:
  - Purchased: border + fill glow in branch colour, "✓" in white
  - Unlockable: branch-colour border, dark tinted fill, initials in branch colour
  - Locked: near-invisible grey throughout
- Connector between nodes: 5px line + 12×8px mid-diamond indicator; lights up in branch colour when node above is purchased
- Branch headers: deeper dark background, 3px top accent + 2px left accent in branch colour
- Tap any node → bottom detail card shows: skill name, description, cost/state, BUY button
- Tapping left side of detail card dismisses it; switching to GENERAL tab hides it
- `_skill_initials()` helper: takes first letter of each word for 2-letter monogram
- `_build_skill_detail_card()` builds fixed 144px card outside the scroll area

**GameState.gd — type fix**
- `var bc := SkillDatabase.BRANCH_COLORS[...]` → `var bc: Color = SkillDatabase.BRANCH_COLORS.get(...)`
  (Dictionary lookup returns Variant; explicit type avoids "Cannot infer type" error)

### Next step
1. Open Godot — confirm 0 parser errors
2. GENERAL tab: upgrades you don't meet level for should be invisible
3. SKILLS tab: icon nodes display with correct states; tap a node → detail card appears; BUY purchases the skill
4. Buy a skill → node fills with branch colour, connector lights up, next node becomes available
5. Git commit

## 2026-07-05 (session 5) — Parser fixes, unlock badge, blueprint gate, chest display, boost chip redesign, Time Warp item

### Completed this session

**Main.gd — parser errors cleared (50+ errors)**
- `_wire_scroll_drag(sc)` — function was called 8× but never defined; added pass-through stub (Godot 4 handles ScrollContainer touch drag natively)
- `const SHEET_Y / BTN_Y / CARD_Y` → `var` — referenced class-level `var SCREEN_H/MINE_H` which aren’t compile-time constants
- `const DP_ACCENT := Color(0.90, 0.65, 0.20)` added at class scope before `_build_delivery_pallet_panel`
- `_update_delivery_pallet_panel` rewritten to use `GameState.pending_delivery_pallets: int` (universal counter) + `_on_open_delivery_pallet_btn()` — old per-location `pending_chests` dict loop removed

**Main.gd — waves-to-unlock badge fix**
- `_update_next_unlock_badge()` was showing "82 / 30 → Stone Quarry" even when Stone Quarry was already unlocked
- Now calls `_is_location_unlocked(next_id)` first and hides badge when already unlocked
- Shows "✔ Complete" in green if progress >= threshold (edge case before hide kicks in)

**Main.gd — blueprint fragment gate restored**
- `_award_blueprint_fragment()` and `_grant_blueprint_fragments()` were missing the `GameState.skyline.size() < 15` early return
- Gate re-added to both functions; no fragments drop before 15 buildings complete

**Main.gd — vintage chest modifier display**
- Modifier rows showed "? [COMMON]" because code used `mod.get("name", "?")` but ChestDatabase uses key `"label"`; fixed to `mod.get("label", "?")`
- Row label used `\U0001f381` (rendered as "dz81"); replaced with plain text — emoji already in panel header

**Main.gd — boost chip redesign**
- Old: 72×20px flat rect with "E 48s" text
- New: 158×52px styled card with left accent bar, large symbol, item name, countdown timer ("Xs" / "Xm Ys"), and depleting progress bar across bottom
- Strip height increased 28px → 64px; added 1px border at base
- Progress bar calculated from `chip_dur` (ToolboxDatabase item duration) vs remaining seconds

**ToolboxDatabase.gd — Time Warp item added (9th item)**
- `id: "time_warp"`, effect: `"game_speed"`, mult: 2.0, duration: 30s, gem_cost: 4, rarity: rare
- Hot-pink color (`Color(1.00, 0.30, 0.85)`), symbol "2x"

**GameState.gd — game_speed boost wired to all stats**
- `get_mine_power()`, `get_worker_rate_mult()`, `get_build_power()` all multiply by `get_boost_mult("game_speed")`
- `get_game_speed_mult()` helper added (delegates to `get_boost_mult("game_speed")`)
- Duplicate `get_game_speed_mult` at line 208 removed (Python script); single definition remains at line 208

**Main.gd — `_tick_game_speed_cooldowns(extra)` (new function)**
- Subtracts `delta * (mult - 1)` per frame from all timestamp-based cooldowns when Time Warp active
- Accelerates: `utility_recharge_at` per utility, `stage_cooldown_until` on current_building, `expires_at` on all non-game_speed active boosts

**Main.gd — `_process()` wired**
- Calls `_tick_game_speed_cooldowns(delta * (mult - 1))` each frame when `get_game_speed_mult() > 1.0`

### Next step
1. Open Godot — confirm 0 parser errors
2. Use an Energy Drink — boost chip should show styled card with name, symbol, timer, and progress bar depleting
3. Use Time Warp — all cooldowns (utility recharge, build site prep, other boosts) should run at 2× speed
4. Open VINTAGE TOOL CHEST panel — modifier names should show (e.g. "Mine Power +10%") not "?"
5. Check waves-to-unlock badge hides once you’ve crossed the threshold
6. Confirm blueprint fragments not dropping before 15 buildings
7. Git commit
## 2026-07-02 (session 4) — Accumulator popups, skyline level cap, file reconstruction

### Completed this session

**Main.gd — material popup → accumulator pattern**
- Replaced per-hit `_spawn_mat_popup` (individual fly-up labels) with `_add_mat_popup(mat, amount)` accumulator
- Count stacks for 5 seconds of idle: each new gain on the same material resets the 5s tween and updates the label text (`+N Material`)
- On idle expiry: label fades out over 0.5s then `queue_free`s and cleans up all three dicts (`_mat_accum`, `_mat_popup_labels`, `_mat_popup_tweens`)
- Labels positioned at left edge (x=12), stacked upward by slot index (32px gap), `MOUSE_FILTER_IGNORE`

**Main.gd — skyline level 10 gate**
- `_update_skyline_panel()`: `CONTRACT_MIN_LEVEL = 10`; `_btn_new_contract.visible` / `_lbl_new_contract_locked.visible` toggled based on `GameState.player_level >= 10`
- `_on_new_contract_pressed()`: early return guard if `GameState.player_level < 10`
- Prevents signing a new contract below level 10 regardless of UI state

**File reconstruction (Major)**
- Edit tool caused catastrophic truncation (8066→4872 lines) — entire middle section lost
- Rebuilt via Python: spliced HEAD git content (7800 lines) with all session changes
- Session-only functions reconstructed: `_add_mat_popup`, accumulator vars, `_update_skyline_panel` with level gate, `_on_new_contract_pressed` guard, `_build_utilities_panel`, `_update_utilities_panel`, `_on_menu_utilities`, `_update_vintage_chest_panel`, `_on_menu_vintage_chest`
- Duplicate `const UTIL_ACCENT` removed (HEAD already contained it)

**Parser fix — missing `for` loop header (line 4841)**
- After reconstruction, `_update_skyline_panel` was missing `for child in _skyline_list_box.get_children():` before `child.queue_free()`
- Caused: "Expected statement, found 'Indent'" at 4841, "Unexpected 'if' in class body" at 4846–4847
- Fixed via Edit tool; tail truncation restored via Python anchor script after each Edit call
- File confirmed at 8067 lines with correct `_on_menu_vintage_chest` tail

### Next step
1. Open Godot — confirm 0 parser errors
2. Mine nodes at active location — green "+X Material" popup should appear at left edge; rapid clicking stacks the count; 5s idle → fades
3. Open SKYLINE panel below level 10 — New Contract button hidden, locked label visible
4. Reach level 10 — New Contract button appears
5. Git commit

---

## 2026-07-02 (session 3) — Material gather popups, utilities overhaul, UTILS/TOOLS panel toggle

### Completed this session

**Main.gd — material gather side popups**
- Added `var _mat_popup_count: int = 0` instance var (stacking offset counter)
- Added `_spawn_mat_popup(mat, amount)`: spawns a small green Label at the left edge (x=12), stacked upward per active popup (28px gap), slides up 40px over 1.2s (QUAD OUT), fades out from 0.6s, `queue_free` + counter decrement at 1.5s
- Called in `_break_node()` alongside `_flash_feedback` when `loc_id == active_location_id`
- Truncation fix applied again after Python write (anchor: `_on_menu_vintage_chest() -> void:`)

**Main.gd — utilities panel + charge system (session 2 carry-over)**
- `ALL_UTIL_DEFS` array: 6 utilities — Blasting Cap (200 charges), Det Chord (x3 chain), Yield Charge (2x drop), Apprentice Notice (2x XP), Demolition Order (10x power), Supply Run (+2 all)
- Charge-based recharge: `utility_counts` dict, `utility_recharge_at` dict — ticks every 1s in `_process`
- Utilities panel: same tray design as toolbox, UTILS float hides TOOLS float when open, UTILS button shifts to TOOLS position (CanvasLayer.offset = Vector2(70,0)) while panel is open
- Effect functions: `_effect_blast_cap/det_chord/yield_charge/apprentice_notice/demo_order/supply_run`
- `_break_node`: consumes yield_charge_stacks (2x drop) and apprentice_notice_stacks (2x XP)
- `_close_all_panels` restores both float buttons and resets UTILS offset

**GameState.gd + SaveManager.gd — unified utility system**
- `utility_counts`, `utility_recharge_at`, `yield_charge_stacks`, `apprentice_notice_stacks` vars
- Save/load with migration from old `blast_cap_count` / `blasting_cap_cooldown_until` fields
- Fresh init sets blast_cap=200, all others to their defaults

### Next step
1. Open Godot — confirm 0 parser errors
2. Mine a node — green "+X Material" popup should appear at the left side and fade
3. Multiple quick breaks — popups should stack vertically without overlapping
4. Test UTILS button shifts to TOOLS position when utilities panel opens
5. Git commit

---

## 2026-07-02 (session 2) — UI polish: damage numbers, popups, toolbox redesign, parser fixes

### Completed this session

**Main.gd — skyline page**
- `_lbl_new_contract_locked` font colour forced to `Color.WHITE` so "Reach Level 10 to sign a New Contract" text is readable on the green button

**Main.gd — floating damage numbers**
- Added `_spawn_dmg_number(canvas_pos, dmg)` — creates a `Label` child on the CanvasLayer, animates it upward 58px over 0.75s (QUAD OUT) and fades to transparent starting at 0.12s, then `queue_free`s after 0.82s
- Called in `_apply_node_damage()` for both node-break and non-break hits; uses `_node_visuals[i]["container"].position` as anchor

**Main.gd — Quick Pin menu**
- Fixed "Done" button stuck mid-screen: `card_h` is now calculated dynamically from `rows_pre * tile_h_pre + (rows_pre-1)*pad_pre`, so card height expands with the grid
- `done_y` computed as `grid_y + float(rows) * tile_h + float(rows - 1) * float(pad) + 12.0` (was a hardcoded offset)

**Main.gd — wave-clear unlock popup**
- Added `_show_unlock_popup(next_loc_id)`: CanvasLayer layer 42, dim ColorRect with `MOUSE_FILTER_IGNORE`, 500×210px card at y=220 (upper third), tap-the-card-to-close
- Called from `_break_node` when `_wave_new_prog == _wthresh`
- Removed 🔓 emoji icon (rendered as "g13" fallback glyph in Godot's default font)

**Main.gd — tap-to-close on all popups**
- Stats panel: `bg_btn` Button covers full screen, `✕` removed
- Chest popup: `dim_btn` Button (full screen) closes on press; card has `MOUSE_FILTER_IGNORE`
- Offline gains popup: dim Button calls `_on_offline_collect`
- Unlock popup: card Button closes; dim has `MOUSE_FILTER_IGNORE` (card-only close)

**Main.gd — toolbox panel redesign**
- Rebuilt `_build_toolbox_panel()` as slim utilities-style tray (163px tall, no scrim, no ✕)
- Icon row is 640px wide (`SCREEN_W - 80`) leaving an 80px gap on the right where the TOOLS float button remains visible
- `_toolbox_float_cl.layer` raised from 9 → 25 (above tray at layer 23) so float button renders on top
- `_on_menu_toolbox()` is now a toggle: hides panel if visible, opens if hidden
- `_update_toolbox_panel()` updated — `count_lbl` removed from cells (null in new design)

**Main.gd — parser error fixes**
- File was truncated mid-line (at `mod_lbl.add_theme_`) inside `_update_vintage_chest_panel()`
- Restored correct tail: closing lines of `for mod` loop + `_on_menu_vintage_chest()` function
- `_on_menu_vintage_chest()` was the cause of "Identifier not declared in current scope" at line 1734

### Next step
1. Open Godot — confirm 0 parser errors
2. Test mine screen — damage numbers should float up on each hit
3. Open Quick Pin menu — Done button should be below the grid
4. Clear a wave — unlock popup should appear; tapping card should dismiss it
5. Open Toolbox — should show slim tray with TOOLS button visible in the 80px gap; tapping button again should close it
6. Git commit

---

## 2026-07-02 — Mobile scaling, code audit fixes, crew rework, UI clipping fixes

### Completed this session

**project.godot**
- Added `window/stretch/mode="canvas_items"` + `window/stretch/aspect="keep_width"` — game now fills any mobile screen width and expands height on tall phones instead of rendering at fixed 720×1280 in the corner

**Main.gd — dynamic screen height**
- `const SCREEN_H` → `var SCREEN_H: int = 1280` (dynamic)
- `const MINE_H` → `var MINE_H: int = 994` (dynamic)
- `_ready()` now reads `DisplayServer.window_get_size()` and calculates logical SCREEN_H and MINE_H before any UI is built
- Fixed three function-level `const` declarations that referenced the now-var SCREEN_H/MINE_H (`SHEET_Y`, `BTN_Y`, `CARD_Y` → all changed to `var`)

**Main.gd — code audit fixes (4 bugs)**
- `_update_craft_panel()` rewritten: now updates all 16 inventory labels and all 8 recipe cards (was only updating 4 labels and 2 cards)
- Blueprint fragment drops added to `_on_craft_all()` and `_on_craft_all_everything()` (was only in `_on_craft_one()`)
- `_mat_color()` extended: added "brick", "plaster", "aluminium" entries
- `_tier_colour()` extended: added apartment, retail, office, high_rise, skyscraper colours

**Main.gd — location picker panel**
- Rebuilt as full-width (was 660px on 720 screen causing text clipping and scrollbar overlap)
- `horizontal_scroll_mode = SCROLL_MODE_DISABLED` added
- VBox now uses `custom_minimum_size` instead of `size`
- Progress count label moved above bar with 100px width; bar extends full width minus padding
- `_on_loc_picker_open()` updated to pass `SCREEN_W` instead of hardcoded 660

**Main.gd — crew location picker**
- Rebuilt as full-width (was 580px card — same clipping issue)
- `_on_crew_move_pressed()` updated to pass `0, 0, SCREEN_W`

**Crew rework (3 files)**
- `CrewMemberResource.gd`: added `unlock_level: int = 1` export field
- `BuildDatabase.gd`: `_crew()` helper gains `unlock_lvl` param; `_register_crew()` updated with level gates:
  - Old Bob: Lv1, Granite Pete: Lv3, Nimble Nick: Lv5, Sandy Walsh: Lv7
  - Iron Mike: Lv10, Clay Molly: Lv13, Copper Carl: Lv16, Lime Larry: Lv19, Boxy Dave: Lv22
- `Main.gd`:
  - Removed: `_crew_loc_labels`, `_crew_move_btns`, `_crew_loc_picker`, `_crew_loc_picker_for`, `_crew_loc_rows_node` vars
  - Added: `_crew_lock_overlays: Array[Control]` (one dim overlay + lock label per card)
  - Removed: `_build_crew_loc_picker()`, `_rebuild_crew_loc_rows()`, `_on_crew_move_pressed()`, `_on_crew_loc_selected()` functions
  - `_build_crew_card()`: location badge static (no array), hire/upgrade buttons full-width (no move button), lock overlay added
  - `_update_crew_panel()`: shows/hides lock overlay per card based on `player_level >= unlock_level`; skips button updates for locked cards
  - `_on_hire_pressed()`: guards against locked crew

### Next step
1. Open Godot — confirm 0 parser errors
2. Test on device — game should fill the full screen
3. Open Crew panel — Old Bob available at start, Granite Pete locked until Lv3, etc.
4. Reach Lv3 — confirm Granite Pete unlocks automatically (overlay hides, hire button appears)
5. Open craft panel — all 8 recipe cards should show live "Will make:" counts
6. Check location picker — full width, no text clipping, progress numbers visible
7. Commit

---

## 2026-07-01 — Big batch: wave-clear unlocks, hold-to-mine, Blasting Cap, chest system, 18 intro tasks, build cooldown fix, menu restructure

### Completed this session

**BuildDatabase.gd**
- `LOCATION_UNLOCK_NODES` thresholds updated to wave-clear counts: `[30, 78, 126, 174, 222, 270, 318]`
- Comment updated: "A 'clear' = all nodes on screen destroyed in one wave"

**UpgradeDatabase.gd**
- Upgrade name `"Sharper Tools"` → `"Upgrade Tools"` (id `sharper_tools` unchanged)

**GameState.gd**
- Added tutorial counters (permanent): `timber_collected`, `sand_collected`, `lumber_crafted`, `materials_sold`, `visited_stone_quarry`, `visited_sand_pit`, `blasting_caps_fired`, `blasting_cap_cooldown_until`, `toolbox_items_used`, `delivery_pallets_opened`, `vintage_chests_opened`
- Added chest system: `pending_chests: Dictionary`, `chest_modifiers: Array`, `get_chest_modifier_bonus(effect)`
- Wired `get_chest_modifier_bonus()` into: `get_mine_power`, `get_drop_bonus`, `get_xp_mult`, `get_stage_cash_mult`, `get_worker_rate_mult`, `get_build_power`

**SaveManager.gd**
- All new fields saved/loaded/init-fresh'd

**ChestDatabase.gd** (new autoload, registered in project.godot)
- 13 modifiers across common/uncommon/rare rarities (mine power, XP, drop bonus, cash, worker rate, build power)
- `RARITY_WEIGHTS: {common:60, uncommon:30, rare:10}`
- `roll_modifier()` — weighted random selection; `rarity_color(rarity)` helper

**project.godot**
- `ChestDatabase` registered as autoload

**Main.gd (major changes)**
- `_break_node()`: removed per-node `location_unlock_progress` increment; added `timber_collected`/`sand_collected` tracking; wave-clear increment moved inside `if all_clear` block; `_update_chest_btn()` called after every break
- `_spawn_wave()`: added chest spawn logic (12% chance per wave clear, 25% vintage chest / 75% delivery pallet); updates chest button if active location
- `INTRO_TASKS` replaced: 10 old tasks → 18 new tasks (timer-based _congrats screen at end)
- `_intro_task_value()` rewritten for all new keys
- `_update_intro_strip()`: special handling for `_congrats` key — 4-second auto-hide via `create_timer`
- `_on_location_btn()`: tracks `visited_stone_quarry` / `visited_sand_pit`
- `_on_sell_pressed()`: increments `materials_sold`
- `_on_craft_one/all()`: increments `lumber_crafted`
- `_on_use_item()`: increments `toolbox_items_used`
- `_complete_stage()`: build cooldown removed from here
- `_complete_building()`: `stage_cooldown_until` set for full building completion only
- Hold-to-mine: `MINE_HOLD_INTERVAL=0.35s`, `_mine_hold_active`, `_mine_hold_timer`; `_on_mine_hold_start/stop()` wired to `button_down`/`button_up`; `_close_all_panels()` resets `_mine_hold_active`
- Blasting Cap: `BLAST_COOLDOWN=30.0`, `_btn_blast_cap`, `_lbl_blast_cooldown`, `_blast_flash`; `_on_blast_cap_fire()`, `_update_blast_cap_btn()` piggybacking on boost-strip 1s timer tick
- Chest system: `CHEST_SPAWN_CHANCE=0.12`, `_btn_chest`, `_chest_popup`; `_update_chest_btn()`, `_on_chest_open()`, `_open_delivery_pallet()`, `_open_vintage_chest()`, `_show_chest_popup()`; `_update_chest_btn()` also called from `_update_mine_screen()` so chest visibility is correct on location switch
- Menu restructure: removed MINE/TOOLBOX/TRADESHOW/SHOP; added SKILL TREE (locked < 4 buildings); MISSIONS locked < 10 buildings; BLUEPRINTS locked < 15 buildings; `_rebuild_menu_items()` called on each open so lock states are always current; locked items show 🔒 label + disabled button
- `_on_menu_skill_tree()`: opens UPGRADES panel on SKILLS tab

### Currently in progress / left mid-task
All changes implemented. Needs Godot reload + test.

### Additional changes (2026-07-02 — code review + fixes)

**Main.gd — 4 bugs fixed from code audit**

1. `_update_craft_panel()` rewritten — now updates all 16 inventory grid labels and all 8 recipe cards (yield labels + Craft 1 / Craft All button states). Previously only updated 4 labels and 2 cards; cards 3–8 were permanently stuck at "Will make: 0" with buttons disabled.

2. Blueprint fragment drops added to `_on_craft_all()` and `_on_craft_all_everything()` — one 20% roll per base craft, matching the existing `_on_craft_one()` behaviour. Previously bulk crafting never awarded blueprint fragments.

3. `_mat_color()` extended — added entries for "brick" → `C_BRICK`, "plaster" → `C_PLASTER`, "aluminium" → `C_ALUMINIUM`. Previously these fell through to `C_TEXT` (white).

4. `_tier_colour()` extended — added colour entries for apartment, retail, office, high_rise, skyscraper. Previously all five returned grey.

### Next step
1. Open Godot — confirm 0 parser errors
2. Open Craft panel — all 8 recipe cards should show live "Will make:" counts and enabled buttons
3. Craft using individual buttons and ⚡ CRAFT ALL — verify all inventory grid cells update (including sand/glass, steel_ore/steel_beam etc.)
4. Commit

---

### Additional changes (2026-07-01 continuation session)

**Button press animations**
- Added `_make_animated_btn()` and `_wire_btn_anim()` helpers — scale-bounce on every button press (0.92× in 70ms, spring back 120ms)
- Added `_wire_cell_anim(cell, btn)` for flat overlay buttons — animates the parent wrapper Control so visible siblings (bg + label) also bounce
- All `Button.new()` calls replaced with `_make_animated_btn()` (56 buttons total)
- Pin slots, menu grid items, toolbox cells, and utilities icon wrapped in Control nodes so animation affects full card visuals

**Item stacking fix**
- `_on_use_item()`: using the same toolbox item while a boost is active now stacks additively (extends timer by new duration + remaining; multiplier adds `mult - 1` per use)
- Flash feedback now shows stacked multiplier and total remaining seconds

**Blueprint Fragment gate**
- `_award_blueprint_fragment()` and `_grant_blueprint_fragments()` now early-return if `GameState.skyline.size() < 15`

**Unlock badge "Complete"**
- `_update_next_unlock_badge()`: when `progress >= threshold`, shows `✔ Complete` in green instead of raw overflow number

**HUD material chip fix**
- `_update_hud()` now refreshes `_lbl_active_mat` with current material count + color (was stuck at "0 Timber" forever)

**Chest system refactor — universal chests**
- `GameState.pending_chests: Dictionary` replaced with `pending_delivery_pallets: int` + `pending_vintage_chests: int`
- SaveManager updated for new fields
- Spawn: chests now increment a universal counter instead of being tied to a location
- `_on_chest_open_at(loc_id)` replaced with `_on_open_delivery_pallet_btn()` / `_on_open_vintage_chest_btn()`
- Delivery Pallet panel: single row "📦 N Delivery Pallets" + OPEN button
- Vintage Chest panel: single row "🎁 N Vintage Tool Chests" + OPEN button

**Vintage chest modifier display**
- Fixed `mod.get("name")` → `mod.get("label")` (key was wrong)
- Modifiers now grouped by `id`, values summed, sorted rare→uncommon→common
- Display shows stacked total: e.g. "• XP Gain +40%  [RARE]  ×2" instead of two separate rows

### Next step
1. Open Godot — confirm 0 parser errors
2. Test button bounce on bottom bar, menu grid, toolbox cells, utilities icon
3. Use same toolbox item twice — multiplier should stack (e.g. "Mining Frenzy ×3.0 for 90s!")
4. Confirm blueprint fragments not dropping before 15 buildings
5. Unlock badge: check it shows "✔ Complete" when wave clears exceed threshold
6. HUD chip top-right: verify updates live as you mine/sell materials
7. Clear a wave — chest counter increments; open from DELIVERY PALLETS / VINTAGE CHEST menu
8. Open vintage chest twice for same modifier — panel should show single stacked row (e.g. "Mine Power +10%  ×2")
9. Commit once verified

---

## 2026-06-30 — Location Unlock System

### Completed this session
- **BuildDatabase.gd**: Added `LOCATION_UNLOCK_NODES` const array (thresholds: 50/80/100/120/150/200/250)
- **GameState.gd**: Added `location_unlock_progress: Dictionary`
- **SaveManager.gd**: Save/load + `_init_fresh_state` + `prestige_reset` all wired (resets on prestige)
- **Main.gd**:
  - `_break_node()`: increments `location_unlock_progress[loc_id]` on every break
  - `_is_location_unlocked(loc_id)`: checks prev location's progress vs threshold
  - Loc picker: locked rows show dim overlay, greyed name, "Break X nodes at Y" requirement, progress bar + count
  - Loc picker: rebuilds on every open (`_rebuild_loc_picker_rows`) so progress stays current
  - Crew loc picker: filters to unlocked-only, rebuilds on open (`_rebuild_crew_loc_rows`)
  - `_on_location_btn`: guards against selecting locked locations

### Currently in progress / left mid-task
All code done. Needs Godot reload + test.

### Next step
1. Reload project → 0 parser errors
2. Fresh save → only Lumber Yard available, Stone Quarry shows progress bar at 0/50
3. Break 50 trees → Stone Quarry unlocks (open picker to verify)
4. Crew MOVE button → only Lumber Yard listed until Stone Quarry unlocks
5. Prestige → location_unlock_progress resets, back to Lumber Yard only
6. Commit once verified

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
