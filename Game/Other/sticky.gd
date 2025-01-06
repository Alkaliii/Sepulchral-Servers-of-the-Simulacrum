extends Node2D

var stick : Vector2
# Called when the node enters the scene tree for the first time.
func _ready():
	stick = get_parent().global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var p = get_parent()
	if p: p.global_position = stick
