extends Node2D



func _ready():
	off()

func on(col: Color):
	modulate = col
	$DiscoShadow.modulate = Color.TRANSPARENT

func off():
	$DiscoShadow.modulate = Color.WHITE

func anim_in(col: Color):
	modulate = col
	$Anim.stop(true)
	$Anim.play('in')

func anim_out():
	$Anim.stop(true)
	$Anim.play('out')

func anim_pulse(col: Color):
	modulate = col
	$Anim.stop(true)
	$Anim.play('pulse')

func anim_pulse_loop(col: Color):
	modulate = col
	$Anim.stop(true)
	$Anim.play('pulse_loop')
