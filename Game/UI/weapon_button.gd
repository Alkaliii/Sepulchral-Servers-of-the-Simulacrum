extends Button
class_name WeaponBtn

var weapon : system_weapon :
	set(v):
		weapon = v
		set_icon()

signal hovered
signal unhovered
signal clicked

@onready var highlight = $highlight
@onready var delete = $delete

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
var del_hold : float = 0.0
func _process(delta):
	if inside and Input.is_action_pressed("ACTIONC") and !disabled:
		del_hold += delta
		delete.material.set_shader_parameter("progress", del_hold - 0.5)
	if del_hold >= 1.6:
		delete_weapon()
	elif del_hold >= 0 and !Input.is_action_pressed("ACTIONC"): 
		del_hold -= (delta * 2.0)
		delete.material.set_shader_parameter("progress", del_hold - 0.5)

func delete_weapon():
	set_process(false)
	App.weapon_inventory.erase(weapon)
	pivot_offset = size/2.0
	var tw = create_tween()
	
	var dmspv = func(nv):
		delete.material.set_shader_parameter("progress", nv)
	
	tw.tween_method(dmspv,1.0,0.0,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self,"modulate:a",0.0,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	await tw.finished
	get_parent().remove_child(self)
	queue_free()

func set_icon():
	if !weapon: return
	match weapon.icon:
		weapon.i.DAGGER:
			icon.region = Rect2(0,0,32,32)
		weapon.i.SWORD:
			icon.region = Rect2(32,0,32,32)
		weapon.i.STAFF:
			icon.region = Rect2(64,0,32,32)
		weapon.i.HAMMER:
			icon.region = Rect2(96,0,32,32)
		weapon.i.GLASS:
			icon.region = Rect2(128,0,32,32)
		weapon.i.AXE:
			icon.region = Rect2(160,0,32,32)
		weapon.i.WARAXE:
			icon.region = Rect2(192,0,32,32)
		weapon.i.TRIDENT:
			icon.region = Rect2(224,0,32,32)
		weapon.i.BOW:
			icon.region = Rect2(256,0,32,32)
		weapon.i.BLADE:
			icon.region = Rect2(288,0,32,32)
		weapon.i.GAUNTLET:
			icon.region = Rect2(0,32,32,32)

func set_as_equipped(state:bool):
	match state:
		true:
			disabled = true
			highlight.show()
		false:
			disabled = false
			highlight.hide()

var inside : bool = false
func _on_mouse_entered():
	if !weapon: return
	inside = true
	if weapon.inflict_status != system_status.effects.NONE:
		SystemUI.push_lateral({
		"speaker":"nme",
		"message":"This weapon inflicts status.",
		"type":LateralNotification.nt.SYSTEM,
		"duration":3.0
		})
	hovered.emit(self)

func _on_mouse_exited():
	inside = false
	unhovered.emit()

func _on_pressed():
	release_focus()
	clicked.emit(self)
	#set player weapon
	var img : AtlasTexture = icon.duplicate()
	var icn = img.get_image()
	icn.resize(17,17)
	Input.set_custom_mouse_cursor(icn)
	pass
