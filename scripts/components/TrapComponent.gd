class_name TrapComponent
extends Node

@export var trap_id: StringName
@export var trigger_once: bool = false
@export var trap_type: trap_data
var triggered: bool = false
var disarmed: bool = false
var blink_tween: Tween
var blink_material: StandardMaterial3D

func _ready() -> void:
	MapManager.register_trap(self)

func _exit_tree() -> void:
	MapManager.unregister_trap(self)

func discover_trap() -> void:
	if blink_tween != null and blink_tween.is_valid():
		return
	var trap_mesh := get_parent() as MeshInstance3D
	if trap_mesh == null or trap_mesh.mesh == null or trap_mesh.mesh.get_surface_count() == 0:
		push_warning("TrapComponent requires a parent MeshInstance3D to reveal the trap.")
		return
	var source_material := trap_mesh.get_active_material(0) as StandardMaterial3D
	if source_material == null:
		push_warning("Trap mesh has no StandardMaterial3D to animate.")
		return
	# Trap floors commonly share floor.tres. A local duplicate prevents every
	# floor using that resource from pulsing when this trap is discovered.
	blink_material = source_material.duplicate() as StandardMaterial3D
	blink_material.resource_local_to_scene = true
	blink_material.emission_enabled = true
	blink_material.emission = Color.BLACK
	trap_mesh.set_surface_override_material(0, blink_material)
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(blink_material, "emission", Color(0.331, 0.0, 0.0, 1.0), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	blink_tween.tween_property(blink_material, "emission", Color.BLACK, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func stop_blinking() -> void:
	if blink_tween != null and blink_tween.is_valid():
		blink_tween.kill()
	blink_tween = null
	if blink_material != null:
		blink_material.emission = Color.BLACK

func is_discovered() -> bool:
	var secret := get_parent().get_node_or_null("SecretComponent") as SecretComponent
	return secret == null or not secret.is_secret

func disarm() -> bool:
	if disarmed:
		return false
	if trap_id.is_empty():
		disarmed = true
	else:
		MapManager.set_trap_state(trap_id, true, triggered)
	return true

func apply_state(state: Dictionary) -> void:
	disarmed = bool(state.get("disarmed", false))
	triggered = bool(state.get("triggered", false))
	if disarmed:
		stop_blinking()

func trigger(_actor: Node) -> void:
	if disarmed:
		return
	# Springing a hidden trap reveals it through the same persistent discovery
	# path used by Search, making it immediately eligible for Disarm Trap.
	var secret := get_parent().get_node_or_null("SecretComponent") as SecretComponent
	if secret != null and secret.is_secret:
		secret.discover()
	else:
		discover_trap()
	if (trigger_once and triggered) or trap_type == null:
		return
	triggered = true
	if not trap_id.is_empty():
		MapManager.set_trap_state(trap_id, disarmed, true)
	for member in PartyManager.party:
		var save := DCChecks.check_character(member, trap_type.save_stat, trap_type.save_dc)
		if save.succeeded:
			continue
		var rolled_damage := DiceRoller.roll(trap_type.dice_rolls, trap_type.dice_sides).total
		var damage_taken: int
		var message: String
		if trap_type.target_stamina:
			var stamina_before := member.current_stamina
			member.current_stamina -= rolled_damage
			damage_taken = stamina_before - member.current_stamina
			message = "%s lost %d Stamina from the trap" % [member.member_name, damage_taken]
		else:
			var hp_before := member.current_hp
			member.take_damage(rolled_damage)
			damage_taken = hp_before - member.current_hp
			message = "%s took %d damage from the trap" % [member.member_name, damage_taken]
		if trap_type.status_effect != StatusEffects.Effect.NONE:
			member.active_status_effects[trap_type.status_effect] = {
				"remaining_rounds": trap_type.status_rounds,
				"save_dc": trap_type.save_dc,
				"source": String(trap_id) if not trap_id.is_empty() else "Trap",
			}
			member.stats_changed.emit()
			message += " and was afflicted with %s" % StatusEffects.get_label(trap_type.status_effect)
		MapManager.request_alert(message)
