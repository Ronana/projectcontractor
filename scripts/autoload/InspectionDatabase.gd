extends Node
## Defines the 16 permanent Site Inspections — two per building tier.
##
## Conditions:
##   "no_skip"  — complete the full tier without using any gem stage-skip
##   "speed"    — complete the full tier within condition_value minutes
##
## Rewards are auto-awarded by Main._check_inspections() at _complete_building().
## completed_inspections is permanent (survives prestige).

## "speed" limits are 2× the minimum Site-Prep cooldown time for each tier,
## giving a realistic window that rewards efficiency without being trivial.
## stage count → (N-1) × 10 min cooldowns × 2.
const INSPECTIONS: Array[Dictionary] = [
	# ── Garden Shed (4 stages, 3 cooldowns = 30 min min) ────────────────────
	{
		"id":               "inspect_shed_noskip",
		"tier_id":          "shed",
		"name":             "Clean Build",
		"desc":             "Complete a Garden Shed without using any gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 5,
		"reward_gems":      3,
	},
	{
		"id":               "inspect_shed_speed",
		"tier_id":          "shed",
		"name":             "Fast Track",
		"desc":             "Complete a Garden Shed in under 60 minutes.",
		"condition_type":   "speed",
		"condition_value":  60,
		"reward_fragments": 8,
		"reward_gems":      5,
	},
	# ── Single-Storey House (5 stages, 4 cooldowns = 40 min min) ────────────
	{
		"id":               "inspect_shouse_noskip",
		"tier_id":          "single_house",
		"name":             "Clean Build",
		"desc":             "Complete a Single-Storey House without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 10,
		"reward_gems":      5,
	},
	{
		"id":               "inspect_shouse_speed",
		"tier_id":          "single_house",
		"name":             "Fast Track",
		"desc":             "Complete a Single-Storey House in under 90 minutes.",
		"condition_type":   "speed",
		"condition_value":  90,
		"reward_fragments": 15,
		"reward_gems":      8,
	},
	# ── Two-Storey House (5 stages, 4 cooldowns = 40 min min) ───────────────
	{
		"id":               "inspect_thouse_noskip",
		"tier_id":          "two_story_house",
		"name":             "Clean Build",
		"desc":             "Complete a Two-Storey House without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 15,
		"reward_gems":      8,
	},
	{
		"id":               "inspect_thouse_speed",
		"tier_id":          "two_story_house",
		"name":             "Fast Track",
		"desc":             "Complete a Two-Storey House in under 90 minutes.",
		"condition_type":   "speed",
		"condition_value":  90,
		"reward_fragments": 25,
		"reward_gems":      12,
	},
	# ── Apartment Block (6 stages, 5 cooldowns = 50 min min) ────────────────
	{
		"id":               "inspect_apt_noskip",
		"tier_id":          "apartment_block",
		"name":             "Clean Build",
		"desc":             "Complete an Apartment Block without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 25,
		"reward_gems":      12,
	},
	{
		"id":               "inspect_apt_speed",
		"tier_id":          "apartment_block",
		"name":             "Fast Track",
		"desc":             "Complete an Apartment Block in under 120 minutes.",
		"condition_type":   "speed",
		"condition_value":  120,
		"reward_fragments": 40,
		"reward_gems":      20,
	},
	# ── Retail Unit (6 stages, 5 cooldowns = 50 min min) ────────────────────
	{
		"id":               "inspect_retail_noskip",
		"tier_id":          "retail_unit",
		"name":             "Clean Build",
		"desc":             "Complete a Retail Unit without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 40,
		"reward_gems":      18,
	},
	{
		"id":               "inspect_retail_speed",
		"tier_id":          "retail_unit",
		"name":             "Fast Track",
		"desc":             "Complete a Retail Unit in under 120 minutes.",
		"condition_type":   "speed",
		"condition_value":  120,
		"reward_fragments": 60,
		"reward_gems":      28,
	},
	# ── Office Block (7 stages, 6 cooldowns = 60 min min) ───────────────────
	{
		"id":               "inspect_office_noskip",
		"tier_id":          "office_block",
		"name":             "Clean Build",
		"desc":             "Complete an Office Block without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 60,
		"reward_gems":      25,
	},
	{
		"id":               "inspect_office_speed",
		"tier_id":          "office_block",
		"name":             "Fast Track",
		"desc":             "Complete an Office Block in under 150 minutes.",
		"condition_type":   "speed",
		"condition_value":  150,
		"reward_fragments": 90,
		"reward_gems":      40,
	},
	# ── High-Rise Tower (7 stages, 6 cooldowns = 60 min min) ────────────────
	{
		"id":               "inspect_highrise_noskip",
		"tier_id":          "high_rise",
		"name":             "Clean Build",
		"desc":             "Complete a High-Rise Tower without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 80,
		"reward_gems":      35,
	},
	{
		"id":               "inspect_highrise_speed",
		"tier_id":          "high_rise",
		"name":             "Fast Track",
		"desc":             "Complete a High-Rise Tower in under 150 minutes.",
		"condition_type":   "speed",
		"condition_value":  150,
		"reward_fragments": 120,
		"reward_gems":      55,
	},
	# ── Landmark Skyscraper (8 stages, 7 cooldowns = 70 min min) ────────────
	{
		"id":               "inspect_sky_noskip",
		"tier_id":          "skyscraper",
		"name":             "Clean Build",
		"desc":             "Complete a Landmark Skyscraper without gem stage-skips.",
		"condition_type":   "no_skip",
		"reward_fragments": 120,
		"reward_gems":      50,
	},
	{
		"id":               "inspect_sky_speed",
		"tier_id":          "skyscraper",
		"name":             "Fast Track",
		"desc":             "Complete a Landmark Skyscraper in under 180 minutes.",
		"condition_type":   "speed",
		"condition_value":  180,
		"reward_fragments": 180,
		"reward_gems":      80,
	},
]

## Returns all inspections for a given tier id, in definition order.
func get_for_tier(tier_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for insp: Dictionary in INSPECTIONS:
		if insp["tier_id"] == tier_id:
			result.append(insp)
	return result

## Returns a single inspection by id, or {} if not found.
func get_inspection(insp_id: String) -> Dictionary:
	for insp: Dictionary in INSPECTIONS:
		if insp["id"] == insp_id:
			return insp
	return {}

## Returns all inspection definitions.
func get_all() -> Array[Dictionary]:
	return INSPECTIONS
