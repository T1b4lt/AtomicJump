class_name Protagonist
extends CharacterBody2D


# Parameters
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")

# Childs
@onready var body_sprite: Sprite2D = $body
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hp_bar: ProgressBar = $hp_bar
@onready var hp_data: Label = $hp_bar/hp_data

# Variables
var consecutive_jump_count = 0


func _ready():
	# Set initial values for hp_bar and hp_text from game.gd
	hp_bar.max_value = game.pr_max_hp
	hp_bar.value = game.pr_hp
	hp_data.text = str(game.pr_hp) + "/" + str(game.pr_max_hp)

func _process(_delta):
	# Update Health bar and text with game.gd values
	hp_bar.max_value = game.pr_max_hp
	hp_bar.value = game.pr_hp
	hp_data.text = str(game.pr_hp) + "/" + str(game.pr_max_hp)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and consecutive_jump_count < game.pr_max_jumps - 1:
		velocity.y = game.pr_jump_velocity
		consecutive_jump_count += 1
		game.jump_counter += 1
		
	# Reset jump count when on floor
	if is_on_floor():
		consecutive_jump_count = 0

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * game.pr_walk_velocity
		# Flip the sprite based on movement direction
		if direction < 0:
			body_sprite.scale.x = -1
		else:
			body_sprite.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, game.pr_walk_velocity)

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

func play_animation(animation_name: String):
	# If animation is not being played, play it
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
