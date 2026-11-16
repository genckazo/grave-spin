class_name RelicEngine
extends RefCounted
## The relic effect hooks. Relics are plain data (data/relics.json); this class
## is the only place their effects are evaluated.
##
## Hook names:
##   sword_bonus         +N damage per sword symbol
##   block_bonus         +N block per shield symbol
##   heal_bonus          +N HP per potion symbol
##   coin_bonus          +N coins per coin symbol
##   skull_reduction     -N skull damage penalty
##   second_wind         survive one lethal hit (value = HP left)
##   lucky_seventh       every value-th pull, force value2 swords
##   start_block         +N block when a fight starts
##   blood_coin          +N coins per point of damage taken
##   skull_damage        +N damage to the enemy per skull
##   triple_sword_bonus  +N damage for a three-sword payline
##   all_bonus           +N to every payout (sword/block/heal/coin)
##   first_skull_free    the first skull each fight adds no penalty
##   max_relics_bonus    +N to the relic carry cap
##   kill_heal           +N HP when an enemy is slain

static func total(state, effect: String) -> int:
	var sum := 0
	for r in state.relics:
		if String(r.get("effect", "")) == effect:
			sum += int(r.get("value", 0))
	return sum

static func has_effect(state, effect: String) -> bool:
	for r in state.relics:
		if String(r.get("effect", "")) == effect:
			return true
	return false
