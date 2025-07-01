extends Node

var owned_rewards: Array[Reward] = []
var rewards_draw_pile: Array[Reward] = []
var pile_index: int = 0

func initialise() -> void:
	initialise_rewards_draw_pile()
	owned_rewards = [
		#use this for debug
		#preload("res://data/rewards/soul_spores1.tres"),
		#preload("res://data/rewards/soul_spores2.tres"),
		#preload("res://data/rewards/soul_spores3.tres"),
		#preload("res://data/rewards/fly_range1.tres"),
		#preload("res://data/rewards/fly_range2.tres")
	]
	pile_index = 0

func activate_reward(reward: Reward) -> void:
	if reward.type != Enums.reward_type.INSTANT:
		owned_rewards.append(reward)

func get_level_up_rewards() -> Array[Reward]:
	if Globals.level == 2:
		return _get_level_up_skills(5)
	else:
		return _get_level_up_upgrades()

func _get_level_up_skills(number_of_skills: int = 3) -> Array[Reward]:
	if owned_rewards.filter(
	func(r: Reward) -> bool: return r.type == Enums.reward_type.SKILL
	).size() >= number_of_skills:
		return _get_level_up_upgrades()
	else:
		return _get_rewards(number_of_skills, 0)

func _get_rewards(number_of_skills: int, number_of_upgrades: int) -> Array[Reward]:
	var chosen_rewards: Array[Reward] = []
	while number_of_skills + number_of_upgrades > 0:
		var reward = rewards_draw_pile[pile_index]
		if owned_rewards.find(reward) < 0 and chosen_rewards.find(reward) < 0:
			var prerequisites_met: bool = true
			for prerequisite: Reward in reward.prerequisites:
				if owned_rewards.find(prerequisite) < 0:
					prerequisites_met = false
			if prerequisites_met:
				if reward.type == Enums.reward_type.SKILL and number_of_skills > 0:
					number_of_skills -= 1
					chosen_rewards.append(reward)
				if reward.type == Enums.reward_type.UPGRADE and number_of_upgrades > 0:
					number_of_upgrades -= 1
					chosen_rewards.append(reward)
		pile_index += 1
		if pile_index >= rewards_draw_pile.size():
			pile_index = 0
	return chosen_rewards

func _get_level_up_upgrades() -> Array[Reward]:
	var number_of_upgrades = 3 + has_reward("Versatile")
	return _get_rewards(0, number_of_upgrades)
	
func _get_all_rewards() -> Array[Reward]:
	var possible_rewards: Array[Reward] = []
	var dir_path: String = "res://data/rewards"
	var dir = DirAccess.open(dir_path)
	for scene_path in dir.get_files():
		possible_rewards.append(load(dir_path + "/" + scene_path))
	return possible_rewards

func has_reward(reward_title: String) -> int:
	return owned_rewards.filter(
		func(r: Reward) -> bool:
			return r.title.begins_with(reward_title) \
			and r.title.length() <= reward_title.length() + 2
			).size()

func initialise_rewards_draw_pile() -> void:
	rewards_draw_pile = []
	var brute_rewards: Array[Reward] = _get_all_rewards()
	for reward: Reward in brute_rewards:
		var duplications: int = 0
		match reward.rarity:
			Enums.reward_rarity.COMMON:
				duplications = 9
			Enums.reward_rarity.RARE:
				duplications = 3
			Enums.reward_rarity.EPIC:
				duplications = 1
		for i: int in duplications:
			rewards_draw_pile.append(reward)
	rewards_draw_pile.shuffle()

func get_teleport_range() -> int:
	return 2 + has_reward("Teleport Range")

func get_dash_range() -> Array[int]:
	var dash_range: Array[int] = [2]
	for i: int in has_reward("Dash Range"):
		dash_range.append(2 + i + 1)
	return dash_range

func get_fly_duration() -> int:
	return 1 + has_reward("Fly Range")

func get_werewolf_range() -> int:
	return 3 + has_reward("Werewolf Range")
