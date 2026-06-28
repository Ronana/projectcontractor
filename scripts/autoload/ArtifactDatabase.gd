extends Node
## Permanent artifacts purchased with Reputation Points.
## All bonuses persist across New Contract resets.

const ARTIFACTS: Array[Dictionary] = [
	{
		"id":          "veteran_foreman",
		"name":        "Veteran Foreman",
		"description": "+10% Mine Power per level",
		"max_level":   10,
		"effect":      "mine_power_pct",
		"bonus":       0.10,
		"base_cost":   1,
	},
	{
		"id":          "site_reputation",
		"name":        "Site Reputation",
		"description": "+10% cash from all sources per level",
		"max_level":   10,
		"effect":      "cash_pct",
		"bonus":       0.10,
		"base_cost":   1,
	},
	{
		"id":          "quality_materials",
		"name":        "Quality Materials",
		"description": "+1 bonus material drop per node per level",
		"max_level":   5,
		"effect":      "drop_bonus",
		"bonus":       1.0,
		"base_cost":   2,
	},
	{
		"id":          "experienced_crew",
		"name":        "Experienced Crew",
		"description": "Hired crew start +1 level higher per artifact level",
		"max_level":   3,
		"effect":      "crew_start_level",
		"bonus":       1.0,
		"base_cost":   3,
	},
	{
		"id":          "fast_learner",
		"name":        "Fast Learner",
		"description": "+20% XP gain per level",
		"max_level":   10,
		"effect":      "xp_pct",
		"bonus":       0.20,
		"base_cost":   2,
	},
]

func get_all() -> Array[Dictionary]:
	return ARTIFACTS

func get_artifact(id: String) -> Dictionary:
	for a: Dictionary in ARTIFACTS:
		if a["id"] == id:
			return a
	return {}

## Cost in Reputation Points to purchase the next level.
## Doubles each purchase: base_cost × 2^current_level
func get_cost(artifact_id: String, current_level: int) -> int:
	var a := get_artifact(artifact_id)
	if a.is_empty():
		return 9999
	var base: int = int(a["base_cost"])
	return base * int(pow(2.0, float(current_level)))

## Total accumulated bonus for the given artifact at the given level.
func get_total_bonus(artifact_id: String, level: int) -> float:
	var a := get_artifact(artifact_id)
	if a.is_empty():
		return 0.0
	return float(a["bonus"]) * float(level)
