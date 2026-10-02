class_name Protagonist
extends CharacterBody2D

# Parameters
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variables
var air_jumps_used: int = 0  # Jumps done in the air since last touching the floor

# Childs
@onready var body_sprite: Sprite2D = $body
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hp_bar: ProgressBar = $hp_bar
@onready var hp_data: Label = $hp_bar/hp_data


func _ready() -> void:
	# Set initial scale from game.gd
	scale = Vector2(game.pr_size, game.pr_size)

	# Set initial values for hp_bar and hp_text from game.gd
	hp_bar.max_value = game.pr_max_hp
	hp_bar.value = game.pr_hp
	hp_data.text = "%.2f" % game.pr_hp + "/" + str(game.pr_max_hp)


func _process(_delta: float) -> void:
	# Update Health bar and text with game.gd values
	hp_bar.max_value = game.pr_max_hp
	hp_bar.value = game.pr_hp
	hp_data.text = "%.2f" % game.pr_hp + "/" + str(game.pr_max_hp)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump. is_on_floor() still holds the state of the last move_and_slide(),
	# so the air jump count is reset before (never after) jumping in this frame.
	var on_floor: bool = is_on_floor()
	if on_floor:
		air_jumps_used = 0
	if Input.is_action_just_pressed("jump") and try_jump(on_floor):
		velocity.y = game.pr_jump_force
		game.jump_counter += 1

	# Get the input direction and handle the movement/deceleration.
	var direction: float = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * game.pr_speed
		# Flip the sprite based on movement direction
		if direction < 0:
			body_sprite.scale.x = -1
		else:
			body_sprite.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, game.pr_speed)

	# Move the character
	move_and_slide()

	# Handle animations based on the state
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("fall")
	else:
		if direction != 0:
			play_animation("walk")
		else:
			play_animation("idle")


## Number of jumps allowed in the air: pr_max_jumps counts the ground jump too
## (2 = double jump). Walking off a ledge keeps all of them.
static func max_air_jumps(max_jumps: int) -> int:
	return maxi(max_jumps - 1, 0)


## Applies the jump rules for a jump press and returns whether Wilas jumps.
## A ground jump is always allowed and does not consume air jumps.
func try_jump(on_floor: bool) -> bool:
	if on_floor:
		return true
	if air_jumps_used < max_air_jumps(game.pr_max_jumps):
		air_jumps_used += 1
		return true
	return false


func play_animation(animation_name: String) -> void:
	# If animation is not being played, play it
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
