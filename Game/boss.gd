extends CharacterBody2D
class_name system_monster_controller

@export var monster_data : system_monster
@export var monster_weapon : system_weapon
@export var phases : Array[Phase] = []

@export var SPEED = 80.0
@export var SPEED_MULTIPLIER := 1.0
@export var DASH_STRENGTH := 20.0
@export var FRICTION := 0.2
@export var ACCELERATION := 0.3
var DIRECTION : Vector2 = Vector2.ZERO

@onready var hit_detector = $HitDetector
@onready var healthbar = $CanvasLayer/stats/MarginContainer/VBoxContainer/healthbar

#behaviours are processed on host

const FTXT = preload("res://Game/float_text.tscn")

var halfway_dead := false 
#this causes double time
#movement speed will increase by 2x
#if applicable attack spawn interval will get shorter
var dead := false
var tiktok := false
var time_elapsed := 0.0
var total_time_elapsed := 0.0

# On host, phase is selected, this is propagated via RPC to client bosses
# During phase an attack is called, this is also propagated via RPC to client bosses
# The RPC call may send additional data about the attack so the one performed on the client side is similar to host
# Using the phase movement, the host will move, clients will sync using state

func _ready():
	App.start_boss.connect(test_start)
	App.reload_boss.connect(reload)
	#Plyrm.PR_PLAYER_JOIN.connect(check_host)
	#Plyrm.PR_PLAYER_QUIT.connect(check_host)
	#Plyrm.PR_SESSION_END.connect(check_host)
	#Plyrm.PR_DISCONNECT.connect(check_host)
	
	hit_detector.disabled = true
	add_to_group("monster")
	monster_data.status.setup(App.determine_boss_health(monster_data.health_mod,monster_data.clamp_health))
	#healthbar.max_value = monster_data.base_health
	#healthbar.value = monster_data.status.health
	hit_detector.DAMAGED.connect(on_damage)
	hit_detector.AFFLICTED.connect(on_afflict)
	monster_data.status.DOT.connect(show_other_damage)
	if OS.has_feature("pc") or !Plyrm.connected: test_start()

func test_start():
	await get_tree().create_timer(3.0).timeout
	await SystemUI.sync_and_set_title(true,2,monster_data.name,monster_data.stitle,Color("#a89f94"))
	hit_detector.disabled = false
	await roar(str("You encounter [shake]",monster_data.name))
	#SystemAudio.sync_and_play_music(SoundLib.get_file(monster_data.normal_music))
	jukebox(monster_data.normal_music)
	time_elapsed = 0.0
	tiktok = true
	SystemUI.sync_and_set_title(false)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.DISABLE_CLIENT_BOSS]),Plyrm.Playroom.RPC.Mode.OTHERS)
	test_phase()

func check_host(args = null):
	if Plyrm.PLAYER and !Plyrm.Playroom.isHost():
		print("kys")
		hit_detector.disabled = false
		set_physics_process(false)
		kill_phase()
		return
	else:
		set_physics_process(true)
		#test_start()
		#restart the game...?

func reload():
	kill_phase()
	hit_detector.disabled = true
	dead = false
	halfway_dead = false
	monster_data.status.reload()
	global_position = Vector2.ZERO
	if is_physics_processing(): SystemAudio.sync_and_stop_music()
	App.purge_attacks.emit()
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.PURGE_ATTACKS]),Plyrm.Playroom.RPC.Mode.OTHERS)

func test_phase():
	if phases.is_empty(): return
	
	for i in phases:
		i.setup(self)
	
	await App.process_frame()
	
	#phases[0].is_active = true
	#phases[0].play_phase()
	change_phase(0)
	
	#while true:
		#phases[0].ATTACK_OPTIONS[0].attack(self)
		#await phases[0].ATTACK_OPTIONS[0].attack_complete
		#phases[0].SPECIAL_OPTIONS[0].perfrom_special(self)
		#await phases[0].SPECIAL_OPTIONS[0].special_complete
		#phases[0].MOVEMENT_OPTIONS[0].move(self)
		#await phases[0].MOVEMENT_OPTIONS[0].movement_complete

