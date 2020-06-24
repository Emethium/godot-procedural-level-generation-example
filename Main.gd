extends Node2D

const Room = preload("res://Room.tscn")

const tile_size = 32
const num_rooms = 50
const min_room_size = 4
const max_room_size = 10
const horizontal_spread = 400
const room_strip_rate = 0.5

# AStar pathfinding object
var path

func _ready():
	randomize()
	create_rooms()
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(32, 228, 0), false)
	if path:
		for point in path.get_points():
			for connection in path.get_point_connections(point):
				var point_position = path.get_point_position(point)
				var current_position = path.get_point_position(connection)
				draw_line(Vector2(point_position.x, point_position.y),
					Vector2(current_position.x, current_position.y), Color(1, 1, 0), 15, true)
		
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
	# Strip generated room quantities and get the positions of the non-banished ones
	var room_positions = strip_rooms_and_return_positions()
	yield(get_tree(), 'idle_frame')
	# Generate a minimum spanning tree connecting all the rooms
	path = find_minimum_spanning_tree(room_positions)

func clear_rooms():
	for room in $Rooms.get_children():
		room.queue_free()

func strip_rooms_and_return_positions():
	var added_room_coordinates = []
	for room in $Rooms.get_children():
		if randf() < room_strip_rate:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			added_room_coordinates.append(Vector2(room.position.x, room.position.y))

	return added_room_coordinates
	
func find_minimum_spanning_tree(nodes):
	var path = AStar2D.new()
	# Add the first node to the path
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	# Repeat until all the nodes are added to the path
	while nodes:
		var min_distance = INF
		var min_position = null
		var current_position = null
		# Loop through all the points in the path
		for path_point in path.get_points():
			path_point = path.get_point_position(path_point)
			# Loop through the remaining nodes
			for node_point in nodes:
				if path_point.distance_to(node_point) < min_distance:
					min_distance = path_point.distance_to(node_point)
					min_position = node_point
					current_position = path_point
		var next_node = path.get_available_point_id()
		path.add_point(next_node, min_position)
		path.connect_points(path.get_closest_point(current_position), next_node)
		nodes.erase(min_position)
	
	return path
	
