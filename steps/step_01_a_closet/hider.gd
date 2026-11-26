extends Node

const HidingSpot := preload("hiding_spot.gd")
const Player := preload("player.gd")

signal changed

var hidden := false
var near: HidingSpot

@onready var player: Player = get_parent()
@onready var eyes: Camera3D = player.get_node("Head/Camera3D")
@onready var view: Camera3D = $View

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("hide"):
		return
	if hidden:
		come_out()
	elif is_instance_valid(near) and not player.frozen:
		go_in(near)

func came_near(spot: HidingSpot) -> void:
	near = spot
	changed.emit()

func went_away(spot: HidingSpot) -> void:
	if near == spot:
		near = null
		changed.emit()

func go_in(spot: HidingSpot) -> void:
	hidden = true
	player.hiding = true
	player.body.visible = false
	view.global_transform = spot.view.global_transform
	view.make_current()
	spot.set_open(true)
	changed.emit()

func come_out() -> void:
	hidden = false
	player.hiding = false
	player.body.visible = true
	if is_instance_valid(near):
		near.set_open(false)
	eyes.make_current()
	changed.emit()

func reset() -> void:
	come_out()
	near = null
