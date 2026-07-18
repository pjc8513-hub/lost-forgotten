class_name CombatTargeting
extends RefCounted

static func has_reach(actor: Resource) -> bool:
	if actor is EnemyInstance:
		return actor.enemy_data != null and actor.enemy_data.has_reach
	if actor is PartyMember:
		for item in actor.inventory:
			if item != null and item.is_equipped and item.item_data is WeaponData:
				if (item.item_data as WeaponData).has_reach:
					return true
	return false

static func enemy_rows_for(attacker: Resource, enemies: Array[EnemyInstance]) -> Array[int]:
	var occupied_rows: Array[int] = []
	for enemy in enemies:
		if enemy == null or not enemy.is_alive() or enemy.has_fled:
			continue
		if enemy.formation_row not in occupied_rows:
			occupied_rows.append(enemy.formation_row)
	occupied_rows.sort()
	if occupied_rows.is_empty() or has_reach(attacker):
		return occupied_rows
	return [occupied_rows[0]]

static func enemies_in_row(
	attacker: Resource,
	enemies: Array[EnemyInstance],
	row: int
) -> Array[EnemyInstance]:
	var result: Array[EnemyInstance] = []
	if row not in enemy_rows_for(attacker, enemies):
		return result
	for enemy in enemies:
		if enemy != null and enemy.is_alive() and not enemy.has_fled and enemy.formation_row == row:
			result.append(enemy)
	return result

static func party_targets_for(
	attacker: Resource,
	party: Array[PartyMember]
) -> Array[PartyMember]:
	var front: Array[PartyMember] = []
	var back: Array[PartyMember] = []
	for member in party:
		if member == null or not member.is_alive():
			continue
		if member.row == PartyMember.CombatRow.FRONT:
			front.append(member)
		else:
			back.append(member)
	if has_reach(attacker):
		front.append_array(back)
		return front
	return front if not front.is_empty() else back
