@tool
extends Node2D

# setting this boolean will generate a polygon with the defined properties
@export var gen: bool = false:
	set(newGen):
		$Polygon2D.polygon = generate_circle_polygon(10.0, 8.0, 14, Vector2.ZERO)

func generate_circle_polygon(outer_radius: float, inner_radius: float, num_sides: int, position: Vector2) -> PackedVector2Array:
	var angle_delta: float = (PI * 2) / num_sides
	var polygon: PackedVector2Array

	var outer_vector: Vector2 = Vector2(outer_radius, 0)
	for _i in num_sides:
		polygon.append(outer_vector + position)
		outer_vector = outer_vector.rotated(angle_delta)
	polygon.append(outer_vector + position)
	
	var inner_vector: Vector2 = Vector2(inner_radius, 0)
	for _i in num_sides:
		polygon.append(inner_vector + position)
		inner_vector = inner_vector.rotated(-angle_delta)
	polygon.append(inner_vector + position)

	return polygon
