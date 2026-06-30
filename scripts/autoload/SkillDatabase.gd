extends Node
## Defines the three-branch skill tree for Project Contractor.
## Skills are purchased one at a time with Skill Points (1 SP per player level).
## Each branch is linear: node N requires node N-1 to be purchased first.
##
## Autoload order: after UpgradeDatabase, before Main.

## Branch colour accents (used in UI).
const BRANCH_COLORS: Dictionary = {
	"carpentry": Color(0.85, 0.55, 0.20),   # timber orange
	"masonry":   Color(0.65, 0.65, 0.70),   # stone grey
	"me":        Color(0.30, 0.70, 1.00),   # electric blue
}

## Branch display names.
const BRANCH_NAMES: Dictionary = {
	"carpentry": "Carpentry",
	"masonry":   "Masonry",
	"me":        "M&E",
}

## Branch subtitles.
const BRANCH_SUBTITLES: Dictionary = {
	"carpentry": "Timber · Framing · Finishing",
	"masonry":   "Stone · Concrete · Structure",
	"me":        "Electrical · Mechanical · Systems",
}

## All skill node definitions, grouped by branch, in prerequisite order.
## Fields:
##   id        : unique string key (stored in GameState.skill_tree)
##   branch    : branch id
##   name      : display name
##   desc      : one-line effect description shown in card
##   effect    : effect type tag (matches GameState helper effect strings)
##   bonus     : amount added per purchase (flat or fraction, same unit as UpgradeDatabase)
##   cost_sp   : Skill Points required to purchase (always 1 in MVP)
##   requires  : id of the skill that must be purchased first ("" = branch root)
const SKILLS: Array[Dictionary] = [
	# ── Carpentry ─────────────────────────────────────────────────────────────
	{
		"id":       "carp_1",
		"branch":   "carpentry",
		"name":     "Timber Sense",
		"desc":     "+20% Mine Power",
		"effect":   "mine_power_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "",
	},
	{
		"id":       "carp_2",
		"branch":   "carpentry",
		"name":     "Sharp Axes",
		"desc":     "+15% Worker Rate",
		"effect":   "worker_rate_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "carp_1",
	},
	{
		"id":       "carp_3",
		"branch":   "carpentry",
		"name":     "Framing Speed",
		"desc":     "+15% Build Progress per tap",
		"effect":   "build_progress_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "carp_2",
	},
	{
		"id":       "carp_4",
		"branch":   "carpentry",
		"name":     "Quality Lumber",
		"desc":     "+15% Stage Cash reward",
		"effect":   "stage_cash_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "carp_3",
	},
	{
		"id":       "carp_5",
		"branch":   "carpentry",
		"name":     "Master Joiner",
		"desc":     "+10% Double-Craft chance",
		"effect":   "double_craft_chance",
		"bonus":    0.10,
		"cost_sp":  1,
		"requires": "carp_4",
	},
	# ── Masonry ───────────────────────────────────────────────────────────────
	{
		"id":       "mason_1",
		"branch":   "masonry",
		"name":     "Rock Steady",
		"desc":     "+1 Bonus Drop per node break",
		"effect":   "drop_bonus",
		"bonus":    1.0,
		"cost_sp":  1,
		"requires": "",
	},
	{
		"id":       "mason_2",
		"branch":   "masonry",
		"name":     "Mix Pro",
		"desc":     "+20% Worker Rate",
		"effect":   "worker_rate_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "mason_1",
	},
	{
		"id":       "mason_3",
		"branch":   "masonry",
		"name":     "Solid Foundations",
		"desc":     "+20% Build Power",
		"effect":   "build_power_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "mason_2",
	},
	{
		"id":       "mason_4",
		"branch":   "masonry",
		"name":     "Bricklayer",
		"desc":     "+15% Stage Cash reward",
		"effect":   "stage_cash_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "mason_3",
	},
	{
		"id":       "mason_5",
		"branch":   "masonry",
		"name":     "Site Foreman",
		"desc":     "+20% XP gain",
		"effect":   "xp_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "mason_4",
	},
	# ── M&E ──────────────────────────────────────────────────────────────────
	{
		"id":       "me_1",
		"branch":   "me",
		"name":     "Copper Run",
		"desc":     "+15% XP gain",
		"effect":   "xp_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "",
	},
	{
		"id":       "me_2",
		"branch":   "me",
		"name":     "Live Wire",
		"desc":     "+20% Mine Power",
		"effect":   "mine_power_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "me_1",
	},
	{
		"id":       "me_3",
		"branch":   "me",
		"name":     "Circuit Board",
		"desc":     "+10% Double-Craft chance",
		"effect":   "double_craft_chance",
		"bonus":    0.10,
		"cost_sp":  1,
		"requires": "me_2",
	},
	{
		"id":       "me_4",
		"branch":   "me",
		"name":     "Systems Plan",
		"desc":     "+15% Build Progress per tap",
		"effect":   "build_progress_pct",
		"bonus":    0.15,
		"cost_sp":  1,
		"requires": "me_3",
	},
	{
		"id":       "me_5",
		"branch":   "me",
		"name":     "Lead Contractor",
		"desc":     "+20% Build Power",
		"effect":   "build_power_pct",
		"bonus":    0.20,
		"cost_sp":  1,
		"requires": "me_4",
	},
]

## Ordered list of branch ids (for consistent UI display).
const BRANCH_ORDER: Array[String] = ["carpentry", "masonry", "me"]

# ── Public API ──────────────────────────────────────────────────────────────

## Returns all skills in the given branch, in prerequisite order.
func get_branch(branch_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s: Dictionary in SKILLS:
		if s["branch"] == branch_id:
			result.append(s)
	return result

## Returns a single skill definition by id, or {}.
func get_skill(skill_id: String) -> Dictionary:
	for s: Dictionary in SKILLS:
		if s["id"] == skill_id:
			return s
	return {}

## Returns all skill definitions.
func get_all() -> Array[Dictionary]:
	return SKILLS

## Returns true if skill_id can be purchased given the current skill_tree dict.
## Conditions: not already purchased, prerequisite purchased (or none), and SP ≥ cost.
func can_purchase(skill_id: String, skill_tree: Dictionary, skill_points: int) -> bool:
	var s := get_skill(skill_id)
	if s.is_empty():
		return false
	if skill_tree.get(skill_id, false):
		return false   # already owned
	var req: String = s.get("requires", "")
	if req != "" and not skill_tree.get(req, false):
		return false   # prerequisite not met
	return skill_points >= int(s.get("cost_sp", 1))

## Returns the total flat/fractional bonus for a given effect type,
## summing all purchased skills that match. Used by GameState helpers.
func get_total_effect_bonus(effect: String, skill_tree: Dictionary) -> float:
	var total := 0.0
	for s: Dictionary in SKILLS:
		if s["effect"] == effect and skill_tree.get(s["id"], false):
			total += float(s["bonus"])
	return total
