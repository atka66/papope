extends Marker2D

@export var fromRight: bool = false

func _ready():
	spawnCar()

func spawnCar() -> void:
	await get_tree().create_timer(randf_range(3.0, 5.0)).timeout

	var car = Res.CarObject.instantiate()
	car.fromRight = fromRight
	car.position = position
	car.speed = randf_range(700, 1000)
	get_parent().add_child(car)

	spawnCar()