var active_phase : Phase
func change_phase(new_phase : int = -1):
	if phases.is_empty(): return
	kill_phase()
	await App.process_frame()
	print("CHANGING PHASE!"," RANDOM" if new_phase == -1 else str(new_phase))
	var phs : Phase
	if new_phase and new_phase != -1: 
		phs = phases[new_phase]
		start_phase(phs)
		return
	else: 
		var pick : Array[Phase] = []
		for p in phases:
			match p.context_exclusive:
				Phase.e.NORMAL when !halfway_dead: pick.append(p)
				Phase.e.HALFWAY when halfway_dead: pick.append(p)
				Phase.e.BOTH: pick.append(p)
		if pick.is_empty(): pick.append(phases[0])
		phs = pick.pick_random()
	
	start_phase(phs)

func start_phase(phs : Phase):
	if phases.is_empty(): return
	phs.clean_actions()
	phs.is_active = true
	phs.cancel = false
	phs.last_phase_action = false
	phs.phase_idx = 0
	active_phase = phs #sync active phase?
	phs.play_phase()

func kill_phase():
	print("kill")
	for phs in phases: 
		phs.kill_phase()

@onready var boss_sprite = $Sprite
var dtw : Tween
func disappear(state : bool):
	if dtw: dtw.kill()
	dtw = create_tween()
	if Plyrm.connected: sync_disappear(state)
	match state:
		true:
			set_collision_layer_value(1,false)
			hit_detector.disabled = true
			dtw.tween_property(self,"scale",Vector2.ZERO,0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			await dtw.finished
			hide()
		false:
			show()
			dtw.tween_property(self,"scale",Vector2.ONE,0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			await dtw.finished
			set_collision_layer_value(1,true)
			hit_detector.disabled = false

func sync_disappear(state : bool):
	if !Plyrm.Playroom.isHost(): return #prevent spiralling disappear calls
	Plyrm.Playroom.RPC.call("hide_boss",var_to_str(state),Plyrm.Playroom.RPC.Mode.OTHERS)

@onready var sight = $Sight
func check_position(pos : Vector2) -> Vector2:
	sight.target_position = pos - sight.global_position
	if sight.is_colliding():
		return sight.get_collision_point()
	else:
		return pos

func on_afflict(c : Array):
	if c[0] != system_status.effects.NONE:
		print("Afflict ",system_status.effects.keys()[c[0]]," ",c[1])
	if c[0] == system_status.effects.STUN and !monster_data.status.current_effects.has(system_status.effects.STUN):
		kill_phase()
		await App.process_frame()
		active_phase.clean_actions()
		active_phase.is_active = true
		active_phase.cancel = false
		active_phase.last_phase_action = false
		active_phase.phase_idx = 0
		active_phase.pWAIT(c[1])
	monster_data.status.add_effect(c[0],c[1])

func on_damage(amt : int, click : int): #send player data in
	#check condition before validating
	if dead: return
	if active_phase and !active_phase.validate_damage(click): 
		return
	
	disp_ftxt(str(amt,"!" if click == 1 else ""),global_position - Vector2(0,45),[FloatingText.a.POP,FloatingText.a.POP_SHOOT].pick_random())
	var cam = get_tree().get_first_node_in_group("camera")
	match click:
		0: 
			hit_vfx(true)
			cam.add_trauma(0.4,0.9)
		1: 
			hit_vfx()
			cam.add_trauma(1,0.8)
			for p in phases:
				p.on_heavy_received()
	
	App.dmg_dealt += amt
	if Plyrm.PLAYER and !Plyrm.PLAYER.host: 
		sync_damage(amt,click)
		return
	
	monster_data.status._damage(amt)
	healthbar.value = monster_data.status.health
	
	check_progress()

func sync_damage(amt : int, click : int):
	var data : Array = []
	data.append(amt)
	data.append(click)
	
	Plyrm.Playroom.RPC.call("dmg_boss",var_to_str(data),Plyrm.Playroom.RPC.Mode.HOST)

func remote_damage(amt : int, click : int):
	if dead: return
	if active_phase and !active_phase.validate_damage(click): 
		return
	
	if click == 1:
		for p in phases:
			p.on_heavy_received()
	
	monster_data.status._damage(amt)
	print("remote dmg : ",amt)
	check_progress()
	#healthbar.value = monster_data.status.health

func show_other_damage(od : int = 1):
	disp_ftxt(str(od),global_position - Vector2(0,45),[FloatingText.a.POP,FloatingText.a.POP_SHOOT].pick_random())

func check_progress():
	if monster_data.status.health <= 0.0 and !dead:
		kill_phase()
		tiktok = false
		dead = true
		App.purge_attacks.emit()
		if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.PURGE_ATTACKS]),Plyrm.Playroom.RPC.Mode.OTHERS)
		App.performance_screen_details["time"] = time_elapsed
		App.performance_screen_details["total_time"] = total_time_elapsed
		App.performance_screen_details["bhp"] = monster_data.status.max_health
		await roar(str(monster_data.name," has been defeated."))
		
		#Things like this should be one gsu call... It doesn't change so you can just tell the client to do it on their side
		#please keep in mind for future
		SystemUI.sync_and_set_title(true,2,fTxt.victorytitle,fTxt.victorySubtitles.pick_random(),Color("#a89f94"))
		SystemUI.sync_and_set_background(true,Color.BLACK)
		SystemUI.sync_and_push_title(Vector2(0,-80))
		SystemUI.prepare_stats()
	elif monster_data.status.health < (monster_data.status.max_health * .5) and !halfway_dead:
		kill_phase()
		halfway_dead = true
		#SystemAudio.sync_and_play_music(SoundLib.get_file(monster_data.halfway_music))
		jukebox(monster_data.halfway_music)
		await roar(str(monster_data.name," is weak!"))
		if !phases.is_empty(): 
			#start_phase(phases.pick_random())
			change_phase()


