extends RefCounted
## The player's settings, saved as JSON like the best times:
##   {"formatVersion": 1, "settings": {"masterVolume": 0.8, "sfxVolume": 1.0, "headBob": true, "fovKick": false}}
## Loading never fails: no file is the defaults, a value of the wrong kind is its default, and a file that cannot be
## read is kept as <name>.bad while the settings start from the defaults. A save writes back everything that was in the file.

const FORMAT_VERSION := 1
const DEFAULTS := {"masterVolume": 1.0, "sfxVolume": 1.0, "headBob": true, "fovKick": true}

var master_volume := 1.0 ## 0 silent to 1 full, for the bus Master.
var sfx_volume := 1.0 ## For the bus SFX: doors, the lock, the key, the footsteps.
var head_bob := true
var fov_kick := true

var _path: String
var _data := {} ## The whole file as loaded, so keys this version does not know survive a save.

func _init(path: String) -> void:
	_path = path
	_load()

func save() -> void:
	var values: Dictionary = _data.get_or_add("settings", {})
	values["masterVolume"] = master_volume
	values["sfxVolume"] = sfx_volume
	values["headBob"] = head_bob
	values["fovKick"] = fov_kick
	_data["formatVersion"] = maxi(FORMAT_VERSION, int(_data.get("formatVersion", 0))) # never lower it
	_save()

func _load() -> void:
	if FileAccess.file_exists(_path):
		var json := JSON.new()
		var readable := json.parse(FileAccess.get_file_as_string(_path)) == OK
		if readable and json.data is Dictionary and (json.data as Dictionary).get("settings", {}) is Dictionary:
			_data = json.data
		else:
			# Never delete what cannot be read: keep it to look at later and start from the defaults.
			push_warning("settings: %s cannot be read, kept as %s.bad" % [_path, _path])
			DirAccess.rename_absolute(_path, _path + ".bad")
	var values: Dictionary = _data.get("settings", {})
	master_volume = _volume(values, "masterVolume")
	sfx_volume = _volume(values, "sfxVolume")
	head_bob = _switch(values, "headBob")
	fov_kick = _switch(values, "fovKick")

## A number from 0 to 1, or the default.
func _volume(values: Dictionary, key: String) -> float:
	var value: Variant = values.get(key, DEFAULTS[key])
	return clampf(float(value), 0.0, 1.0) if value is float or value is int else DEFAULTS[key]

## true or false, or the default.
func _switch(values: Dictionary, key: String) -> bool:
	var value: Variant = values.get(key, DEFAULTS[key])
	return value if value is bool else DEFAULTS[key]

## Writes next to the file first, then renames: a crash in between leaves the old file whole.
func _save() -> void:
	var temp_path := _path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("settings: cannot write %s (error %d)" % [temp_path, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.flush()
	file.close()
	if DirAccess.rename_absolute(temp_path, _path) != OK:
		push_warning("settings: cannot replace %s" % _path)
