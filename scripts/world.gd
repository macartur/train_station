
extends Node

# LOAD OBJECTS
const agent_scene = preload("res://objects/agent.tscn")
const door_scene = preload('res://objects/door.tscn') 
const block_scene = preload('res://objects/block.tscn')

class Agent:
	var object   #  object of scene
	var name     #  Agent name
	var target   #  Target Cell
	
	func _init(name='Agent',target=[0,0]):
		self.object = agent_scene.instance()
		self.name = name
		self.target=target
		
	func should_move(next_x, next_y, x,y):
		print([next_x, next_y],[x,y])
		return false

class Door:
	var object  # object of scene
	func _init():
		self.object = door_scene.instance()

class Block:
	var object  # object of scene
	func _init():
		self.object = block_scene.instance()

class Map:
	var board
	var tile_size
	var width
	var height
	var object
	var targets = []
	func _init(width=40, height=30, object=null):
		self.board = []
		self.tile_size = 20
		self.width = width
		self.height = height
		self.object = object
		self._fill_board()

	func _fill_board():
		for line in range(width):
			var columns  = []
			for column in range(height):
				columns.append(0)
			self.board.append(columns)
	
	func add_object(instance, x, y):
		self.board[x][y] = instance
		instance.object.set_pos(Vector2(self.tile_size*x, self.tile_size*y))

	# UPDATE AGENTS
	func update():
		for line in range(self.width):
			for column in range(self.height):
				for x in range(line, line+3):
					for y in range(column, column+3):
						if x >= self.width or y >= self.height or x < 0 or y < 0:
							continue
						var obj = self.board[x][y]
						if not (typeof(obj) == TYPE_INT ):
							var opt2 = ('Agent' in obj.type())
							var opt3 = (typeof(self.board[line][column]) == TYPE_INT)
							var opt4 = obj.should_move(line, column, x, y)
							if  opt2 and opt3 and opt4:
								self.board[x][y] = 0
								self.add_object(obj, line, column)

#  GAME LOOP
var map = Map.new()

func _ready():
#	set_process(true)
#	create_agents(3)
	#create_blocks()
	pass
	
	
var last = 1

func _process(delta):
	last -= delta
	if last <= 0:
		last = 1
		map.update()

func create_agents(number=10):
#	for x in range(number):
#		var agent1 = Agent.new('Agent'+str(x),[39,28])
#		map.add_object(agent1, x, 4)
#		add_child(agent1.object)
	var agent1 = Agent.new('Agent'+str(1),[4,8])
	map.add_object(agent1, 8, 8)
	add_child(agent1.object)

func create_blocks():
	for x in range(3):
		var door1 = Door.new()
		map.add_object(door1, 0, 1+x)
		add_child(door1.object)