
extends Node

const tile = preload("res://tile.tscn")
const agent_texture = preload('res://agent.png')

const world_w = 800
const world_h = 600
var tile_size = 10
var map = []
var last_update = 1

func _ready():
	set_process(true)
	create_map()

func _process(delta):
	last_update -= delta
	
	if last_update < 0:
		last_update = 1
		remove_square()

func remove_square():
	var number_h = randi()%(map.size())
	var number_w = randi()%(map[0].size())
	var sprite = map[number_h][number_w].get_child(0)
	# sprite.set_texture(agent_texture)
	var message = str(map.size()) +" - " + str(map[0].size())
	print(message)

func create_map():
	for line in range(1,world_w/tile_size):
		var columns  = []
		for column in range(1,world_h/tile_size):
			var new_tile = tile.instance()
			add_child(new_tile)
			new_tile.set_pos(Vector2((line * tile_size), (column * tile_size)))
			columns.append(new_tile)
		map.append(columns)
		
