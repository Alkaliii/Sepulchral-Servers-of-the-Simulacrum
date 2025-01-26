extends Node2D

@onready var hit_detector = $HitDetector

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("monster")
	hit_detector.DAMAGED.connect(on_damage)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_damage(amt,click):
	disp_ftxt(str(amt,"!" if click == 1 else ""),global_position - Vector2(0,0),[FloatingText.a.POP,FloatingText.a.POP_SHOOT].pick_random())
	var cam = get_tree().get_first_node_in_group("camera")
	match click:
		0: 
			#flash_vfx()
			cam.add_trauma(0.4,0.9)
		1: 
			#hit_vfx()
			cam.add_trauma(1,0.8)
	App.tutorial_click.emit(click)

const FTXT = preload("res://Game/float_text.tscn")
func disp_ftxt(text : String, pos : Vector2, anim : FloatingText.a = FloatingText.a.FLOAT, outline : Dictionary = {}):
	var new = FTXT.instantiate()
	new.inital_position = pos
	new.anim = anim
	new.text = text
	if outline:
		new.outline_color = outline.color
		new.outline_size = outline.size
	get_parent().add_child(new)
