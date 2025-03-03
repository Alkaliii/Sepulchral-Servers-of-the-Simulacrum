extends Node


#var system_messages : Array = []
#[Message,Duration]
#Negative means it's duration will elapse when sharing screen time
@onready var system_msg = $cl/Top/Panel/HBoxContainer/system_msg
@onready var console = $cl/Top/consolecont/console
@onready var weapon_inventory = $cl/InGameMenu/MarginContainer/WeaponInventory
@onready var job_select = $cl/InGameMenu/MarginContainer/JobSelect

func _ready():
	set_title(false)

#func play_message(msg : String,dura : float = 1.0):
	#if system_msg.text == msg: return
	#system_messages.push_front([msg,dura])
	#system_msg.text = msg

func _process(_delta):
	#for m in system_messages:
		#m[1] -= delta
	#if !system_messages.is_empty() and system_messages[0][1] <= 0.0:
		#system_messages.pop_front()
		#if system_messages.is_empty(): system_msg.text = ""
		#else: system_msg.text = system_messages[0][0]
	
	if Input.is_action_just_pressed("open_console") and !console.visible:
		open_console()
	
	if Input.is_action_just_pressed("open_weapon_inventory"):
		open_w_inv()
	
	if check_move() and weapon_inventory.visible: open_w_inv()

func check_move() -> bool:
	if Input.is_action_just_pressed("MDOWN"): return true
	if Input.is_action_just_pressed("MLEFT"): return true
	if Input.is_action_just_pressed("MRIGHT"): return true
	if Input.is_action_just_pressed("MUP"): return true
	return false

func sync_and_set_background(state : bool, colr : Color = Color.BLACK):
	var data = {
		"state":state,
		"colr":colr.to_html()
	}
	var pack = JSON.stringify(data)
	
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_BACKGROUND,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	set_background(state,colr)

