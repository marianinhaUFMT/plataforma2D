extends CharacterBody2D

@export var acceleration := 900.0      
@export var deceleration := 2000.0      
@export var max_speed := 300.0         
@export var jump_gravity := 800.0
@export var fall_gravity := 700.0
@export var air_acceleration := 400.0  
@export var jump_speed := 400.0         

# salvao posicao inicial do player
@onready var spawn_position : Vector2 = global_position

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction_x := 0.0
var current_gravity := 200.0

enum State {
	GROUND,
	JUMP,
	FALL,
	DEATH
}

var current_state: State = State.GROUND

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition_to_state(State.FALL)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	direction_x = signf(Input.get_axis("left", "right"))

	match current_state:
		State.GROUND:
			process_ground_state(delta)
		State.JUMP:
			process_jump_state(delta)
		State.FALL:
			process_fall_state(delta)
		State.DEATH:
			pass

	velocity.y += current_gravity * delta
	move_and_slide()

func process_ground_state(delta):
	var is_moving := absf(direction_x) > 0.0

	if is_moving:
		velocity.x += direction_x * acceleration * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0
		animated_sprite.play("Run")
	else:
		animated_sprite.play("Idle")
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

	if Input.is_action_just_pressed("up"):
		transition_to_state(State.JUMP)
	elif not is_on_floor():
		transition_to_state(State.FALL)

func process_jump_state(delta):
	var is_moving := absf(direction_x) > 0.0

	if is_moving:
		velocity.x = move_toward(velocity.x, max_speed * direction_x, air_acceleration * delta)
		animated_sprite.flip_h = direction_x < 0.0

	if velocity.y >= 0: # atingimos o pico
		print("começou a cair")
		transition_to_state(State.FALL)

func process_fall_state(delta):
	var is_moving := absf(direction_x) > 0.0

	if is_moving:
		velocity.x = move_toward(velocity.x, max_speed * direction_x, air_acceleration * delta)
		animated_sprite.flip_h = direction_x < 0.0

	if is_on_floor():
		print("atingiu o chao")
		transition_to_state(State.GROUND)

func transition_to_state(new_state: State):
	var previous_state = current_state
	current_state = new_state

	match previous_state:
		pass

	match current_state:
		State.JUMP:
			animated_sprite.play("Jump")
			velocity.y = -jump_speed
			current_gravity = jump_gravity
		State.FALL:
			animated_sprite.play("Fall")
			current_gravity = fall_gravity
		State.DEATH:
			print("morreu")
			animated_sprite.play("Hurt")
			set_physics_process(false) # congela 
			await get_tree().create_timer(0.5).timeout # await serve como uma espera assincrona
			# reposicionar o player (RESPAWN)
			global_position = spawn_position
			velocity = Vector2.ZERO
			transition_to_state(State.GROUND)
			set_physics_process(true)
			

func _on_kill_plane_body_entered(body: Node2D) -> void:
	transition_to_state(State.DEATH)
