extends CharacterBody2D

signal interact_requested(target: Node2D)
signal respawned

const FX = preload("res://Script/fx.gd")

const SPEED: float = 260.0
const GROUND_ACCELERATION: float = 2600.0
const GROUND_FRICTION: float = 3000.0
const AIR_ACCELERATION: float = 1700.0
const AIR_FRICTION: float = 650.0
const JUMP_VELOCITY: float = -520.0
const JUMP_RELEASE_FACTOR: float = 0.5
const FALL_GRAVITY_SCALE: float = 1.35
const MAX_FALL_SPEED: float = 820.0
const COYOTE_TIME: float = 0.1
const JUMP_BUFFER_TIME: float = 0.12
const FEET_OFFSET: float = 28.0
const FALL_LIMIT: float = 900.0
const SHAKE_DECAY: float = 40.0

@onready var sprite: AnimatedSprite2D = $Image
@onready var camera: Camera2D = $Camera
@onready var attack_area: Area2D = $Attack
@onready var attack_left: CollisionShape2D = $Attack/A_E
@onready var attack_right: CollisionShape2D = $Attack/A_D
@onready var interaction_area: Area2D = $InteractionArea

var controls_locked: bool = false
var attacking: bool = false
var invulnerability_time: float = 0.0
var interaction_cooldown: float = 0.0
var attack_targets: Array[Node] = []
var nearby_npcs: Array[Node2D] = []

var _last_safe_position: Vector2 = Vector2(120, 530)
var _coyote_time: float = 0.0
var _jump_buffer: float = 0.0
var _knockback_time: float = 0.0
var _hurt_tint: float = 0.0
var _dust_timer: float = 0.0
var _was_on_floor: bool = true
var _shake: float = 0.0
var _squash_tween: Tween

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 5
	attack_area.body_entered.connect(_on_attack_body_entered)
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	sprite.play("Idle")
	_last_safe_position = global_position

func _process(delta: float) -> void:
	sprite.position.y = FEET_OFFSET * (1.0 - sprite.scale.y)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - SHAKE_DECAY * delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote_time = COYOTE_TIME
		_last_safe_position = global_position
	else:
		_coyote_time = maxf(0.0, _coyote_time - delta)
		var gravity_scale: float = FALL_GRAVITY_SCALE if velocity.y > 0.0 else 1.0
		velocity += get_gravity() * gravity_scale * delta
		velocity.y = minf(velocity.y, MAX_FALL_SPEED)

	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	interaction_cooldown = maxf(0.0, interaction_cooldown - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_knockback_time = maxf(0.0, _knockback_time - delta)
	_hurt_tint = maxf(0.0, _hurt_tint - delta)
	_update_blink()

	var direction: float = 0.0
	if not controls_locked:
		direction = Input.get_axis("A", "D")
		if Input.is_action_just_pressed("F") and interaction_cooldown <= 0.0:
			_try_interact()
			interaction_cooldown = 0.2
		if Input.is_action_just_pressed("M1") and not attacking:
			_start_attack()
		if Input.is_action_just_pressed("W") or Input.is_action_just_pressed("Space"):
			_jump_buffer = JUMP_BUFFER_TIME
		if (Input.is_action_just_released("W") or Input.is_action_just_released("Space")) and velocity.y < 0.0:
			velocity.y *= JUMP_RELEASE_FACTOR
		if Input.is_action_pressed("S") and not on_floor:
			velocity.y = maxf(velocity.y, 300.0)

	if _jump_buffer > 0.0 and _coyote_time > 0.0 and not controls_locked:
		_jump()

	if _knockback_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	elif controls_locked:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
	elif direction != 0.0:
		var acceleration: float = GROUND_ACCELERATION if on_floor else AIR_ACCELERATION
		if signf(velocity.x) == -direction:
			acceleration *= 1.6
		velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, (GROUND_FRICTION if on_floor else AIR_FRICTION) * delta)

	_update_animation(on_floor)
	_update_run_dust(on_floor, delta)

	var fall_speed: float = velocity.y
	move_and_slide()

	var landed: bool = is_on_floor() and not _was_on_floor
	if landed:
		_on_landed(fall_speed)
	_was_on_floor = is_on_floor()

	if global_position.y > FALL_LIMIT:
		_respawn()

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	_jump_buffer = 0.0
	_coyote_time = 0.0
	_squash(0.78, 1.28, 0.22)
	FX.dust(get_parent(), _feet(), 0.0, 6)

func _on_landed(fall_speed: float) -> void:
	var impact: float = clampf(fall_speed / 650.0, 0.0, 1.0)
	if impact < 0.18:
		return
	_squash(1.0 + 0.3 * impact, 1.0 - 0.24 * impact, 0.25)
	FX.dust(get_parent(), _feet(), -1.0, 3 + int(impact * 4.0))
	FX.dust(get_parent(), _feet(), 1.0, 3 + int(impact * 4.0))
	if impact > 0.7:
		shake(1.8)

