extends AudioStreamPlayer3D
## Footsteps by the distance walked, not by a timer: one step every stride along the floor.
## It sits at the player's feet and only listens. It reads where the player is and never moves it.

signal stepped ## A foot came down: once per step, the landing of a jump included.

const Feel := preload("feel.gd")
const FEEL: Feel = preload("feel.tres")
const TELEPORT := 1.0 ## Metres in one physics step that nobody walks: a restart moved the player.
const LANDING := 0.25 ## Seconds in the air that make the touchdown a step of its own.

var distance := 0.0 ## Metres walked on the floor since the last step.
var steps := 0 ## Steps since the scene started.
var walking := false ## The player moved along the floor in the last physics step.

var _last := Vector3.ZERO ## Where the player was in the last physics step.
var _air_time := 0.0 ## Seconds the player has been off the floor.

@onready var body: CharacterBody3D = get_parent()

func _ready() -> void:
	_last = body.global_position
	distance = FEEL.stride * (1.0 - FEEL.first_step)

## A child runs its physics step after its parent: the player has moved for this step.
func _physics_process(delta: float) -> void:
	var now := body.global_position
	var moved := Vector2(now.x - _last.x, now.z - _last.z).length() # along the floor: up and down is not a step
	_last = now
	walk(moved, body.is_on_floor(), delta)

## The rule: in `delta` seconds the player moved `moved` metres.
func walk(moved: float, on_floor: bool, delta: float) -> void:
	walking = on_floor and moved > 0.0 and moved < TELEPORT
	if moved >= TELEPORT: # a restart moved the player: no step
		distance = FEEL.stride * (1.0 - FEEL.first_step)
		_air_time = 0.0
		return
	if not on_floor:
		_air_time += delta
		return
	if _air_time >= LANDING: # landed: a step at once
		distance = 0.0
		_step()
	else:
		distance += moved
		if distance >= FEEL.stride:
			distance -= FEEL.stride
			_step()
	_air_time = 0.0

func _step() -> void:
	steps += 1
	play()
	stepped.emit()
