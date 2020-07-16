extends Node2D

const Room = preload("res://Room.tscn")

const tile_size = 64
const num_rooms = 50
const min_room_size = 4
const max_room_size = 10
const horizontal_spread = 400
const room_strip_rate = 0.5

onready var Map = $TileMap
enum Tile { Purple_Background, Rocky_Background, Tiled_BackGround, Brown_Block, Grassy_Block, Purple_Block }

# AStar pathfinding object
var path

func _ready():
	randomize()
	create_rooms()
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
				Color(0, 1, 0), false)
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
	if event.is_action_pressed("ui_focus_next"):
		create_map()
		
	
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
	path = null

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
	
func create_map():
	Map.clear()
	
	setup_map_walls()


func setup_map_walls():
	var map_outline = Rect2()
	for room in $Rooms.get_children():
		var rectangle = Rect2(room.position - room.size,
							room.get_node("CollisionShape2D").shape.extents * 2)
		map_outline = map_outline.merge(rectangle)
	
	var map_topleft = Map.world_to_map(map_outline.position)
	var map_bottomright = Map.world_to_map(map_outline.end)
	for x in range(map_topleft.x, map_bottomright.x):
		for y in range(map_topleft.y, map_bottomright.y):
			Map.set_cell(x, y, Tile.Purple_Background)
			
	carve_rooms()


func carve_rooms():
	var corridors = []
	for room in $Rooms.get_children():
		var size = (room.size / tile_size).floor()
		var position = Map.world_to_map(room.position)
		var upper_left = (room.position / tile_size).floor() - size
		
		for x in range(2, size.x * 2 - 1):
			for y in range(2, size.y * 2 - 1):
				Map.set_cell(upper_left.x + x, upper_left.y + y, Tile.Brown_Block)
				
		# Carve connecting corridors
		var point = path.get_closest_point(Vector2(room.position.x, room.position.y))
		for connection in path.get_point_connections(point):
			if not connection in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(point).x,
												path.get_point_position(point).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(connection).x,
												path.get_point_position(connection).y))
				carve_path(start, end)
		corridors.append(point)
		
func carve_path(pos1, pos2):
	# Carve a path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	# choose either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1	
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cell(x, x_y.y, Tile.Brown_Block)
		Map.set_cell(x, x_y.y + y_diff, Tile.Brown_Block)  # widen the corridor
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x, y, Tile.Brown_Block)
		Map.set_cell(y_x.x + x_diff, y, Tile.Brown_Block)
		
		
