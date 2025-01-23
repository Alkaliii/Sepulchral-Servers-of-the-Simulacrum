extends VBoxContainer

@onready var list = $invsc/vbx/List

const WEAPON_BUTTON = preload("res://Game/UI/weapon_button.tscn")

@onready var stats = $Stats
@onready var weapon_type = $Stats/weaponType
@onready var p_dmg = $Stats/dmg/pDmg
@onready var s_dmg = $Stats/dmg/sDmg
@onready var t_dmg = $Stats/dmg/tDmg

@onready var invsc = $invsc
@onready var slsh = $Stats/dmg/slash
@onready var slsh_2 = $Stats/dmg/slash2

# Called when the node enters the scene tree for the first time.
func _ready():
	on_wbtn_unhover()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("open_weapon_inventory"):
		load_inv()

func size_inv():
	print(App.weapon_inventory)
	var dif = App.weapon_inventory.size() - list.get_child_count()
	if dif < 0: #Negative, need to remove spots
		for i in dif:
			var remove = list.get_child(list.get_child_count() - 1)
			list.remove_child(remove)
			remove.queue_free()
	else: #Positive or Zero, add or do nothing
		for i in dif:
			var add = WEAPON_BUTTON.instantiate()
			add.hovered.connect(on_wbtn_hover)
			add.unhovered.connect(on_wbtn_unhover)
			add.clicked.connect(on_wbtn_click)
			list.add_child(add)

func on_wbtn_hover(wbtn : WeaponBtn):
	stats.show()
	var wve = "[wave]" if wbtn.weapon.inflict_status != system_status.effects.NONE else ""
	weapon_type.text = str(wve,"[code]%s[/code]") % str(system_weapon.i.keys()[wbtn.weapon.icon],
	"!" if wbtn.weapon.inflict_status != system_status.effects.NONE else "")
	p_dmg.text = str(system_weapon.wd.keys()[wbtn.weapon.primary_damage]).replace("D","")
	if wbtn.weapon.secondary_damage != system_weapon.wd.D0:
		s_dmg.text = str(system_weapon.wd.keys()[wbtn.weapon.secondary_damage]).replace("D","")
		slsh.show()
	else: 
		s_dmg.text = ""
		slsh.hide()
	if wbtn.weapon.tertiary_damage != system_weapon.wd.D0:
		t_dmg.text = str(system_weapon.wd.keys()[wbtn.weapon.tertiary_damage]).replace("D","")
		slsh_2.show()
	else:
		t_dmg.text = ""
		slsh_2.hide()

func on_wbtn_unhover():
	var w = get_player_weapon()
	if !w:
		if list.get_children().is_empty(): stats.hide()
		return
	weapon_type.text = "[code]CURRENT[/code]"
	p_dmg.text = str(system_weapon.wd.keys()[w.primary_damage]).replace("D","")
	if w.secondary_damage != system_weapon.wd.D0:
		s_dmg.text = str(system_weapon.wd.keys()[w.secondary_damage]).replace("D","")
		slsh.show()
	else: 
		s_dmg.text = ""
		slsh.hide()
	if w.tertiary_damage != system_weapon.wd.D0:
		t_dmg.text = str(system_weapon.wd.keys()[w.tertiary_damage]).replace("D","")
		slsh_2.show()
	else:
		t_dmg.text = ""
		slsh_2.hide()

func on_wbtn_click(wbtn : WeaponBtn):
	if !plyr: plyr = get_tree().get_first_node_in_group("player")
	if !plyr: return
	
	plyr.weapon = wbtn.weapon
	if equip: equip.set_as_equipped(false)
	wbtn.set_as_equipped(true)
	equip = wbtn
	
	list.move_child(equip,0)
	create_tween().tween_property(invsc,"scroll_horizontal",0.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

var equip : WeaponBtn
func load_inv():
	size_inv()
	await get_tree().process_frame
	if App.weapon_inventory.is_empty(): 
		on_wbtn_unhover()
		return
	
	var idx = 0
	for i : WeaponBtn in list.get_children():
		i.weapon = App.weapon_inventory[idx]
		if i.weapon == get_player_weapon():
			i.set_as_equipped(true)
			equip = i
		else: i.set_as_equipped(false)
		idx += 1
	
	if equip:
		list.move_child(equip,0)
		create_tween().tween_property(invsc,"scroll_horizontal",0.0,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

var plyr : system_controller
func get_player_weapon() -> system_weapon:
	if !plyr: plyr = get_tree().get_first_node_in_group("player")
	if !plyr: return null
	return plyr.weapon
