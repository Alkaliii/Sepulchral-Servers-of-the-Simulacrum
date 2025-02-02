extends Camera2D

@export var target : Node2D
var offset_target : Vector2 = Vector2.ZERO

@export_group("Shake")
@export var decay := 0.8 #How quickly shaking will stop [0,1].
@export var max_offset := Vector2(100,75) #Maximum displacement in pixels.
@export var max_roll := 0.1 #Maximum rotation in radians (use sparingly).
@export var noise : FastNoiseLite #The source of random values.

var noise_y = 0 #Value used to move through the noise

var trauma := 0.0 #Current shake strength
var trauma_pwr := 3 #Trauma exponent. Use [2,3]

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("camera")
	randomize()
	noise.seed = randi()
	App.tutorial_start.connect(on_tut_begin)
	App.tutorial_end.connect(on_tut_end)
	on_tut_end()

func on_tut_begin():
	limit_left = -500
	limit_top = -250
	limit_right = 500
	limit_bottom = 250

func on_tut_end():
	limit_left = -1000
	limit_top = -500
	limit_right = 1000
	limit_bottom = 500

func set_target(new : Node2D,ofst : Vector2 = Vector2.ZERO):
	target = new
	offset_target = ofst

func sync_target():
	var data : Array = []
	data.append(target.get_path())
	data.append(offset_target)
	
	Plyrm.Playroom.RPC.call("cam_target",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func sync_trauma(amt = trauma, dec := decay):
	var data : Array = []
	data.append(amt)
	data.append(dec)
	
	Plyrm.Playroom.RPC.call("cam_trauma",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func add_trauma(amount : float, dec := decay):
	trauma = min(trauma + amount, 1.0)
	while trauma:
		trauma = max(trauma - dec * get_process_delta_time(), 0)
		await get_tree().process_frame
		shake()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#if Input.is_action_just_pressed("ACTIONA"): add_trauma(10.0)
	
	if target and is_instance_valid(target):
		global_position = lerp(global_position,target.global_position + offset_target,0.5)
	#elif offset.x != 0 or offset.y != 0 or rotation != 0:
		#lerp(offset.x,0.0,1)
		#lerp(offset.y,0.0,1)
		#lerp(rotation,0.0,1)

func shake(): 
	var amt = pow(trauma, trauma_pwr)
	noise_y += 1
	rotation = max_roll * amt * noise.get_noise_2d(100,noise_y)
	offset.x = max_offset.x * amt * noise.get_noise_2d(1000,noise_y)
	offset.y = max_offset.y * amt * noise.get_noise_2d(2000,noise_y)
