@tool
extends Node2D
class_name Disperse2D


# I disperse nodes within a set radius randomly

@export var draft : bool = false : 
	set(v):
		draft = false
		disperse()
@export var clear : bool = false :
	set(v):
		clear = false
		clear_nodes()

@export_group("Placement")
## Disperse radius in pixels
@export var radius : float = 200
@export var distort_circle : Vector2 = Vector2(1.0,1.0)
@export var random_range : Vector2 = Vector2(0.0,1.0)
@export var placement_seed : float = 0.0

@export_group("Scene")
@export var disperse_amount : int = 20
@export var select_seed : float = 0.0
@export var nodes_to_disperse : Array[PackedScene] = []
## Nodes dispersed closer to center will be nodes near top of the list to pick from
@export_subgroup("Selection Method")
@export var select_node_by_distance : bool = false 
@export var select_node_by_weight : bool = false
@export var node_weights : PackedFloat32Array = []

@export_group("Other")
## Dispersed nodes will not appear in the scene tree
@export var add_nodes_internally : bool = false
@export var allow_many : bool = false
@export var slow_add : bool = false #every 50 it will wait one frame

func precheck_options() -> bool:
	if disperse_amount <= 0:
		printerr("Please set disperse amount to a positive integer")
		return false
	if nodes_to_disperse.is_empty():
		printerr("err. No nodes set, nothing to disperse")
		return false
	if select_node_by_distance and select_node_by_weight: 
		printerr("err. Please enable only one selection method!")
		return false
	if select_node_by_weight and node_weights.is_empty():
		printerr("err. No weights set")
		return false
	if select_node_by_weight and node_weights.size() != nodes_to_disperse.size():
		printerr("err. Some nodes where not assigned weights, insure you have the same amount of weights as nodes")
		return false
	if disperse_amount > 50 and !allow_many:
		print("You have set to disperse a large amount of nodes, this can crash your editor")
		printerr("If you understand and want to continue anyway, please enable OTHER/ALLOW_MANY")
		return false
	
	return true

func clear_nodes():
	for c in get_children():
		if c.has_meta("from_disperse"):
			remove_child(c)
			c.queue_free()

func disperse():
	if !precheck_options(): return
	
	var pack = Node2D.new()
	add_child(pack)
	pack.set_owner(get_tree().edited_scene_root)
	pack.name = str("dispersePack_",ugen.v4()) #remove ugen if you don't have it, just be careful for name conflicts
	pack.set_meta("from_disperse",true)
	
	var pRNG = RandomNumberGenerator.new()
	pRNG.state = 0
	pRNG.seed = placement_seed
	var sRNG = RandomNumberGenerator.new()
	sRNG.state = 0
	sRNG.seed = select_seed
	
	var new
	var theta : float
	var rah : float
	var pos : Vector2
	
	var didx : int = 0
	for n in disperse_amount:
		if didx == 50 and slow_add:
			await get_tree().process_frame
			didx = 0
		
		# determine position
		theta = pRNG.randf_range(0.0,TAU)
		rah = pRNG.randf_range(random_range.x,random_range.y) * radius
		pos = Vector2(rah * cos(theta),rah * sin(theta))
		pos *= distort_circle
		
		# instance and add
		new = get_scene(sRNG,rah).instantiate()
		pack.add_child(new,false,Node.INTERNAL_MODE_FRONT if add_nodes_internally else Node.INTERNAL_MODE_DISABLED)
		new.set_owner(get_tree().edited_scene_root)
		new.position = pos
		
		didx += 1

func get_scene(sRNG : RandomNumberGenerator,rah : float) -> PackedScene:
	var idx : int
	if select_node_by_distance:
		idx = int(round(remap(rah,0.0,radius,0.0,float(nodes_to_disperse.size() - 1))))
	elif select_node_by_weight:
		idx = sRNG.rand_weighted(node_weights)
	else:
		idx = sRNG.randi_range(0,nodes_to_disperse.size() - 1)
	
	return nodes_to_disperse[idx]
