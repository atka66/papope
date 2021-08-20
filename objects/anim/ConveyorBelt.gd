extends Area2D

func _on_ConveyorBelt_body_entered(body):
	if body is RigidBody2D:
		body.add_central_force(Global.CONVEYOR_VEL_PHYSICS)
	if body.is_in_group('destructible'):
		body.conveyed = true

func _on_ConveyorBelt_area_entered(area):
	if area.is_in_group('pwrups') || area.is_in_group('trap'):
		area.conveyed = true


func _on_ConveyorBelt_area_exited(area):
	if area.is_in_group('pwrups'):
		area.get_node('Anim').play('conveyorfall')
	if area.is_in_group('trap'):
		area.get_node('Anim').play('conveyorfall')
		area.trigger()


func _on_ConveyorBelt_body_exited(body):
	if body.is_in_group('destructible') || body.is_in_group('destructionparticle'):
		body.get_node("CollisionShape2D").set_deferred("disabled", true)
		body.get_node('Anim').play('conveyorfall')
