extends Marker2D

@export var fromRight: bool = false

func _ready():
	# Online traffic is host-driven; guests spawn via Net.car_event.
	if Net.isOnline and not Net.isHost:
		return
	spawnCar()

func spawnCar() -> void:
	await get_tree().create_timer(randf_range(3.0, 5.0)).timeout

	var carSpeed := randf_range(700, 1000)
	var paint := randi()
	_spawnCar(carSpeed, paint)
	if Net.isOnline and Net.isHost:
		Net.car_event(name, carSpeed, paint)

	spawnCar()

func spawnNetCar(carSpeed: float, paint: int) -> void:
	_spawnCar(carSpeed, paint)

func _spawnCar(carSpeed: float, paint: int = -1) -> void:
	var car = Res.CarObject.instantiate()
	car.fromRight = fromRight
	car.position = position
	car.speed = carSpeed
	car.netPaint = paint
	get_parent().add_child(car)
