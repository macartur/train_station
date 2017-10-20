
extends Node

# LOAD OBJECTS
const agent_right = preload("res://objects/agent_left.tscn")
const agent_left = preload("res://objects/agent_right.tscn")
const door_scene = preload('res://objects/door.tscn') 
const block_scene = preload('res://objects/block.tscn')

class Agent:
	var object
	var last_update = 0.02
	var side
	var influence_number
	
	func _init(side='left', influence_number=200):
		if side == 'left':
			self.object = agent_left.instance()
			self.influence_number = influence_number
		else:
			self.object = agent_right.instance()
			self.influence_number = influence_number*(-1)
		self.side = side

	func add_influence(map, x, y):
		for line in range(map.width):
			for column in range(map.height):
				map.influence_map[line][column] += self.influence_number/(1+abs(column - x)+abs(line - y))^2

	func remove_influence(map, x, y):
		for line in range(map.width):
			for column in range(map.height):
				map.influence_map[line][column] -= self.influence_number/(1+abs(column - x)+abs(line - y))^2

	func delete(map):
		map.object.remove_child(self.object)
		self.object.free()

	func update(delta, map, line, column):
		last_update -= delta
		
		if last_update < 0.0:
			var next_x = line
			var next_y = column
			last_update = 0.02
			for x in [line-1,line,line+1]:
				for y in [column-1, column, column+1]:
					if x > map.width or y > map.height or x < 0 or y < 0:
						continue

					if typeof(map.board[x][y]) == TYPE_INT and x < map.width+1 and y < map.height+1:
						if (self.side == 'left' and map.influence_map[x][y] <= map.influence_map[next_x][next_y]) or \
						   (self.side == 'right' and map.influence_map[x][y] > map.influence_map[next_x][next_y]):
							next_x = x
							next_y = y
			map.move_object(self, line, column, next_x, next_y)

class Door:
	var timestamp
	var object
	var influence_number
	
	func _init(influence_number=10000):
		self.object = door_scene.instance()
		self.timestamp =  self.get_random_value()
		self.influence_number = influence_number

	func update(delta, map, x, y):
		self.timestamp -= delta
		
		var tmp_x = 0
		if x == 0:
			tmp_x = x+1
		else: 
			tmp_x = x-1

		for n in [y-1, y, y+1]:
			var obj = map.board[tmp_x][n]
			if typeof(obj) != TYPE_INT:
				if (obj.side == 'left' and x == 39) or (obj.side == 'right' and x == 0):
					map.remove_object(tmp_x,n)
				
		if self.timestamp < 0:
			if x == 0 and typeof(map.board[x+1][y]) == TYPE_INT and typeof(map.board[x+1][y-1]) == TYPE_INT and typeof(map.board[x+1][y+1]) == TYPE_INT:
				var agent = Agent.new('left')
				map.set_object(agent, x+1,y)
				self.timestamp = self.get_random_value()
			elif x == 39 and typeof(map.board[x-1][y]) == TYPE_INT and typeof(map.board[x-1][y-1]) == TYPE_INT and typeof(map.board[x-1][y+1]) == TYPE_INT:
				var agent = Agent.new('right')
				map.set_object(agent, x-1,y)
				self.timestamp = self.get_random_value()

	func get_random_value():
		randomize()
		return randf()/5

	func add_influence(map, x, y):
		for tmp_x in range(map.width):
			for tmp_y in range(map.height):
				map.influence_map[tmp_x][tmp_y] += self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2

class Block:
	var object  # object of scene
	var influence_number
	
	func _init(influence_number=0):
		self.object = block_scene.instance()
		self.influence_number = influence_number
	
	func update(delta, map, line, column):
		pass

	func add_influence(map, x, y):
		for tmp_x in range(map.width):
				for tmp_y in range(map.height):
					map.influence_map[tmp_x][tmp_y] += self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2

class Map:
	var board
	var influence_map
	var tile_size
	var width
	var height
	var object
	
	func _init(width, height, object):
		self.tile_size = 20
		self.width = width
		self.height = height
		self.object = object
		self.board = []
		self.influence_map = []
		self._fill_map(self.board)
		self._fill_map(self.influence_map)
		self.create_doors()
		self.create_blocks()

	func _fill_map(map):
		for line in range(width):
			var columns  = []
			for column in range(height):
				columns.append(0)
			map.append(columns)

	func create_blocks():
		for x in range(self.width):
			for y in range(self.height):
				if (x == 0 or y == 0 or x == 39 or y == 29) and typeof(self.board[x][y]) == TYPE_INT :
					var block = Block.new()
					self.set_object(block, x, y)

	func create_doors():
		# right door
		for y in [2,3,4,14,15,16,23,24,25]:
			var door = Door.new(10000)
			self.set_object(door, 0, y)
		# left_door
		for y in [2,3,4,14,15,16,23,24,25]:
			var door = Door.new(-10000)
			self.set_object(door, 39, y)

	func set_object(instance, x, y):
		self.object.add_child(instance.object)
		self.board[x][y] = instance
		instance.add_influence(self, x, y)
		instance.object.set_pos(Vector2(self.tile_size*x, self.tile_size*y))
	
	func remove_object(x, y):
		print(self.board[x][y])
		var instance = self.board[x][y]
		instance.remove_influence(self, x, y)
		self.board[x][y] = 0
		instance.delete(self)
		
	func move_object(instance, x, y, next_x, next_y):
		instance.remove_influence(self, x, y)
		instance.add_influence(self, next_x, next_y)
		self.board[x][y] = 0
		self.board[next_x][next_y] = instance
		instance.object.set_pos(Vector2(self.tile_size*next_x, self.tile_size*next_y))
		
	func update(delta):
		for x in range(self.width):
			for y in range(self.height):
				var obj = self.board[x][y]
				if typeof(obj) != TYPE_INT:
					obj.update(delta, self, x, y)

#  GAME LOOP
var map = Map.new(40,30, get_node('.'))

func _ready():
	set_process(true)
	
var last = 1
func _process(delta):
	last -= delta
	if last < 0:
		last = 1
		map.update(delta)