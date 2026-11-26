extends SceneTree
## Walks the autopilot through the finished game (step 4) for a range of seeds and writes one line per seed to a file:
##   ok <seed> <ticks> <doors> <hits>                      the player stood on the goal pad, after going through that many doors and taking that many hits
##   held <seed> <room> <ticks> <hits> <local position>    the player stopped moving, or the run took too long
##   died <seed> <room> <ticks> <hits> <cause>             the player's health reached 0: the run stops there
## and, before that seed's line, one line for every hit and for every door whose number was wrong:
##   hit <seed> <room the player was in> <health after the hit>
##   numbers <seed> <room> <what the door said and what it should have said>
## and "done" as the last line. The test suite starts several of these side by side (tests/run_tests.gd, test_autopilot_seed_sweep).
##   godot --headless --path godot/12-hide-in-the-closet -s res://tools/sweep_seeds.gd -- --from=1 --to=50 --out=/tmp/sweep.txt
## The ticks are the same 1/60 s ones at any speed, so a seed walks the same way fast or slow. The speed is the engine's own
## limit of 8 physics steps per frame: faster than that Jolt warns about running out of jobs.
## The autopilot has no eyes: it never steers around a hazard. The contents check (steps/step_NN/check_contents.gd) keeps every prop,
## the hazards included, off the way through a room and off the way to its key, which is why a run is expected to take no hit.

const Autopilot := preload("res://tools/autopilot.gd")
const FINAL_SCENE := "res://steps/step_04_the_peek/main.tscn"
const SPEED_UP := 8 ## Times real time.
const STATE_FINISHED := 2 ## Level.State.FINISHED
const STATE_DEAD := 3 ## Level.State.DEAD
const STALL_TICKS := 120 ## A run that has not moved for this many ticks (2 s) is held in place.
const STALL_DISTANCE := 0.0005 ## Metres a tick has to move the player to count as moving.
const BUDGET := 60 * 60 * 3 ## Ticks a run may take (3 minutes of game time; a run takes about one).

## Calls its callback once per physics tick, before the player's own tick.
class Driver extends Node:
	signal finished
	var tick: Callable

	func _physics_process(_delta: float) -> void:
		if tick.is_valid() and tick.call():
			tick = Callable()
			finished.emit()

func _initialize() -> void:
	await process_frame
	var first := 1
	var last := 1
	var out_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--from="):
			first = int(argument.trim_prefix("--from="))
		elif argument.begins_with("--to="):
			last = int(argument.trim_prefix("--to="))
		elif argument.begins_with("--out="):
			out_path = argument.trim_prefix("--out=")
	var out := FileAccess.open(out_path, FileAccess.WRITE)
	if out == null:
		printerr("sweep_seeds: cannot write ", out_path)
		quit(1)
		return
	Engine.physics_ticks_per_second = 60 * SPEED_UP
	Engine.time_scale = float(SPEED_UP)
	for chain_seed in range(first, last + 1):
		for line: String in await _walk(chain_seed):
			out.store_line(line)
		out.flush()
	out.store_line("done")
	out.close()
	# The audio server lets go of the last sounds in its own thread, on the clock: wait a little real time, or the engine
	# reports them as leaked at exit (Godot issue 76745).
	OS.delay_msec(250)
	await process_frame
	quit(0)

## The number on the door of a room, "" for a room without a door (the goal room). Every door says four digits: "0005".
func _number_on(room: Node3D) -> String:
	var door := room.get("door") as Node3D
	return (door.get_node("Hinge/Number") as Label3D).text if door != null else ""

## One seed from the first door to the goal pad. Returns the lines for the result file.
func _walk(chain_seed: int) -> Array[String]:
	var save_path := OS.get_temp_dir().path_join("phaix-godot-12-sweep-%d-%d.json" % [OS.get_process_id(), chain_seed]) # one file per worker: two sweeps at the same time must not share a save file
	var main := (load(FINAL_SCENE) as PackedScene).instantiate()
	var level: Node3D = main.get_node("Level")
	level.set("save_path", save_path)
	main.get_node("HUD/Settings").set("save_path", save_path.trim_suffix(".json") + "-settings.json") # never the player's own settings
	level.set("seed_text", str(chain_seed)) # a number is the text of its digits: the same seed as in the earlier tutorials
	root.add_child(main)
	for i in 10:
		await physics_frame # the CSG shapes build their collision
	var pilot := Autopilot.new(level)
	var run := {"ticks": 0, "still": 0, "last": level.player.global_position, "doors": 0, "hits": 0, "health": level.health.health, "numbers": [] as Array[String], "hit_lines": [] as Array[String]}
	var room_label := main.get_node("HUD/Stats/RoomLabel") as Label
	# Every point the health loses is a hit; a reset (a new run) raises it and is not.
	level.health.changed.connect(func(health: int) -> void:
		if health < run["health"]:
			run["hits"] += 1
			(run["hit_lines"] as Array[String]).append("hit %d %d %d" % [chain_seed, level.current, health])
		run["health"] = health)
	# The number on the door the player has just gone through is the number the HUD shows now.
	level.room_entered.connect(func(index: int) -> void:
		if index == 0:
			return
		var said := _number_on(level.rooms[index - 1])
		run["doors"] += 1
		if said != "%04d" % index or room_label.text != "Room %d / %d" % [index, level.chain.goal_index]:
			(run["numbers"] as Array[String]).append("numbers %d %d the door said \"%s\", the HUD says \"%s\"" % [chain_seed, index - 1, said, room_label.text]))
	var driver := Driver.new()
	driver.process_priority = -100
	driver.tick = func() -> bool:
		pilot.physics_step()
		run["ticks"] += 1
		var at: Vector3 = level.player.global_position
		for index: int in level.rooms: # every door that exists says its plan's number, whatever was freed or built before
			var said := _number_on(level.rooms[index])
			if level.rooms[index].door != null and said != "%04d" % (level.chain.plans[index].index + 1) and (run["numbers"] as Array[String]).size() < 3:
				(run["numbers"] as Array[String]).append("numbers %d %d the door says \"%s\", the plan says %04d" % [chain_seed, index, said, level.chain.plans[index].index + 1])
		run["still"] = run["still"] + 1 if at.distance_to(run["last"]) < STALL_DISTANCE else 0
		run["last"] = at
		return level.state == STATE_FINISHED or level.state == STATE_DEAD or run["still"] >= STALL_TICKS or run["ticks"] >= BUDGET
	root.add_child(driver)
	await driver.finished
	pilot.release()
	var lines: Array[String] = []
	lines.append_array(run["hit_lines"])
	lines.append_array(run["numbers"])
	var line := "ok %d %d %d %d" % [chain_seed, run["ticks"], run["doors"], run["hits"]]
	if level.state == STATE_DEAD:
		line = "died %d %d %d %d %s" % [chain_seed, level.current, run["ticks"], run["hits"], level.death_cause]
	elif level.state != STATE_FINISHED:
		var room: Node3D = level.rooms[level.current]
		var local: Vector3 = room.global_transform.affine_inverse() * level.player.global_position
		line = "held %d %d %d %d %s" % [chain_seed, level.current, run["ticks"], run["hits"], local]
	root.remove_child(driver)
	driver.queue_free()
	root.remove_child(main)
	main.free()
	for path: String in [save_path, save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	await process_frame
	lines.append(line)
	return lines
