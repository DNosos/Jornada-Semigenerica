extends CharacterBody2D

signal interact_requested(target: Node2D)
signal respawned

const SPEED: float = 260.0
const JUMP_VELOCITY: float = -520.0
const FALL_LIMIT: float = 900.0

@onready var sprite: AnimatedSprite2D = $Image
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

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask = 5
	attack_area.body_entered.connect(_on_attack_body_entered)
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	sprite.play("Idle")
	_last_safe_position = global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		_last_safe_position = global_position

	invulnerability_time = maxf(0.0, invulnerability_time - delta)
	interaction_cooldown = maxf(0.0, interaction_cooldown - delta)
	if invulnerability_time <= 0.0:
		sprite.modulate = Color.WHITE

	if controls_locked:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
	else:
		if Input.is_action_just_pressed("F") and interaction_cooldown <= 0.0:
			_try_interact()
			interaction_cooldown = 0.2
		if Input.is_action_just_pressed("M1") and not attacking:
			_start_attack()
		if (Input.is_action_just_pressed("W") or Input.is_action_just_pressed("Space")) and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if Input.is_action_pressed("S") and not is_on_floor():
			velocity.y = maxf(velocity.y, 300.0)

		var direction := Input.get_axis("A", "D")
		if direction != 0.0:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0.0
			if not attacking and is_on_floor():
				sprite.play("Walk")
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
			if not attacking and is_on_floor():
				sprite.play("Idle")

	if not is_on_floor() and not attacking:
		sprite.play("Jump")
	move_and_slide()

	if global_position.y > FALL_LIMIT:
		_respawn()

func set_controls_locked(value: bool) -> void:
	controls_locked = value
	if not value:
		# Evita que a mesma tecla F que fechou o diálogo abra outro imediatamente.
		interaction_cooldown = 0.2
	if value:
		velocity.x = 0.0
		if not attacking:
			sprite.play("Idle")

func _start_attack() -> void:
	attacking = true
	attack_targets.clear()
	sprite.play("Attack")
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
		body.call("take_hit", GameState.get_attack_damage())

func _on_interaction_body_entered(body: Node2D) -> void:
	if body.is_in_group("NPC") and not nearby_npcs.has(body):
		nearby_npcs.append(body)

func _on_interaction_body_exited(body: Node2D) -> void:
	nearby_npcs.erase(body)

func _try_interact() -> void:
	var nearest: Node2D = null
	var nearest_distance := INF
	for candidate in nearby_npcs:
		if not is_instance_valid(candidate):
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if nearest:
		interact_requested.emit(nearest)

func take_damage(amount: int) -> void:
	if invulnerability_time > 0.0:
		return
	GameState.damage(amount)
	invulnerability_time = 1.0
	sprite.modulate = Color(1.0, 0.45, 0.45)
	if GameState.health <= 0:
		_respawn()

func _respawn() -> void:
	GameState.restore_health()
	var destination := GameState.get_spawn_position(_last_safe_position)
	global_position = destination
	velocity = Vector2.ZERO
	invulnerability_time = 1.2
	respawned.emit()
