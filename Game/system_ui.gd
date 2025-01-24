extends Node


var system_messages : Array = []
#[Message,Duration]
#Negative means it's duration will elapse when sharing screen time
@onready var system_msg = $cl/Top/Panel/HBoxContainer/system_msg
@onready var console = $cl/Top/consolecont/console
@onready var weapon_inventory = $cl/InGameMenu/MarginContainer/WeaponInventory

func _ready():
	set_title(false)

func play_message(msg : String,dura : float = 1.0):
	if system_msg.text == msg: return
	system_messages.push_front([msg,dura])
	system_msg.text = msg

func _process(delta):
	for m in system_messages:
		m[1] -= delta
	if !system_messages.is_empty() and system_messages[0][1] <= 0.0:
		system_messages.pop_front()
		if system_messages.is_empty(): system_msg.text = ""
		else: system_msg.text = system_messages[0][0]
	
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

@onready var background = $cl/Back/Background
@onready var background_texture = $cl/Back/Background/BackTexture
var btw : Tween #background tween
func set_background(state : bool, colr : Color = Color.BLACK):
	if btw: btw.kill()
	btw = create_tween()
	
	btw.tween_property(background,"color",colr,0.25).set_ease(Tween.EASE_IN_OUT)
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
			#background_texture.material.set_shader_parameter("polar_coordinates",[true,false].pick_random())
			#background_texture.material.set_shader_parameter("spin_rotation",randf_range(5,-5))

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
			titlecont.show()
			titletext.clear()
			if s_colr == Color.BLACK:
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
		Plyrm.Playroom.RPC.call("game_state_update",var_to_str([7,state]),Plyrm.Playroom.RPC.Mode.OTHERS)
	match state:
		true: #Show roar
			rtw.tween_property(roar_sl,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,1.0,0.5,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		false: #Hide roar
			rtw.tween_property(roar_sl,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			rtw.parallel().tween_method(srslmev,0.5,1.0,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)

func srslmev(nv : float): #set roar speed lines mask edge value
	roar_sl.material.set_shader_parameter("mask_edge",nv)


func open_console():
	if weapon_inventory.visible: return
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
	if console.visible: return
	weapon_inventory.visible = !weapon_inventory.visible
	match weapon_inventory.visible:
		true:
			App.can_input = false
		false:
			App.can_input = true

func _on_console_text_submitted(new_text):
	open_console()
	if new_text:
		push_lateral({
			"speaker":"nme",
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

@onready var performance_screen = $cl/Top/PerformanceScreen
func prepare_stats():
	#get all players to stash stats if multiplayer
	await App.time_delay(4.0)
	
	#get all players to show stat screen (then they have to progress through menus on their own)
	performance_screen.setlist()