func _update_animation(on_floor: bool) -> void:
	if attacking:
		return
	if not on_floor:
		if sprite.animation != &"Jump":
			sprite.play(&"Jump")
		var jump_frame: int = 2
		if velocity.y < -220.0:
			jump_frame = 0
		elif velocity.y < -40.0:
			jump_frame = 1
		elif velocity.y > 120.0:
			jump_frame = 3
		sprite.pause()
		sprite.frame = jump_frame
		return
	if absf(velocity.x) > 25.0:
		if sprite.animation != &"Walk" or not sprite.is_playing():
			sprite.play(&"Walk")
		sprite.speed_scale = clampf(absf(velocity.x) / SPEED, 0.6, 1.2)
	else:
		sprite.speed_scale = 1.0
		if sprite.animation != &"Idle" or not sprite.is_playing():
			sprite.play(&"Idle")

func _update_run_dust(on_floor: bool, delta: float) -> void:
	if not on_floor or absf(velocity.x) < 150.0:
		_dust_timer = 0.0
		return
	_dust_timer -= delta
	if _dust_timer <= 0.0:
		_dust_timer = 0.17
		FX.dust(get_parent(), _feet(), -signf(velocity.x), 2)

func _update_blink() -> void:
	if _hurt_tint > 0.0:
		sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif invulnerability_time > 0.0:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.45 if int(invulnerability_time * 18.0) % 2 == 0 else 1.0)
	else:
		sprite.modulate = Color.WHITE

func _feet() -> Vector2:
	return global_position + Vector2(0.0, FEET_OFFSET)

func _squash(stretch_x: float, stretch_y: float, duration: float) -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	sprite.scale = Vector2(stretch_x, stretch_y)
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

func set_controls_locked(value: bool) -> void:
	controls_locked = value
	if not value:
		interaction_cooldown = 0.2
	else:
		_jump_buffer = 0.0
		if not attacking:
			sprite.play("Idle")

func _start_attack() -> void:
	attacking = true
	attack_targets.clear()
	sprite.speed_scale = 1.0
	sprite.play("Attack")
	var facing: float = -1.0 if sprite.flip_h else 1.0
	if _knockback_time <= 0.0:
		velocity.x = clampf(velocity.x + facing * 150.0, -SPEED * 1.15, SPEED * 1.15)
	FX.slash(get_parent(), global_position + Vector2(facing * 34.0, 2.0), facing)
	if sprite.flip_h:
		attack_left.set_deferred("disabled", false)
	else:
		attack_right.set_deferred("disabled", false)
	await get_tree().create_timer(0.24).timeout
	attack_left.set_deferred("disabled", true)
	attack_right.set_deferred("disabled", true)
	if sprite.is_playing():
		await sprite.animation_finished
	attacking = false
	if not controls_locked:
		if is_on_floor():
			sprite.play("Idle")
		else:
			sprite.play("Jump")

func _on_attack_body_entered(body: Node2D) -> void:
	if not attacking or attack_targets.has(body):
		return
	if body.is_in_group("enemies") and body.has_method("take_hit"):
		attack_targets.append(body)
		body.call("take_hit", GameState.get_attack_damage(), global_position.x)
		shake(2.4)
		FX.hit_stop(get_tree(), 0.045)

func _on_interaction_body_entered(body: Node2D) -> void:
	if body.is_in_group("NPC") and not nearby_npcs.has(body):
		nearby_npcs.append(body)

func _on_interaction_body_exited(body: Node2D) -> void:
	nearby_npcs.erase(body)

func _try_interact() -> void:
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for candidate in nearby_npcs:
		if not is_instance_valid(candidate):
			continue
		var distance: float = global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if nearest:
		interact_requested.emit(nearest)

func take_damage(amount: int, from_x: float = NAN) -> void:
	if invulnerability_time > 0.0:
		return
	GameState.damage(amount)
	invulnerability_time = 1.0
	_hurt_tint = 0.18
	var facing: float = -1.0 if sprite.flip_h else 1.0
	if is_nan(from_x):
		velocity = Vector2(-facing * 140.0, -380.0)
	else:
		var push: float = signf(global_position.x - from_x)
		if push == 0.0:
			push = -facing
		velocity = Vector2(push * 270.0, -300.0)
	_knockback_time = 0.2
	_squash(1.25, 0.8, 0.25)
	shake(5.0)
	FX.burst(get_parent(), global_position, Color("#e0584c"), 10, 190.0, 0.45, 3.0, 620.0)
	FX.hit_stop(get_tree(), 0.06)
	if GameState.health <= 0:
		_respawn()

func _respawn() -> void:
	FX.burst(get_parent(), global_position, Color("#e0584c"), 14, 220.0, 0.5, 3.0, 620.0)
	GameState.restore_health()
	var destination: Vector2 = GameState.get_spawn_position(_last_safe_position)
	global_position = destination
	velocity = Vector2.ZERO
	invulnerability_time = 1.2
	_knockback_time = 0.0
	_hurt_tint = 0.0
	_coyote_time = 0.0
	camera.reset_smoothing()
	FX.burst(get_parent(), global_position, Color("#f6ce78"), 12, 160.0, 0.5, 3.0, 200.0)
	respawned.emit()
