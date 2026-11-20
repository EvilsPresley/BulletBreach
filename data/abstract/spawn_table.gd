extends Resource
class_name SpawnTable
## Ordered spawn rules: the first rule whose enemy count is below its quota
## decides the next spawn; otherwise `fallback` is used.

@export var rules: Array[SpawnRule] = []
@export var fallback: EnemyDefinition

func pick(alive_counts: Dictionary) -> EnemyDefinition:
	for rule: SpawnRule in rules:
		if alive_counts.get(rule.enemy, 0) < rule.max_alive:
			return rule.enemy
	return fallback