@onready var background = $cl/Back/Background
@onready var background_texture = $cl/Back/Background/BackTexture
var btw : Tween #background tween
func set_background(state : bool, colr : Color = Color.BLACK):
	if btw: btw.kill()
	btw = create_tween()
	
	if state: btw.tween_property(background,"color",colr,0.25).set_ease(Tween.EASE_IN_OUT)
	#background.color = colr
	match state:
		true: #open
			background_texture.modulate.a = 25.0/255.0
			background.show()
			btw.parallel().tween_property(background,"scale:y",1.0,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
			#btw.parallel().tween_property(background_texture,"modulate:a",25.0/255.0,0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			await btw.finished
		false: #close
			btw.parallel().tween_property(background_texture,"modulate:a",0.0,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
			btw.parallel().tween_property(background,"scale:y",-1.0,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
			await btw.finished
			background.hide()
			background.color = colr
			#background_texture.material.set_shader_parameter("polar_coordinates",[true,false].pick_random())
			#background_texture.material.set_shader_parameter("spin_rotation",randf_range(5,-5))

func fade_background():
	await create_tween().tween_property(background,"modulate:a",0.0,1.0).set_ease(Tween.EASE_IN_OUT)
	background.hide()
	background.scale.y = -1

func sync_and_set_title(state : bool = true, shake : int = 2, title : String = "", subtitle : String = "", s_colr : Color = Color("#e34262")):
	var data = {
		"state":state,
		"shake":shake,
		"title":title,
		"subtitle":subtitle,
		"s_colr":s_colr.to_html()
	}
	var pack = JSON.stringify(data)
	
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_TITLE,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	set_title(state,shake,title,subtitle,s_colr)

@onready var titlecont = $cl/Top/TITLECONT
@onready var titletext = $cl/Top/TITLECONT/TITLE/pc/TITLETEXT
@onready var title_background = $cl/Top/TITLECONT/TITLE/background
var ttw : Tween #title tween
func set_title(state : bool = true, shake : int = 2, title : String = "", subtitle : String = "", s_colr : Color = Color("#e34262")):
	if ttw: ttw.kill()
	ttw = create_tween()
	
	match state:
		false: #hide
			ttw.tween_property(titlecont,"modulate:a",0,0.25).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished
			titlecont.hide()
			push_title(Vector2.ZERO)
		true:
			if weapon_inventory.visible: open_w_inv()
			titlecont.show()
			titletext.clear()
			if s_colr == Color.BLACK or title.contains("the end"):
				title_background.hide()
			else: title_background.show()
			if subtitle != "":
				titletext.append_text(str("[center][code][color=",s_colr.to_html(),"]",subtitle,"[/color][/code]"))
				titletext.newline()
			var wve = "[wave]" if shake >= 1 else ""
			titletext.append_text(str(wve,title))
			if shake >= 2: titletext.material.set_shader_parameter("normal_offset",1.5)
			else: titletext.material.set_shader_parameter("normal_offset",0.0)
			
			if subtitle != "": titletext.visible_characters = subtitle.length()
			
			ttw.tween_property(titlecont,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished
			await App.time_delay(0.5)
			ttw = create_tween()
			ttw.tween_property(titletext,"visible_ratio",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
			await ttw.finished

func sync_and_push_title(offset : Vector2):
	var pack = var_to_str(offset)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_TITLE_PUSH,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	push_title(offset)

var pttw : Tween #push title tween
func push_title(offset : Vector2):
	if pttw: pttw.kill()
	pttw = create_tween()
	pttw.tween_property(titlecont,"position",Vector2.ZERO + offset,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)

@onready var roar_sl = $effects/RoarSL
var rtw : Tween #roar tween
func roar_effect(state : bool):
	if rtw: rtw.kill()
	rtw = create_tween()
	if Plyrm.connected and Plyrm.Playroom.isHost(): 
		Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.ROAR_FX,state]),Plyrm.Playroom.RPC.Mode.OTHERS)
	match state:
		true: #Show roar
			rtw.tween_property(roar_sl,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,1.0,0.5,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		false: #Hide roar
			rtw.tween_property(roar_sl,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,0.5,1.0,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)

func srslmev(nv : float): #set roar speed lines mask edge value
	roar_sl.material.set_shader_parameter("mask_edge",nv)

@onready var blur = $effects/Blur
var blrtw : Tween
func blur_effect(state : bool):
	if blrtw: blrtw.kill()
	blrtw = create_tween()
	match state:
		true: #show
			blur.show()
			blrtw.tween_property(blur,"modulate:a",1.0,0.5).set_ease(Tween.EASE_IN_OUT)
			blrtw.parallel().tween_method(sbbv,0.0,16.0,0.5).set_ease(Tween.EASE_IN_OUT)
			await blrtw.finished
		false: #hide
			blrtw.tween_property(blur,"modulate:a",0.0,0.5).set_ease(Tween.EASE_IN_OUT)
			blrtw.parallel().tween_method(sbbv,16.0,0.0,0.5).set_ease(Tween.EASE_IN_OUT)
			await blrtw.finished
			blur.hide()

func sbbv(nv):
	blur.material.set_shader_parameter("blur_amount",nv)

func open_console():
	var plyr = get_tree().get_first_node_in_group("player")
	if plyr:
		if plyr.status and plyr.status.current_effects.has(system_status.effects.MUTE): return
	
	if weapon_inventory.visible: open_w_inv()
	console.visible = !console.visible 
	match console.visible:
		true:
			console.clear()
			console.grab_focus()
			App.can_input = false
		false:
			console.release_focus()
			App.can_input = true

func open_w_inv():
	if console.visible: return #open_console()
	weapon_inventory.visible = !weapon_inventory.visible
	match weapon_inventory.visible:
		true:
			if App.can_job_change: job_select.appear(weapon_inventory.visible)
			App.can_input = false
		false:
			job_select.appear(false)
			App.can_input = true

func _on_console_text_submitted(new_text):
	open_console()
	if new_text and new_text[0] != "/":
		sync_and_push_lateral({
			"speaker":str(App.player_name),
			"message":new_text,
			"type":LateralNotification.nt.SELF
		})

func clean_lateral():
	#destory first child?
	var noti = lat_notifications.get_children()
	if noti.size() == 8:
		var min_dur : LateralNotification = noti[0]
		for i : LateralNotification in noti:
			if i.liftime < min_dur.liftime:
				min_dur = i
		#lat_notifications.get_child(0).remove()
		min_dur.remove()

const NOTIPANEL = preload("res://Game/UI/notipanel.tscn")
@onready var notipos = $cl/Top/NotificationCenter/Notification/notipos
@onready var lat_notifications = $cl/Top/NotificationCenter/latNotifications

#display shows a max of 8 msgs at a time, messages persist for 4 seconds by default?
func push_lateral(data : Dictionary = {}):
	clean_lateral()
	var np : Control = Control.new()
	np.custom_minimum_size = Vector2(150,15)
	notipos.add_child(np)
	await get_tree().process_frame
	var ln : LateralNotification = NOTIPANEL.instantiate()
	ln.assign = np
	lat_notifications.add_child(ln)
	ln.global_position = np.global_position + Vector2(-200,0)
	ln.set_noti(data)

func remove_lateral(id : String):
	for n : LateralNotification in lat_notifications.get_children():
		if n.id == id:
			n.remove()

func lat_pop_back():
	lat_notifications.get_child(0).remove()

func clear_lateral():
	for n : LateralNotification in lat_notifications.get_children():
		n.remove()

func set_lateral_duration(id : String, new_duration : float):
	for n : LateralNotification in lat_notifications.get_children():
		if n.id == id:
			n.liftime = new_duration
			break

func sync_and_push_lateral(data : Dictionary = {}):
	var chat_data = data.duplicate()
	if chat_data["type"] == LateralNotification.nt.SELF:
		chat_data["type"] = LateralNotification.nt.CHAT
	var pack = JSON.stringify(chat_data)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_LATERAL,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	push_lateral(data)

func sync_lateral(data : Dictionary = {}):
	var pack = JSON.stringify(data)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_LATERAL,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)

@onready var performance_screen = $cl/Top/PerformanceScreen
func prepare_stats():
	if Plyrm.connected: 
		Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.STASH_METRICS]),Plyrm.Playroom.RPC.Mode.OTHERS)
		var metrics = {
			"name":App.player_name,
			"dmg":App.dmg_dealt,
			"heal":App.healing_performed,
			"rev":App.revolutions_made,
			"click":App.clicks_made
		}
		Plyrm.PLAYER.state.setState("pMetrics",JSON.stringify(metrics))
		
		var boss_metrics = App.performance_screen_details
		Plyrm.Playroom.setState("bMetrics",JSON.stringify(boss_metrics))
	#get all players to stash stats if multiplayer
	await App.time_delay(4.0)
	
	#get all players to show stat screen (then they have to progress through menus on their own)
	performance_screen.setlist()
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.SHOW_PERFORMANCE]),Plyrm.Playroom.RPC.Mode.OTHERS)

func remote_perf():
	performance_screen.setlist()

@onready var level_select = $cl/Top/LevelSelect
func open_level_select(state:bool):
	level_select.appear(state)

func force_close_perf():
	performance_screen.appear(false)

@onready var objectivepanel = $cl/InGameMenu/MarginContainer/objectivepanel
func close_obj():
	objectivepanel.hide_obj()

@onready var config_screen = $cl/Top/ConfigScreen
func open_config(state : bool):
	config_screen.appear(state)

@onready var roomcode = $cl/Top/MarginContainer/ROOMCODE
func display_room_code(code : String):
	if code != "":
		roomcode.text = str("[wave]",code)
		roomcode.show()
	else:
		roomcode.hide()

@onready var settings = $cl/Top/Settings
func open_settings(state : bool):
	settings.appear(state)
