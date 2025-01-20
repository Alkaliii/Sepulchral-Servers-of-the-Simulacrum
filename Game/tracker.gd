extends Control

var target : Node2D
@export var player : CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !target: target = get_tree().get_first_node_in_group("monster")
	
	var dir : Vector2 = (player.global_position - target.global_position).rotated(deg_to_rad(-90))
	
	rotation = dir.angle()
