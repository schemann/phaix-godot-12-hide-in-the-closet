extends Camera3D
## What the camera adds to the walk, for the eye only: the view dips a little at every step (head bob),
## and it widens for a moment when a door bursts open (field of view kick).
## It moves this camera and nothing else. The body, its collider and the head that steers never see it.

const Feel := preload("feel.gd")
const Footsteps := preload("footsteps.gd")
const FEEL: Feel = preload("feel.tres")

@export var footsteps: Footsteps ## Where the step cycle comes from.
@export var head_bob := true ## Off: the camera stays exactly where the head is.
@export var fov_kick := true ## Off: the view keeps its field of view.

var _bob := 0.0 ## 0 standing, 1 walking, eased in between so the bob fades in and out.
var _kick: Tween
@onready var _rest_fov := fov ## The field of view without a kick: the scene's.

## A door bursts open: the view widens fast and eases back slowly. A tween runs on frame time, so it takes as long at any frame rate.
func kick() -> void:
	if not fov_kick:
		return
	if _kick != null:
		_kick.kill()
	_kick = create_tween()
	_kick.tween_property(self, "fov", _rest_fov + FEEL.kick_degrees, FEEL.kick_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_kick.tween_property(self, "fov", _rest_fov, FEEL.kick_back_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if not fov_kick and fov != _rest_fov: # turned off in the middle of a kick
		if _kick != null:
			_kick.kill()
		fov = _rest_fov
	if not head_bob:
		_bob = 0.0
		position = Vector3.ZERO
		return
	var target := 1.0 if footsteps.walking else 0.0
	_bob += (target - _bob) * (1.0 - exp(-FEEL.bob_smoothing * delta)) # the same fade at any frame rate
	var cycle := footsteps.distance / FEEL.stride # 0 as a foot comes down, 1 at the next one
	position = Vector3(0.0, -FEEL.bob_height * _bob * (1.0 + cos(TAU * cycle)) / 2.0, 0.0)
