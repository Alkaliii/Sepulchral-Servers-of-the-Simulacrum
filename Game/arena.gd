extends Node2D

#Manages The Arena
#eg. regenerating enviroment
#eg. placing down boss, player, and puppets

const PUPPET = preload("res://Game/puppet.tscn")
const DAMAGE_RADIUS = preload("res://Game/damage_radius.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Plyrm.PR_PLAYER_JOIN.connect(on_player_join)
	App.spawn_dmg.connect(spawn_dmg)
	App.load_boss.connect(load_boss)
	App.load_misc.connect(load_misc)
	
	App.debug_line.connect(debug_draw_line)

func gen_loot():
	await App.process_frame()
	var states : Array = []
	var barrels = get_tree().get_nodes_in_group("loot")
	for l in barrels:
		states.append(l.loot_state)
	
	if states.has(false):
		for l in barrels:
			if l.loot_state:
				l.queue_free()
	else: #delete 1
		barrels.pick_random().queue_free()

func spawn_dmg(pos : Vector2, data : DamageRadiusSettings):
	var new = DAMAGE_RADIUS.instantiate()
	new.settings = data
	add_child(new)
	new.top_level = true
	new.global_position = pos
	new.warn()

func load_boss(file : String):
	if !file.is_absolute_path(): 
		printerr("What the fuck is, ",file,"?")
		return
	var rldr = ResourceLoader
	rldr.load_threaded_request(file)
	
	var load_file #= load(file)
	var progress : Array = []
	var status
	while true:
		await App.process_frame()
		status = rldr.load_threaded_get_status(file,progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_file = rldr.load_threaded_get(file)
			await App.time_delay(0.2)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			printerr("load failed")
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"err: Background loading failed",
			"type":LateralNotification.nt.DANGER,
			"duration":18.0
			})
			break
	
	if load_file and load_file is PackedScene:
		var new = load_file.instantiate()
		add_child(new)
	App.load_complete.emit()
	print("loaded ",file)

func load_misc(file : String):
	if !file.is_absolute_path(): 
		printerr("What the fuck is, ",file,"?")
		return
	var rldr = ResourceLoader
	rldr.load_threaded_request(file)
	
	var load_file #= load(file)
	var progress : Array = []
	var status
	while true:
		await App.process_frame()
		status = rldr.load_threaded_get_status(file,progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_file = rldr.load_threaded_get(file)
			await App.time_delay(0.2)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			printerr("load failed")
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"err: Background loading failed",
			"type":LateralNotification.nt.DANGER,
			"duration":18.0
			})
			break
	
	if load_file and load_file is PackedScene:
		var new = load_file.instantiate()
		add_child(new)
	App.load_complete.emit()
	print("loaded ",file)
	gen_loot()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_player_join(args):
	if Plyrm.PLAYER and args[0].id == Plyrm.PLAYER.id: return
	var puppets = get_tree().get_nodes_in_group("puppet")
	for p : system_player_puppet in puppets:
		if p.my_id == args[0].id:
			p.state = args[0]
			return
	
	var inst = PUPPET.instantiate()
	inst.state = args[0]
	add_child(inst)
	inst.position.x = randf_range(30,60)
	inst.my_id = args[0].id
	

func debug_draw_line(p : Array):
	var new = Line2D.new()
	new.points = PackedVector2Array(p)
	new.default_color = Color.GREEN
	add_child(new)
	#new.global_position = p[0]
	await App.time_delay(8.0)
	new.queue_free()
