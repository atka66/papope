extends Node2D

@export var withFireSound: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if withFireSound:
		$Audio.stream = Res.AudioRevolverFire
	else:
		$Audio.stream = Res.AudioRevolverRicochet.pick_random()
	$Audio.play()
	await $Audio.finished
	queue_free()

## helper function to generate circle with tool script
func generate_circle_polygon(radius: float, num_sides: int, position: Vector2) -> PackedVector2Array:
	var angle_delta: float = (PI * 2) / num_sides
	var vector: Vector2 = Vector2(radius, 0)
	var polygon: PackedVector2Array

	for _i in num_sides:
		polygon.append(vector + position)
		vector = vector.rotated(angle_delta)

	return polygon
