extends Node2D

const Room = preload("res://Room.tscn")

const tile_size = 32
const num_rooms = 50
const min_room_size = 4
const max_room_size = 10
const horizontal_spread = 400
const room_strip_rate = 0.5

func _ready():
	randomize()
	create_rooms()
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(32, 228, 0), false)
		
func _process(_delta):
	update()
	
func _input(event):
	if event.is_action_pressed('ui_select'):
		clear_rooms()
		create_rooms()
		
	
func create_rooms():
	for _i in range(num_rooms):
		var position = Vector2(rand_range(-horizontal_spread, horizontal_spread), 0)
		var room = Room.instance()
		var width = min_room_size + randi() % (max_room_size - min_room_size)
		var height = min_room_size + randi() % (max_room_size - min_room_size)
		
		room.create_room(position, Vector2(width, height) * tile_size)
		$Rooms.add_child(room)
	
	# Wait until all rooms stop moving and are settled
	yield(get_tree().create_timer(1.1), 'timeout')
	
	strip_rooms()

func clear_rooms():
	for room in $Rooms.get_children():
		room.queue_free()

func strip_rooms():
	for room in $Rooms.get_children():
		if randf() < room_strip_rate:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
	
