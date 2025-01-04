extends Resource
class_name system_job

enum j {
	## Charge by 1, Max 3, Mid Damage (2)
	## Health starts at 5
	## Not intended to be used beyond tutorial
	JOBLESS,
	
	## Charge by 1, Max 6, High Damage (3)
	## Health starts at 7
	## Can left click on players to give armor effect
	KNIGHT,
	
	## Charge by 3, Max 3, Mid Damage (2)
	## Health starts at 6
	## Can left click on players to remove bad effects
	MAGE,
	
	## Charge by 2, Max 4, Low Damage (1)
	## Health starts at 4
	## Can left click on players to heal them
	SAINT,
	
	#Advanced Jobs
	## Charge by 2, Max 6, High Damage (3)
	## Health starts at 8
	## Left click on players will clear and give armor effect
	MAGIC_KNIGHT, #Mage + Knight
	
	## Charge by 4, Max 4, Mid Damage (2)
	## Health starts at 8
	## Left click on players will heal and clear
	DIVINE_SAGE, #Mage + Saint
	
	## Charge by 2, Max 6, High Damage (3)
	## Health starts at 8
	## Left click will heal and give armor effect
	HIGH_PALADIN, #Saint + Knight
	
	## Charge by 2, Max 8, Extra High Damage (4)
	## Health starts at 7
	## Left click will give armor effect
	GUARDIAN, #Knight + Knight
	
	## Charge by 5, Max 5, High Damage (3)
	## Health starts at 7
	## Left click will clear bad effects
	SIBYL, #Mage + Mage
	
	## Charge by 3, Max 6, Mid Damage (2)
	## Health starts at 7
	## Left click will heal
	ORACLE, #Saint + Saint
	
	#Secret Jobs!?
	LEGIONNAIRE, #Abnormal Knight
	ARCANE_MYSTIC, #Abnormal Mage
	OCCULT_PSYCHIC, #Abnormal Saint
}

@export var JOB : j = j.JOBLESS
@export var additional_health : int = 0
@export var additional_max_pcache : int = 0
@export var additional_pcache_charge_amt : int = 0
@export var additional_damage : int = 0

@export var can_guard : bool = false
@export var can_clear : bool = false
@export var can_heal : bool = false
@export var can_parry : bool = false #click attack to...?

var m_pc : int = 3
var pc_c : int = 1
var health : int = 5
var base_dmg : int = 2

var final_m_pc : int
var final_pc_c : int
var final_health : int
var final_base_dmg : int

func setup():
	match JOB:
		j.KNIGHT:
			m_pc = 6
			pc_c = 1
			health = 7
			base_dmg = 3
			can_guard = true
		j.MAGE:
			m_pc = 3
			pc_c = 3
			health = 6
			base_dmg = 2
			can_clear = true
		j.SAINT:
			m_pc = 4
			pc_c = 2
			health = 4
			base_dmg = 1
			can_heal = true
		j.MAGIC_KNIGHT:
			m_pc = 6
			pc_c = 2
			health = 8
			base_dmg = 3
			can_guard = true
			can_clear = true
		j.DIVINE_SAGE:
			m_pc = 4
			pc_c = 4
			health = 8
			base_dmg = 2
			can_clear = true
			can_heal = true
		j.HIGH_PALADIN:
			m_pc = 6
			pc_c = 2
			health = 8
			base_dmg = 3
			can_guard = true
			can_heal = true
		j.GUARDIAN:
			m_pc = 8
			pc_c = 2
			health = 7
			base_dmg = 4
			can_guard = true
		j.SIBYL:
			m_pc = 5
			pc_c = 5
			health = 7
			base_dmg = 3
			can_clear = true
		j.ORACLE:
			m_pc = 6
			pc_c = 3
			health = 7
			base_dmg = 2
			can_heal = true
		j.LEGIONNAIRE: pass
		j.ARCANE_MYSTIC: pass
		j.OCCULT_PSYCHIC: pass
	
	final_m_pc = m_pc + additional_max_pcache
	final_pc_c = pc_c + additional_pcache_charge_amt
	final_health = health + additional_health
	final_base_dmg = base_dmg + additional_damage
