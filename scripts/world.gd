extends Node

# LOAD OBJECTS
const agent_right = preload("res://objects/agent_left.tscn")
const agent_left = preload("res://objects/agent_right.tscn")
const door_scene = preload('res://objects/door.tscn') 
const block_scene = preload('res://objects/block.tscn')

# MAIN CLASSES
class Agent:
	var object
	var last_update
	var speed
	var side
	var influence_number

	func _init(side, speed, influence_number=300):
		if side == 'left':
			self.object = agent_left.instance()
			self.influence_number = influence_number
		else:
			self.object = agent_right.instance()
			self.influence_number = influence_number*(-1)
		self.side = side
		self.speed = speed
		self.last_update = self.speed

	func type():
		return 'Agent'

	func add_influence(map, x, y):
		for next_x in range(map.width):
			for next_y in range(map.height):
				map.influence_map[next_x][next_y] += self.influence_number/(1+abs(next_x - x)+abs(next_y - y))^2

	func remove_influence(map, x, y):
		for next_x in range(map.width):
			for next_y in range(map.height):
				map.influence_map[next_x][next_y] -= self.influence_number/(1+abs(next_x - x)+abs(next_y - y))^2

	func delete(map):
		map.object.remove_child(self.object)
		self.object.free()

	func update(delta, map, current_x, current_y):
		self.last_update -= delta
		if self.last_update < 0.0:
			self.last_update = self.speed
			var next_x = current_x
			var next_y = current_y
			for x in [current_x-1,current_x,current_x+1]:
				for y in [current_y-1, current_y, current_y+1]:
					if x > map.width or y > map.height or x < 0 or y < 0:
						continue
					if typeof(map.board[x][y]) == TYPE_INT and x < map.width+1 and y < map.height+1:
						if (self.side == 'left' and map.influence_map[x][y] <= map.influence_map[next_x][next_y]) or \
						   (self.side == 'right' and map.influence_map[x][y] > map.influence_map[next_x][next_y]):
							next_x = x
							next_y = y
			map.move_object(self, current_x, current_y, next_x, next_y)

class Door:
	var timestamp
	var object
	var influence_number
	var agent_speed
	var born_speed

	func _init(born_speed,influence_number=10000):
		self.object = door_scene.instance()
		self.timestamp =  born_speed + self.get_random_value()
		self.born_speed = born_speed + self.get_random_value()
		self.influence_number = influence_number
		self.agent_speed = 0.02

	func type():
		return 'Door'

	func delete(map):
		map.object.remove_child(self.object)
		self.object.free()

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

		if self.timestamp < 0.0:
			if x == 0 and typeof(map.board[x+1][y]) == TYPE_INT and typeof(map.board[x+1][y-1]) == TYPE_INT and typeof(map.board[x+1][y+1]) == TYPE_INT:
				var agent = Agent.new('left', self.agent_speed)
				map.set_object(agent, x+1, y)
				self.timestamp = self.get_random_value() + self.born_speed
			elif x == 39 and typeof(map.board[x-1][y]) == TYPE_INT and typeof(map.board[x-1][y-1]) == TYPE_INT and typeof(map.board[x-1][y+1]) == TYPE_INT:
				var agent = Agent.new('right', self.agent_speed)
				map.set_object(agent, x-1, y)
				self.timestamp = self.get_random_value() + self.born_speed

	func get_random_value():
		randomize()
		return randf()/8

	func add_influence(map, x, y):
		for tmp_x in range(map.width):
			for tmp_y in range(map.height):
				map.influence_map[tmp_x][tmp_y] += self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2

	func remove_influence(map, x, y):
		for tmp_x in range(map.width):
			for tmp_y in range(map.height):
				map.influence_map[tmp_x][tmp_y] -= self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2

class Block:
	var object
	var influence_number
	var side
	func _init(influence_number=0):
		self.object = block_scene.instance()
		self.influence_number = influence_number
		self.side = ''
	
	func type():
		return 'Block'
	
	func update(delta, map, x, y):
		pass

	func delete(map):
		map.object.remove_child(self.object)
		self.object.free()

	func add_influence(map, x, y):
		for tmp_x in range(map.width):
				for tmp_y in range(map.height):
					map.influence_map[tmp_x][tmp_y] += self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2
					
	func remove_influence(map, x, y):
		for tmp_x in range(map.width):
				for tmp_y in range(map.height):
					map.influence_map[tmp_x][tmp_y] -= self.influence_number/(1+abs(tmp_x - x)+abs(tmp_y - y))^2

