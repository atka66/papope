extends Node2D

func showCount(cnt: String, size: int, audio: Resource) -> void:
	var label = Res.CustomLabelObject.instantiate()
	label.text = cnt
	label.fontSize = size
	label.alignment = Control.LayoutPreset.PRESET_CENTER
	label.aliveTime = 1
	label.animation = 'boom_in'
	label.animation_out = 'float_out'
	label.audio = audio
	add_child(label)

func _ready():
	for i in range(3):
		showCount(str(3 - i), 8, Res.AudioPlayerDash.pick_random())
		await get_tree().create_timer(1.0).timeout
	var scene := get_tree().get_current_scene()
	if scene != null && scene.get_name() != 'Lobby':
		# Round start inside a map. A countdown that outlived its scene (we
		# left mid-count) must not poke a map that is already gone.
		if Global.MapControllerNode == null || !is_instance_valid(Global.MapControllerNode):
			return
		showCount("go!", 12, null)
		Global.startRound()
		return
	# Lobby countdown: assign max HPs and go to map.
	for i in range(4):
		match Global.options['mode'][Global.optionsSelected['mode']]:
			'normal':
				Global.playersMaxHp[i] = 100
			'one-hit':
				Global.playersMaxHp[i] = 1
			'cards':
				Global.playersMaxHp[i] = 100
	# Guests never advance a match themselves: they wait for the host's travel
	# message, and the host re-announces its phase if one goes missing.
	if Net.isOnline && !Net.isHost:
		return
	Net.advance_match()
