extends CharacterBody2D

@onready var A_E = $Attack/A_E
@onready var A_D = $Attack/A_D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var canIdle = true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("M1"):
		$Image.play("Attack")
		canIdle = false
		await $Image.animation_finished
		canIdle = true
		if $Image.flip_h == false:
			A_D.disabled = false
		else:
			A_E.disabled = false
		$Image.play("Idle")
		A_D.disabled = true
		A_E.disabled = true
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("W") and is_on_floor() or Input.is_action_just_pressed("Space") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("A", "D")
	if direction:
		$Image.play("Walk")
		velocity.x = direction * SPEED
		if direction < 0:
			$Image.flip_h = true
		else:
			$Image.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if canIdle:
			$Image.play("Idle")

	move_and_slide()
	
