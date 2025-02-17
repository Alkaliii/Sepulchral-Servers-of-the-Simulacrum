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
@export var sight_subject : Node2D
@onready var cs = $CollisionShape2D

var pseudo_control : Control = Control.new()
var disabled := false

func _ready():
	add_child(pseudo_control)
	mouse_exited.connect(on_exit)
	if !sight_subject: 
		sight_subject = get_parent()

var exit : bool = false
func _input_event(_viewport, event, _shape_idx):
	if disabled: return
	if !App.can_click: return
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("ACTIONB"):
			exit = false
			repeat()
			#sfx()
		if Input.is_action_pressed("ACTIONC"):
			if player_callback(1): 
				print("ACTION C Intercepted.")
				heavy_sfx()
				pseudo_control.accept_event()
				App.clicks_made += 1

const hit_sounds = [SoundLib.sound_files.IMPACT_A,SoundLib.sound_files.IMPACT_B]
func sfx():
	var sounds = hit_sounds
	var pitch = randf_range(0.9,1.1)
	
	SystemAudio.play(SoundLib.get_file_sfx(sounds.pick_random()),0.5,"sfx",pitch)

const h_hit_sounds = [SoundLib.sound_files.ATTACK_LIGHTNING_A,SoundLib.sound_files.ATTACK_FIRE_A,SoundLib.sound_files.ATTACK_FIRE_B]
func heavy_sfx():
	var sounds = h_hit_sounds
	var pitch = randf_range(0.9,1.1)
	
	SystemAudio.play(SoundLib.get_file_sfx(sounds.pick_random()),0.8,"sfx",pitch)

func repeat():
	var increment := 0.5
	while Input.is_action_pressed("ACTIONB") and !Input.is_action_just_released("ACTIONB"):
		increment += get_process_delta_time()
		await get_tree().process_frame #change to App?
		if increment > 0.5: 
			increment = 0.0
			if player_callback(0): 
				print("ACTION B Intercepted.")
				sfx()
				pseudo_control.accept_event()
				App.clicks_made += 1
		if !Input.is_action_pressed("ACTIONB"): break
		if exit or disabled: break

func on_exit():
	exit = true

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
			if p.status and p.status.current_effects.has(system_status.effects.MUTE): return false
			
			if p.job and p.job.can_clear: CLEARED.emit() #free
			if p.job and p.job.can_guard: GUARDED.emit() #free
			if p.job and p.job.can_heal:
				if !p.discharge(): return false 
				delta = p.calc_heal()
				HEALED.emit(delta)
				App.healing_performed += delta
			print("AID! ",delta)
		hdf.ENEMY:
			if p.job.need_sight and !p.can_see(sight_subject): return false
			if !p.canDealDamage: return false
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
