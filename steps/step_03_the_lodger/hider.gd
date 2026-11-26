extends Node

const HidingSpot := preload("hiding_spot.gd")
const Player := preload("player.gd")

enum State { OUT, GOING_IN, HIDDEN, COMING_OUT }

signal changed

const MOVE_TIME := 0.6
const PUSH_TIME := 0.25

var state := State.OUT
var near: Array[HidingSpot]
var current: HidingSpot
var hidden: bool:
	get:
		return state == State.GOING_IN or state == State.HIDDEN

var _move: Tween

@onready var player: Player = get_parent()
@onready var eyes: Camera3D = player.get_node("Head/Camera3D")
@onready var view: Camera3D = $View

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("hide"):
		return
	match state:
		State.OUT:
			var faced := _faced_spot()
			if faced != null and not player.frozen:
				go_in(faced)
		State.HIDDEN:
			come_out()

func came_near(spot: HidingSpot) -> void:
	if not near.has(spot):
		near.append(spot)
		changed.emit()

func went_away(spot: HidingSpot) -> void:
	if near.has(spot):
		near.erase(spot)
		changed.emit()

func _faced_spot() -> HidingSpot:
	var faced: HidingSpot
	var best := -2.0
	var forward := -eyes.global_basis.z
	for spot in near:
		var dot := forward.dot(eyes.global_position.direction_to(spot.view.global_position))
		if dot > best:
			best = dot
			faced = spot
	return faced

func go_in(spot: HidingSpot) -> void:
	current = spot
	view.global_transform = eyes.global_transform
	view.fov = eyes.fov
	view.make_current()
	_set_state(State.GOING_IN)
	_move_view(spot.view.global_transform, true)

func come_out() -> void:
	_set_state(State.COMING_OUT)
	_move_view(eyes.global_transform, false)

func push_out() -> void:
	if state == State.HIDDEN:
		come_out()
		_move.set_speed_scale(MOVE_TIME / PUSH_TIME)

func reset() -> void:
	if _move != null:
		_move.kill()
	if is_instance_valid(current):
		current.set_open(false)
	near.clear()
	_set_state(State.OUT)

func _move_view(target: Transform3D, open: bool) -> void:
	if _move != null:
		_move.kill()
	var yaw := view.global_rotation.y + angle_difference(view.global_rotation.y, target.basis.get_euler().y)
	_move = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	current.turn_doors(_move, open, MOVE_TIME)
	_move.tween_property(view, "global_position", target.origin, MOVE_TIME)
	_move.tween_property(view, "global_rotation:y", yaw, MOVE_TIME)
	_move.tween_property(view, "global_rotation:x", target.basis.get_euler().x, MOVE_TIME)
	_move.chain().tween_callback(_arrive)

func _arrive() -> void:
	_set_state(State.HIDDEN if state == State.GOING_IN else State.OUT)

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.OUT:
			player.hiding = false
			player.body.visible = true
			eyes.make_current()
		State.GOING_IN:
			player.hiding = true
			player.body.visible = false
	changed.emit()