class Map:
	var last_update
	var update_time
	var board
	var influence_map
	var tile_size
	var width
	var height
	var object
	
	func _init(width, height, object):
		self.update_time =1
		self.last_update = self.update_time
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

	func clear_agents():
		for x in range(self.width):
			for y in range(self.height):
				var obj = self.board[x][y]
				if  typeof(obj) != TYPE_INT and obj.type() == 'Agent':
					self.remove_object(x,y)

	func clear_blocks():
		for x in range(self.width):
			for y in range(self.height):
				var obj = self.board[x][y]
				if (x == 0 or y == 0 or x == 39 or y == 29):
					continue
				if  typeof(obj) != TYPE_INT and obj.type() == 'Block':
					self.remove_object(x,y)

	func create_blocks():
		for x in range(self.width):
			for y in range(self.height):
				if (x == 0 or y == 0 or x == 39 or y == 29) and typeof(self.board[x][y]) == TYPE_INT :
					var block = Block.new()
					self.set_object(block, x, y)

	func create_doors():
		# right door
		for y in [2,3,4,14,15,16,23,24,25]:
			var door = Door.new(0.005, 10000)
			self.set_object(door, 0, y)
		# left_door
		for y in [2,3,4,14,15,16,23,24,25]:
			var door = Door.new(0.1,-10000)
			self.set_object(door, 39, y)

	func set_object(instance, x, y):
		self.object.add_child(instance.object)
		self.board[x][y] = instance
		instance.add_influence(self, x, y)
		instance.object.set_pos(Vector2(self.tile_size*x, self.tile_size*y))
	
	func remove_object(x, y):
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
		
	func update(delta, stopped):
		if stopped == 'Stopped':
			return

		self.last_update -= delta
		if self.last_update > 0:
			return

		self.last_update = self.update_time
		for x in range(self.width):
			for y in range(self.height):
				var obj = self.board[x][y]
				if typeof(obj) != TYPE_INT:
					obj.update(delta, self, x, y)

	func update_door_speed(left_door_speed, right_door_speed):
		for y in [2,3,4,14,15,16,23,24,25]:# left_door
			self.board[0][y].born_speed = left_door_speed
		for y in [2,3,4,14,15,16,23,24,25]:# right_door
			self.board[39][y].born_speed = right_door_speed
	
	func update_agent_speed(speed):
		for x in range(self.width):
			for y in range(self.height):
				var obj = self.board[x][y]
				if typeof(obj) != TYPE_INT:
					if obj.type() == 'Agent':
						obj.speed = speed
					if obj.type() == 'Door':
						obj.agent_speed = speed

class Game:
	var menu_items
	var map
	
	func _init(menu, map):
		self.map = map
		
		var items_name = ['start_button','stop_button', 'agent_speed','left_door_speed',
						  'right_door_speed', 'status','reset_button_agents', 'reset_train_station']
		self.menu_items = {}
		for name in items_name:
			self.menu_items[name] = menu.get_node(name)
			if 'speed' in name:
				self._create_speed_itens(self.menu_items[name])
		
	func _create_speed_itens(button):
		button.add_item('slow', 0)
		button.add_item('normal', 1)
		button.add_item('fast', 2)
		button.select(1)
	
	func is_stopped():
		return self.menu_items['status'].get_text()

	func update(delta):
		if self.menu_items['start_button'].is_pressed():
			self.menu_items['status'].set_text('Running')
			self.map.update_agent_speed(self.get_speed('agent_speed'))
			self.map.update_door_speed( self.get_speed('left_door_speed'), self.get_speed('right_door_speed'))
		if self.menu_items['stop_button'].is_pressed():
			self.menu_items['status'].set_text('Stopped')
		if self.menu_items['reset_button_agents'].is_pressed():
			self.map.clear_agents()
			self.menu_items['status'].set_text('Stopped')
		if self.menu_items['reset_train_station'].is_pressed():
			self.map.clear_blocks()
			self.menu_items['status'].set_text('Stopped')
			
		self.map.update(delta, self.is_stopped())

	func get_speed(button_name):
		var speed_index = self.menu_items[button_name].get_selected()
		var speed = 0
		if  speed_index == 0: # slow
			speed = 0.1
		elif speed_index == 2: # fast
			speed = 0.02
		else: # normal
			speed = 0.035
		return speed

#  GAME LOOP
var game

func _ready():
	set_process_input(true)
	set_process(true)
	var map = Map.new(40,30, get_node('.'))
	game = Game.new(get_node('/root/world/menu'), map)

func _process(delta):
	game.update(delta)

func _input(ev):
	if (ev.type==InputEvent.MOUSE_BUTTON):
		if ev.button_index == BUTTON_LEFT and ev.pressed and game.is_stopped() == "Stopped":
			var block = Block.new()
			var x = int(ev.pos.x) / game.map.tile_size
			var y = int(ev.pos.y) / game.map.tile_size
			if x > game.map.width or y > game.map.height:
				return
			game.map.set_object(block, x, y)