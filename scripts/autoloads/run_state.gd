extends Node
## Everything that defines the current run, independent from the UI.
## The UI only *displays* this state (XP bar, skill cooldowns, banners), which
## makes save/load, turn undo and automated tests possible.

signal xp_changed(xp: float, xp_to_next: int)
signal leveled_up(level: int)
signal cooldowns_changed

const BASE_XP_TO_NEXT: int = 1
const XP_GROWTH: float = 1.2
const XP_PER_BLOOD: float = 1.0
const XP_PER_TYPE_O_STACK: float = 0.35

## Seed of the run. Godot's global RNG is seeded from it in reset(),
## so a run can be replayed exactly.
var run_seed: int = 0
var night: int = 1
var turn: int = 0
var lives: int = 1
var level: int = 1
var xp: float = 0.0
var xp_to_next: int = BASE_XP_TO_NEXT
## MoveAbility -> remaining cooldown turns, for every owned skill.
var cooldowns: Dictionary = {}

func _ready() -> void:
	Events.player_move_started.connect(_on_player_move_started)
	Events.cooldowns_reduced.connect(reduce_cooldowns)

func reset(new_seed: int = -1) -> void:
	run_seed = new_seed if new_seed >= 0 else randi()
	seed(run_seed)
	print("Run seed: %s" % run_seed)
	night = 1
	turn = 0
	lives = 1
	level = 1
	xp = 0.0
	xp_to_next = BASE_XP_TO_NEXT
	cooldowns.clear()

# --- Experience --------------------------------------------------------------

## Called when the player drains a civilian or an enemy.
func add_blood() -> void:
	add_xp(XP_PER_BLOOD + PlayerRewards.stacks(&"type_o_negative") * XP_PER_TYPE_O_STACK)

func add_xp(amount: float) -> void:
	xp = minf(xp + amount, xp_to_next)
	if xp >= xp_to_next:
		level += 1
		xp = 0.0
		xp_to_next = ceili(xp_to_next * XP_GROWTH)
		xp_changed.emit(xp, xp_to_next)
		leveled_up.emit(level)
	else:
		xp_changed.emit(xp, xp_to_next)

# --- Skill cooldowns -----------------------------------------------------------

func register_ability(ability: MoveAbility) -> void:
	cooldowns[ability] = 0
	cooldowns_changed.emit()

func get_cooldown(ability: MoveAbility) -> int:
	return cooldowns.get(ability, 0)

func is_ready(ability: MoveAbility) -> bool:
	return ability == null or get_cooldown(ability) <= 0

## The used skill goes on cooldown; the others recover one turn (not while flying).
func _on_player_move_started(used: Resource, is_flying: bool) -> void:
	for ability: MoveAbility in cooldowns:
		if ability == used:
			cooldowns[ability] = ability.cooldown
		elif !is_flying:
			cooldowns[ability] = maxi(0, cooldowns[ability] - 1)
	cooldowns_changed.emit()

func reduce_cooldowns(turns: int) -> void:
	for ability: MoveAbility in cooldowns:
		cooldowns[ability] = maxi(0, cooldowns[ability] - turns)
	cooldowns_changed.emit()
