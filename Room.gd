extends RigidBody2D

var size

func create_room(_pos, _size):
	position = _pos
	size = _size
	var shape = RectangleShape2D.new()
	shape.extents = size
	# Speeds up room placement
	shape.custom_solver_bias = 0.75
	$CollisionShape2D.shape = shape
