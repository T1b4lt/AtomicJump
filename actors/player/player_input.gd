class_name PlayerInput
extends RefCounted
## Snapshot of the player's controls for one physics frame. The player reads it
## from the input actions; tests and debug tools build it by hand.

## -1 (left) to 1 (right).
var move_axis: float = 0.0
var down_held: bool = false
var jump_pressed: bool = false
var jump_held: bool = false
var dash_pressed: bool = false


## Reads the input actions (docs/04-player.md#controles).
static func from_actions() -> PlayerInput:
	var input := PlayerInput.new()
	input.move_axis = Input.get_axis(&"move_left", &"move_right")
	input.down_held = Input.is_action_pressed(&"move_down")
	input.jump_pressed = Input.is_action_just_pressed(&"jump")
	input.jump_held = Input.is_action_pressed(&"jump")
	input.dash_pressed = Input.is_action_just_pressed(&"dash")
	return input


static func create(
	p_move_axis: float = 0.0,
	p_jump_pressed: bool = false,
	p_jump_held: bool = false,
	p_down_held: bool = false,
	p_dash_pressed: bool = false
) -> PlayerInput:
	var input := PlayerInput.new()
	input.move_axis = p_move_axis
	input.jump_pressed = p_jump_pressed
	input.jump_held = p_jump_held or p_jump_pressed
	input.down_held = p_down_held
	input.dash_pressed = p_dash_pressed
	return input
