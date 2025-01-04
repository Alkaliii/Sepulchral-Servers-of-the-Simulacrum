extends Area2D
class_name HitDetector

enum hdf {
	UNASSIGNED,
	PLAYER,
	ENEMY,
	OBJECT,
	ATTACK,
}

signal DAMAGED
signal AFFLICTED
signal HEALED
signal CLEARED #like status clear
signal GUARDED #like guarded lol
signal CLICKED

@export var hd_for = hdf.UNASSIGNED

var pseudo_control : Control = Control.new()

func _ready():
	add_child(pseudo_control)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if Input.is_action_pressed("ACTIONB"):
			while Input.is_action_pressed("ACTIONB"):
				if player_callback(0): 
					print("ACTION B Intercepted.")
					pseudo_control.accept_event()
				await get_tree().create_timer(0.5).timeout
				if !Input.is_action_pressed("ACTIONB"): break
		if Input.is_action_pressed("ACTIONC"):
			if player_callback(1): 
				print("ACTION C Intercepted.")
				pseudo_control.accept_event()

func player_callback(click : int = 0) -> bool:
	if !is_inside_tree(): return false
	#Deal damage to entity here
	var p : system_controller = get_tree().get_first_node_in_group("player")
	if !p: return false
	
	return determine_and_signal_outcome(p,click)

func determine_and_signal_outcome(p : system_controller, c : int) -> bool:
	var delta
	match hd_for:
		hdf.UNASSIGNED: pass
		hdf.PLAYER:
			if c != 0: return false
			if p.job and p.job.can_heal:
				if !p.discharge(): return false 
				delta = p.calc_heal()
				HEALED.emit(delta)
			if p.job and p.job.can_clear: CLEARED.emit() #free
			if p.job and p.job.can_guard: GUARDED.emit() #free
			print("AID! ",delta)
		hdf.ENEMY:
			match c:
				0: #light
					if p.discharge():
						delta = p.calc_light_dmg()
					else: return false
				1: #heavy
					var pre = p.s_discharge()
					if bool(pre):
						delta = p.calc_heavy_dmg(pre)
					else: return false
			DAMAGED.emit(delta,c)
			AFFLICTED.emit(p.calc_inflict(c))
			print("DMG! ",delta)
		hdf.OBJECT:
			if c != 0: return false
			CLICKED.emit()
		hdf.ATTACK:
			if c != 0: return false
			if p.job and p.job.can_parry: CLICKED.emit()
	return true
