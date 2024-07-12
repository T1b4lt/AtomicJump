extends CharacterBody2D


@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var MAX_JUMPS = 2  # Allow double jump

@onready var body_sprite = $cuerpo
@onready var animation_player = $AnimationPlayer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variable to keep track of the number of jumps
var jump_count = 0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("saltar") and jump_count < MAX_JUMPS - 1:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		
	# Reset jump count when on floor
	if is_on_floor():
		jump_count = 0

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("izquierda", "derecha")
	if direction:
		velocity.x = direction * SPEED
		# Flip the sprite based on movement direction
		if direction < 0:
			body_sprite.scale.x = -1
		else:
			body_sprite.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Move the character and get the motion result
	var motion_result = move_and_slide()

	# Handle animations based on the state
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("salto")
		else:
			play_animation("caida")
	else:
		if direction != 0:
			play_animation("caminar")
		else:
			play_animation("reposo")

func play_animation(name: String):
	if animation_player.current_animation != name:
		animation_player.play(name)