func jukebox(filekey : SoundLib.music_files):
	if filekey in SoundLib.has_intro:
		var intro : String
		var loop : String
		match filekey:
			SoundLib.music_files.BATTLE_KANNAGI, SoundLib.music_files.BATTLE_KANNAGI_INTRO:
				intro = SoundLib.get_file(SoundLib.music_files.BATTLE_KANNAGI_INTRO)
				loop = SoundLib.get_file(SoundLib.music_files.BATTLE_KANNAGI)
			SoundLib.music_files.BATTLE_MASYOU, SoundLib.music_files.BATTLE_MASYOU_INTRO:
				intro = SoundLib.get_file(SoundLib.music_files.BATTLE_MASYOU_INTRO)
				loop = SoundLib.get_file(SoundLib.music_files.BATTLE_MASYOU)
			SoundLib.music_files.BATTLE_ARIADNE, SoundLib.music_files.BATTLE_ARIADNE_INTRO:
				intro = SoundLib.get_file(SoundLib.music_files.BATTLE_ARIADNE_INTRO)
				loop = SoundLib.get_file(SoundLib.music_files.BATTLE_ARIADNE)
			SoundLib.music_files.BATTLE_TRUTH, SoundLib.music_files.BATTLE_TRUTH_INTRO:
				intro = SoundLib.get_file(SoundLib.music_files.BATTLE_TRUTH_INTRO)
				loop = SoundLib.get_file(SoundLib.music_files.BATTLE_TRUTH)
		
		SystemAudio.sync_and_play_intro_then_loop(intro,loop)
		return
	else:
		SystemAudio.sync_and_play_music(SoundLib.get_file(filekey))

