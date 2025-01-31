extends Resource
class_name system_monster

@export var stitle : String = "vanguard of observation"
@export var name : String = "System Unit Test"
@export var health_mod : float = 1.0
@export var clamp_health : int = 0 #no clamp on 0
@export var status : system_status
@export var normal_music : SoundLib.music_files = SoundLib.music_files.BATTLE_DAWN
@export var halfway_music : SoundLib.music_files = SoundLib.music_files.BATTLE_KANNAGI
@export var roar : SoundLib.sound_files = SoundLib.sound_files.MONSTER_GROWL_A

#Behaviours
enum b {
	NONE,
	REST, 
		#Rest, Stops in place and does nothing, optional chance to heal
		#If the attacked it will switch to a new state
	STUN, 
		#Stun, Stops in place and does nothing
	
	#MOVEMENT
	CHASE, 
		#Chase, Picks a player or puppet to follow, places a dr down on the subject when close enough
		#If heavy attacked it will chase the attacker
	POUNCE, 
		#Pounce, Picks a player and rushes at them, a dr will be placed and on activate the boss will tween to the position
	RABID, 
		#Rabid, Moves around the arena randomly and rapidly, randomly leaves large drs in it's wake
	ROAM, 
		#Roam, Moves around the arena randomly
		#if attacked it will spawn a dr on the attacker
	TELEPORT, #Teleport, Disappears for a period of time and reappears somewhere else
	RUN, #Run, Moves away from all players and puppets in a certain radius
	
	#SPECIAL
	PUSH, #Push, Pushes players away for x seconds
	PULL, 
		#Pull, Pulls players inward for x seconds
		#Pulls with more strength if attacked
	
	#ATTACK
	CIRCLE, #Places multiple fast dr's down in a circle around it
	LINE, #Places multiple fast dr's down in a line, this can be set to be a line a player or puppet is on (breath orignates from boss)
	ONSALUGHT, #Choose a player or puppet and spawn dr's on them every 3 seconds for a while
	BIGONE, #Big One, Moves somewhere and then covers a large part of the arena in danager radi
}

#Conditions
enum c {
	LIGHT_ONLY,
	HEAVY_ONLY,
	INVULNERABLE,
	INFLICT,
	CLUTCH,
}
#Light ONLY, heavy damage will be rejected
#Heavy ONLY, light damage will be rejected
#Invulnerable, only status damage works
#Inflict, will inflict status set on attack
#Clutch, will deal more damage
