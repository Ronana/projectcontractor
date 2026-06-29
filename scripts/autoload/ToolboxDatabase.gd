extends Node
## Defines all toolbox items (consumables / temporary boosts) for Project Contractor.
## Items are purchased with Gems in the TOOLBOX panel and used for in-game boosts.
##
## effect values:
##   mine_power    — multiplies GameState.get_mine_power()
##   worker_rate   — multiplies GameState.get_worker_rate_mult()
##   build_power   — multiplies GameState.get_build_power()
##   xp_mult       — multiplies GameState.get_xp_mult()
##   drop_bonus    — flat addition to GameState.get_drop_bonus()
##   stage_cash    — multiplies GameState.get_stage_cash_mult()
##   instant_wave  — immediately clears + respawns active-location nodes (no duration)

const ITEMS: Array[Dictionary] = [
	{
		"id":       "energy_drink",
		"name":     "Energy Drink",
		"desc":     "+100% Mine Power for 60s",
		"effect":   "mine_power",
		"mult":     2.0,
		"flat":     0,
		"duration": 60,
		"color":    Color(0.30, 0.90, 0.40),
		"rarity":   "common",
		"gem_cost": 1,
		"symbol":   "E",
	},
	{
		"id":       "speed_brew",
		"name":     "Speed Brew",
		"desc":     "+150% Worker Rate for 60s",
		"effect":   "worker_rate",
		"mult":     2.5,
		"flat":     0,
		"duration": 60,
		"color":    Color(0.40, 0.90, 0.90),
		"rarity":   "common",
		"gem_cost": 1,
		"symbol":   "W",
	},
	{
		"id":       "rush_contract",
		"name":     "Rush Contract",
		"desc":     "+100% Build Power for 45s",
		"effect":   "build_power",
		"mult":     2.0,
		"flat":     0,
		"duration": 45,
		"color":    Color(0.40, 0.70, 1.00),
		"rarity":   "common",
		"gem_cost": 1,
		"symbol":   "B",
	},
	{
		"id":       "xp_crystal",
		"name":     "XP Crystal",
		"desc":     "+100% XP per break for 90s",
		"effect":   "xp_mult",
		"mult":     2.0,
		"flat":     0,
		"duration": 90,
		"color":    Color(0.70, 0.40, 1.00),
		"rarity":   "common",
		"gem_cost": 1,
		"symbol":   "X",
	},
	{
		"id":       "material_surge",
		"name":     "Material Surge",
		"desc":     "+2 bonus drops per break for 60s",
		"effect":   "drop_bonus",
		"mult":     1.0,
		"flat":     2,
		"duration": 60,
		"color":    Color(0.90, 0.80, 0.20),
		"rarity":   "uncommon",
		"gem_cost": 2,
		"symbol":   "M",
	},
	{
		"id":       "cash_surge",
		"name":     "Cash Surge",
		"desc":     "+100% stage cash rewards for 90s",
		"effect":   "stage_cash",
		"mult":     2.0,
		"flat":     0,
		"duration": 90,
		"color":    Color(1.00, 0.78, 0.20),
		"rarity":   "uncommon",
		"gem_cost": 2,
		"symbol":   "$",
	},
	{
		"id":       "tnt_charge",
		"name":     "TNT Charge",
		"desc":     "Instantly clears all nodes — wave drops immediately",
		"effect":   "instant_wave",
		"mult":     1.0,
		"flat":     0,
		"duration": 0,
		"color":    Color(1.00, 0.40, 0.20),
		"rarity":   "uncommon",
		"gem_cost": 2,
		"symbol":   "T",
	},
	{
		"id":       "mega_blast",
		"name":     "Mega Blast",
		"desc":     "+400% Mine Power for 20s",
		"effect":   "mine_power",
		"mult":     5.0,
		"flat":     0,
		"duration": 20,
		"color":    Color(1.00, 0.30, 0.30),
		"rarity":   "rare",
		"gem_cost": 3,
		"symbol":   "!",
	},
]

# ── Public API ──────────────────────────────────────────────────────────────
func get_item(id: String) -> Dictionary:
	for item: Dictionary in ITEMS:
		if item["id"] == id:
			return item
	return {}

func get_all() -> Array[Dictionary]:
	return ITEMS

func rarity_color(rarity: String) -> Color:
	match rarity:
		"uncommon": return Color(0.40, 0.70, 1.00)
		"rare":     return Color(0.80, 0.40, 1.00)
		_:          return Color(0.30, 0.80, 0.42)   # common = green