func roar(msg : String = "!!!"):
	App.can_click = false
	var cam = get_tree().get_first_node_in_group("camera")
	cam.set_target(boss_sprite,Vector2(0,-45))
	if Plyrm.connected: cam.sync_target()
	await get_tree().create_timer(0.5).timeout
	cam.add_trauma(10)
	SystemAudio.sync_and_play(SoundLib.get_file_sfx(monster_data.roar))
	if Plyrm.connected: cam.sync_trauma(10)
	SystemUI.roar_effect(true)
	await get_tree().create_timer(2.5).timeout
	SystemUI.roar_effect(false)
	cam.set_target(get_tree().get_first_node_in_group("player_persistant"))
	if Plyrm.connected: cam.sync_target()
	App.can_click = true
	await App.time_delay(0.5)
	SystemUI.sync_and_push_lateral({
	"speaker":"nme",
	"message":msg,
	"type":LateralNotification.nt.SYSTEM,
	"duration":6.0
	})

@onready var pull_vfx = $PullVFX
func pull(state:bool,sscl:float = 1.0):
	if state: pull_vfx.speed_scale = sscl
	pull_vfx.emitting = state

@onready var push_vfx = $PushVFX
func push(state:bool,sscl:float = 1.0):
	if state: push_vfx.speed_scale = sscl
	push_vfx.emitting = state

func disp_ftxt(text : String, pos : Vector2, anim : FloatingText.a = FloatingText.a.FLOAT, outline : Dictionary = {}):
	var new = FTXT.instantiate()
	new.inital_position = pos
	new.anim = anim
	new.text = text
	if outline:
		new.outline_color = outline.color
		new.outline_size = outline.size
	get_parent().add_child(new)

func _physics_process(delta):
	if active_phase and !active_phase.cur_option is phaseMovementOption:
		velocity = lerp(velocity,Vector2.ZERO,0.5)
	sync_state()
	#check_host()
	#chase(delta)

