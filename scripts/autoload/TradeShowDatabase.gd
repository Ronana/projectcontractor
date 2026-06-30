extends Node
## Defines the rotating Trade Show events for Project Contractor.
##
## Events run back-to-back (7 days each = 28-day full cycle).
## Each event has 3 tasks with escalating difficulty and 3 gem reward tiers.
##
## Task types:
##   "complete_builds_any"  — complete N buildings of any tier
##   "break_nodes"          — break N mining nodes
##   "earn_stage_cash"      — earn N cash from stage completions this event
##   "complete_tier_min"    — complete N buildings of "tier" or higher
##
## Rewards are gems only — clean, universal, no blueprint fragment confusion.

const EVENT_DURATION_DAYS: float = 7.0

## Ordered list of events. When the last ends the list wraps back to index 0.
const EVENTS: Array[Dictionary] = [
	# ── Event 0: Foundation Fair ─────────────────────────────────────────────
	{
		"id":    "ts_foundation_fair",
		"name":  "Foundation Fair",
		"desc":  "Kick off the season by showing off your groundwork skills.",
		"color": Color(0.88, 0.65, 0.25),   # warm gold
		"tasks": [
			{
				"id":     "ff_t1",
				"desc":   "Complete 2 buildings",
				"type":   "complete_builds_any",
				"target": 2,
			},
			{
				"id":     "ff_t2",
				"desc":   "Break 80 mining nodes",
				"type":   "break_nodes",
				"target": 80,
			},
			{
				"id":     "ff_t3",
				"desc":   "Complete a Two-Storey House or better",
				"type":   "complete_tier_min",
				"tier":   "two_story_house",
				"target": 1,
			},
		],
		"rewards": [
			{"label": "Participation Prize", "gems": 20},
			{"label": "Silver Award",        "gems": 45},
			{"label": "Gold Trophy",         "gems": 80},
		],
	},
	# ── Event 1: High Rise Showcase ──────────────────────────────────────────
	{
		"id":    "ts_high_rise_showcase",
		"name":  "High Rise Showcase",
		"desc":  "Prove your team can build tall and build fast.",
		"color": Color(0.30, 0.70, 1.00),   # electric blue
		"tasks": [
			{
				"id":     "hrs_t1",
				"desc":   "Earn 25,000 stage cash",
				"type":   "earn_stage_cash",
				"target": 25000,
			},
			{
				"id":     "hrs_t2",
				"desc":   "Complete 4 buildings",
				"type":   "complete_builds_any",
				"target": 4,
			},
			{
				"id":     "hrs_t3",
				"desc":   "Complete an Apartment Block or better",
				"type":   "complete_tier_min",
				"tier":   "apartment_block",
				"target": 1,
			},
		],
		"rewards": [
			{"label": "Participation Prize", "gems": 25},
			{"label": "Silver Award",        "gems": 55},
			{"label": "Gold Trophy",         "gems": 95},
		],
	},
	# ── Event 2: Materials Expo ──────────────────────────────────────────────
	{
		"id":    "ts_materials_expo",
		"name":  "Materials Expo",
		"desc":  "The trades are watching — show them what your site can produce.",
		"color": Color(0.65, 0.65, 0.70),   # stone grey
		"tasks": [
			{
				"id":     "me_t1",
				"desc":   "Break 150 mining nodes",
				"type":   "break_nodes",
				"target": 150,
			},
			{
				"id":     "me_t2",
				"desc":   "Earn 60,000 stage cash",
				"type":   "earn_stage_cash",
				"target": 60000,
			},
			{
				"id":     "me_t3",
				"desc":   "Complete 5 buildings",
				"type":   "complete_builds_any",
				"target": 5,
			},
		],
		"rewards": [
			{"label": "Participation Prize", "gems": 25},
			{"label": "Silver Award",        "gems": 55},
			{"label": "Gold Trophy",         "gems": 100},
		],
	},
	# ── Event 3: Blueprint Awards ────────────────────────────────────────────
	{
		"id":    "ts_blueprint_awards",
		"name":  "Blueprint Awards",
		"desc":  "The industry's premier awards night. Only the best designs win.",
		"color": Color(0.70, 0.35, 1.00),   # prestige purple
		"tasks": [
			{
				"id":     "ba_t1",
				"desc":   "Complete 3 buildings",
				"type":   "complete_builds_any",
				"target": 3,
			},
			{
				"id":     "ba_t2",
				"desc":   "Break 250 mining nodes",
				"type":   "break_nodes",
				"target": 250,
			},
			{
				"id":     "ba_t3",
				"desc":   "Complete a Retail Unit or better",
				"type":   "complete_tier_min",
				"tier":   "retail_unit",
				"target": 1,
			},
		],
		"rewards": [
			{"label": "Participation Prize", "gems": 30},
			{"label": "Silver Award",        "gems": 65},
			{"label": "Gold Trophy",         "gems": 120},
		],
	},
]

# ── Public API ───────────────────────────────────────────────────────────────

## Returns the event at the given index (wraps around).
func get_event(idx: int) -> Dictionary:
	if EVENTS.is_empty():
		return {}
	return EVENTS[idx % EVENTS.size()]

## Returns how many events exist.
func event_count() -> int:
	return EVENTS.size()

## Returns the index of tier_id in TIER_ORDER, or -1 if not found.
## Used for complete_tier_min comparisons.
func tier_index(tier_id: String) -> int:
	return BuildDatabase.TIER_ORDER.find(tier_id)
