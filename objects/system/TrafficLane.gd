extends Node2D

export(bool) var fromRight = false

func _ready():
	spawnCar()

func spawnCar():
	var carSpeed = (randi() % 2) + 5
	yield(get_tree().create_timer((randf() * 3) + 2), "timeout")
	var car = Global.Car.instance()
	car.fromRight = fromRight
	car.position = position
	car.speed = carSpeed
	get_tree().get_root().add_child(car)
	var rerun = spawnCar()
