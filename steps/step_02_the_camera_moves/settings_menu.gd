extends PanelContainer
## The settings (O, or Start on a gamepad): the volume of each bus, and the two camera effects on or off.
## A change counts at once, so the player hears and sees it; closing the box saves the file. While it is up the level
## waits like for the seed box (Level._on_seed_entry_opened). The arrow keys or the stick move between the rows,
## left and right change a volume, Enter or the A button turns an effect on or off.

const Level := preload("level.gd")
const CameraFeel := preload("camera_feel.gd")
const Settings := preload("settings.gd")

signal opened ## The box is up.
signal closed ## The box is gone again; the settings are saved.

@export var level: Level
@export var save_path := "user://settings.json" ## Tests and recordings point it at a temporary file.

var settings: Settings
var _volumes_before: Array[float] = [] ## The volume of each bus before this scene changed it.
var _mutes_before: Array[bool] = []

@onready var master_slider: HSlider = $Rows/Master/Slider
@onready var sfx_slider: HSlider = $Rows/Sfx/Slider
@onready var head_bob_check: CheckButton = $Rows/HeadBob
@onready var fov_kick_check: CheckButton = $Rows/FovKick

func _ready() -> void:
	for bus in AudioServer.bus_count:
		_volumes_before.append(AudioServer.get_bus_volume_linear(bus))
		_mutes_before.append(AudioServer.is_bus_mute(bus))
	settings = Settings.new(save_path)
	master_slider.value = settings.master_volume
	sfx_slider.value = settings.sfx_volume
	head_bob_check.button_pressed = settings.head_bob
	fov_kick_check.button_pressed = settings.fov_kick
	for control: Range in [master_slider, sfx_slider]:
		control.value_changed.connect(_on_changed.unbind(1))
	for control: BaseButton in [head_bob_check, fov_kick_check]:
		control.toggled.connect(_on_changed.unbind(1))
	apply()

## The audio server outlives the scene: give it back the volumes it had.
func _exit_tree() -> void:
	for bus in _volumes_before.size():
		AudioServer.set_bus_volume_linear(bus, _volumes_before[bus])
		AudioServer.set_bus_mute(bus, _mutes_before[bus])

## While the box is up no other key reaches the game: it is the last node of the HUD, so it hears them first.
func _unhandled_input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_settings"):
		open()
		get_viewport().set_input_as_handled()

## O again or Esc closes the box. It sees the keys before the sliders do.
func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("open_settings") or event.is_action_pressed("ui_cancel")):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	show()
	master_slider.grab_focus()
	opened.emit()

func close() -> void:
	hide()
	get_viewport().gui_release_focus()
	settings.save()
	closed.emit()

func _on_changed() -> void:
	settings.master_volume = master_slider.value
	settings.sfx_volume = sfx_slider.value
	settings.head_bob = head_bob_check.button_pressed
	settings.fov_kick = fov_kick_check.button_pressed
	apply()

## Puts the settings to work: each volume on its bus (0 is muted), each effect on the player's camera.
func apply() -> void:
	_set_volume("Master", settings.master_volume)
	_set_volume("SFX", settings.sfx_volume)
	var camera := level.player.get_node("Head/Camera3D") as CameraFeel
	camera.head_bob = settings.head_bob
	camera.fov_kick = settings.fov_kick

func _set_volume(bus_name: String, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus, volume)
	AudioServer.set_bus_mute(bus, volume <= 0.0)