func _process(delta):
	if tiktok: 
		time_elapsed += delta
		total_time_elapsed += delta
	if Plyrm.PLAYER and !is_physics_processing():
		var data
		var boss_state = Plyrm.Playroom.getState("bState")
		if boss_state: data = JSON.parse_string(boss_state)
		else: return
		
		remote_drag()
		var pos = Vector2(data.pos_x,data.pos_y)
		var rsd = str_to_var(data.stare_dir)
		if stare_dir != rsd:
			stare(rsd)
		create_tween().tween_property(self,"global_position",pos,0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	else:
		if !monster_data.status.current_effects.is_empty():
			monster_data.status.process_current(delta)

var rd_target : Array
func remote_drag():
	var boss_drag_data
	var boss_drag_state = Plyrm.Playroom.getState("bDrag")
	if boss_drag_state: 
		boss_drag_data = JSON.parse_string(boss_drag_state)
		if boss_drag_data["is_drag"]:
			if !rd_target or rd_target[1] != boss_drag_data["to"]:
				rd_target = []
				rd_target.append(get_node_or_null(boss_drag_data["to"]))
				rd_target.append(boss_drag_data["to"])
			#drag(rd_target[0].global_position,boss_drag_data["strr"])
			if boss_drag_data["strr"] > 0: #pull
				pull(true,1.0 + (abs(boss_drag_data["strr"] / 30.0) / 10.0))
			elif boss_drag_data["strr"] < 0: #push
				push(true,1.0 + (abs(boss_drag_data["strr"] / 30.0) / 10.0))
		else: 
			rd_target.clear()
			pull(false)
			push(false)

func sync_state():
	var state = {
		"pos_x":global_position.x,
		"pos_y":global_position.y,
		"stare_dir":var_to_str(stare_dir)
		#"on_cooldown": !(dash_cooldown <= 0.0),
		#"direction":var_to_str(DIRECTION)
	}
	if Plyrm.PLAYER: 
		#Plyrm.Playroom.setState(str("pState_",Plyrm.PLAYERData.id),JSON.stringify(state))
		Plyrm.Playroom.setState("bState",JSON.stringify(state))

func sync_drag(state : bool, to : NodePath = "", strr : float = 0):
	var drag_state = {
		"is_drag":state,
		"to":to,
		"strr":strr
	}
	if Plyrm.PLAYER:
		Plyrm.Playroom.setState("bDrag",JSON.stringify(drag_state))

var htwA : Tween
var htwB : Tween
@onready var hit_impact_vfx = $HitImpactVFX
@onready var hit_impact_vfxb = $HitImpactVFXB
func hit_vfx(small:=false):
	#print("hi",hit_impact_vfxb.material.get_shader_parameter("progress"),hit_impact_vfx.material.get_shader_parameter("progress"))
	flash_vfx()
	if float(!hit_impact_vfxb.material.get_shader_parameter("progress")) in [1.0,0.0]:
		#use A
		hit_impact_vfx.pivot_offset = hit_impact_vfx.size / 2.0
		if small: hit_impact_vfx.scale = Vector2(0.8,0.8)
		else: hit_impact_vfx.scale = Vector2.ONE
		hit_impact_vfx.rotation = randf_range(0,TAU)
		var spv = func(nv):
			hit_impact_vfx.material.set_shader_parameter("progress",nv)
		if htwA: htwA.kill()
		htwA = create_tween()
		htwA.tween_method(spv,0.0,1.0,0.75).set_ease(Tween.EASE_IN_OUT)
	elif float(!hit_impact_vfx.material.get_shader_parameter("progress")) in [1.0,0.0]:
		#use B
		hit_impact_vfxb.pivot_offset = hit_impact_vfxb.size / 2.0
		if small: hit_impact_vfxb.scale = Vector2(0.8,0.8)
		else: hit_impact_vfxb.scale = Vector2.ONE
		hit_impact_vfxb.rotation = randf_range(0,TAU)
		var spv = func(nv):
			hit_impact_vfxb.material.set_shader_parameter("progress",nv)
		if htwB: htwB.kill()
		htwB = create_tween()
		htwB.tween_method(spv,0.0,1.0,0.75).set_ease(Tween.EASE_IN_OUT)
	else:
		#use A regardless
		hit_impact_vfx.pivot_offset = hit_impact_vfx.size / 2.0
		if small: hit_impact_vfx.scale = Vector2(0.8,0.8)
		else: hit_impact_vfx.scale = Vector2.ONE
		hit_impact_vfx.rotation = randf_range(0,TAU)
		var spv = func(nv):
			hit_impact_vfx.material.set_shader_parameter("progress",nv)
		if htwA: htwA.kill()
		htwA = create_tween()
		htwA.tween_method(spv,0.0,1.0,0.75).set_ease(Tween.EASE_IN_OUT)

func flash_vfx(hold_frames : int = 10):
	$Starburst.emitting = true
	$Starburst2.emitting = true
	boss_sprite.material.set_shader_parameter("active",true)
	for i in hold_frames:
		await App.process_frame()
	boss_sprite.material.set_shader_parameter("active",false)

var stare_dir : Vector2 = Vector2.ZERO
func stare(dir : Vector2 = Vector2.ZERO):
	stare_dir = dir
	print("stare ",dir)
	if dir == Vector2.ZERO:
		boss_sprite.flip_h = [true,false].pick_random()
		print("rand flip")
		return
	if dir.x < 0.0: 
		boss_sprite.flip_h = false
	else: boss_sprite.flip_h = true

#func set_behaviour_time(new_dura : float):
	#behaviour_time_elapse = 0.0
	#behaviour_duration = new_dura
#
#var behaviour_time_elapse : float = 0.0
#var behaviour_duration : float = 10.0
#var chase_target : Node2D
#func chase(delta):
	##Set target
	#if !chase_target or (behaviour_time_elapse >= behaviour_duration):
		#set_behaviour_time(randf_range(10,20))
		#var possible_target : Array = get_tree().get_nodes_in_group("puppet")
		#possible_target.append(get_tree().get_first_node_in_group("player"))
		#chase_target = possible_target.pick_random()
	#
	##run away sorta DIRECTION = (global_position - chase_target.global_position).normalized()
	#DIRECTION = (chase_target.global_position - global_position).normalized()
	#if DIRECTION:
		#velocity = lerp(velocity,DIRECTION * (SPEED * SPEED_MULTIPLIER),ACCELERATION)
		##last_direction = DIRECTION
	#else:
		#velocity = lerp(velocity,Vector2.ZERO,FRICTION)
	#
	#behaviour_time_elapse += delta
	#move_and_slide()
