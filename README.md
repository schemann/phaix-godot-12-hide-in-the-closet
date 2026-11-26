# Hide in the Closet

Project files for tutorial 12 of the Godot 4 series by Phaix on YouTube (https://www.youtube.com/@Phaix).

Add closets and beds to hide in to a game like Roblox DOORS in Godot 4, with a camera that glides in and out, a Lodger that throws you out and a seeded closet scare.
A Hider node on the player, an Area3D hiding spot, a state machine with a Tween for the camera move, a hidden state that every hit respects, and a Peek that the run's seed decides.

Hiding is a node of its own, like Health in tutorial 11: a hiding spot is an Area3D that finds the player's Hider by its name and never needs to know the player script. A second Camera3D moves from the player's eyes to the gap of the closet with a Tween, and a state machine with four states (out, going in, hidden, coming out) knows when the camera is on its way. One check in hurt makes a hidden player safe from every hit, the hazards of tutorial 11 too. The Lodger is a Timer: stay hidden for six seconds and it pushes you out and hits for 30, after a red edge that warns you for two seconds. The Peek shows two eyes in the crack instead of letting you in, five percent of the tries, from a random number generator seeded per try, so the same seed and the same tries give the same scare.

## Steps

Every step of the video is its own folder in `steps/`, the exact state at the end of that
part. Open the project in Godot 4.7, then open `steps/<step>/main.tscn` and press F6 to run
that step. The project's main scene is the final step.

| Folder | Part of the video |
|---|---|
| `steps/step_00_start` | Starting point (the final state of tutorial 11) |
| `steps/step_01_a_closet` | Step 1 - A closet |
| `steps/step_02_the_camera_moves` | Step 2 - The camera moves |
| `steps/step_03_the_lodger` | Step 3 - The Lodger |
| `steps/step_04_the_peek` | Step 4 - The Peek |

## Controls

- W A S D or the arrow keys walk, and so does the left stick of a gamepad.
- The mouse or the right stick looks around.
- Space or the A button jumps.
- Esc gives the mouse back, and a left click captures it again.
- Hold Shift, or hold the left stick pressed in, to walk slowly.
- V or the left shoulder button shows your body from a second camera above the door, and V again gives the view back.
- Tab or the Back button shows and hides the map.
- R or the Y button starts the run again on the same seed.
- N or the right shoulder button starts a run on the next seed.
- T opens the seed box: type a seed and press Enter to start a run with it, or press Esc to close the box and change nothing. While the box is open, every other key you press goes into it.
- C or the X button copies the seed to the clipboard.
- F3 shows and hides the gizmos: the box of every planned room and its markers, drawn through the walls.
- F4 lifts the camera above the rooms to watch the generator, Enter plans the next room while you watch, and F4 again gives the view back.
- O or the Start button opens the settings. In them, the arrow keys, the d-pad or the left stick move between the rows, left and right change a volume, Enter, Space or the A button turns an effect on or off, and O, Start or Esc closes them.
- Near a closet or a bed, E hides you, and E again brings you back out.
- After a death, E gets you back up once per run, at the entrance of the room you died in.

## Tests

```sh
godot --headless --path . -s res://tests/run_tests.gd
```

## Support

Support the channel: https://ko-fi.com/phaix or https://github.com/sponsors/schemann

## License

Code and scenes: MIT (see LICENSE).
The figure and its animations: Animated Characters Protagonists by Kenney (www.kenney.nl), CC0, see character/License.txt.
The sounds (footsteps, doors, lock, key): RPG Audio by Kenney (www.kenney.nl, https://kenney.nl/assets/rpg-audio), CC0, see sounds/CREDITS.md.
