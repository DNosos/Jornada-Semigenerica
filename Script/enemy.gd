extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died(enemy: Node)

const VISUAL_SCRIPT = preload("res://Script/character_visual.gd")
const FX = preload("res://Script/fx.gd")
const ACCELERATION: float = 620.0
const EDGE_PROBE_DEPTH: float = 20.0

var max_health: int = 3
var health: int = 3
var move_speed: float = 55.0
var patrol_distance: float = 100.0
var chase_range: float = 250.0
var contact_damage: int = 1
var is_boss: bool = false
var target: CharacterBody2D
var visual
var half_width: float = 12.0
var body_height: float = 30.0

var _origin_x: float = 0.0
var _direction: float = 1.0
var _chasing: bool = false
var _contact_cooldown: float = 0.0
var _hurt_flash: float = 0.0
var _stun_time: float = 0.0
var _turn_pause: float = 0.0
var _dead: bool = false
var _collision: CollisionShape2D
var _gravity: float = 980.0

func configure(texture_path: String, hp: int, speed: float, patrol: float, size_scale: float = 0.75, boss: bool = false, style: String = "bob") -> void:
	max_health = hp
	health = hp
	move_speed = speed
	patrol_distance = patrol
	is_boss = boss
	contact_damage = 2 if boss else 1
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

	visual = VISUAL_SCRIPT.new()
	add_child(visual)
	visual.setup(FX.load_texture(texture_path), style, size_scale, 3.0)
	half_width = maxf(float(visual.body_width) * 0.275, 8.0)
	body_height = maxf(float(visual.feet_height) * 0.9, 16.0)

	_collision = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(half_width * 2.0, body_height)
	_collision.shape = shape
	_collision.position = Vector2(0.0, -body_height * 0.5)
	add_child(_collision)

func set_target(player: CharacterBody2D) -> void:
	target = player
	_origin_x = global_position.x

func _physics_process(delta: float) -> void:
	# A morte encerra imediatamente a lógica física e o contato do inimigo.
	if _dead or health <= 0:
		return
	if not is_on_floor():
		velocity.y += _gravity * delta

	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	_stun_time = maxf(0.0, _stun_time - delta)
	_turn_pause = maxf(0.0, _turn_pause - delta)
	_update_tint()

	if _stun_time > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if velocity.x != 0.0 and _edge_ahead(signf(velocity.x)):
			velocity.x = 0.0
		move_and_slide()
		_check_contact()
		return

	var direction: float = _choose_direction()
	if direction != 0.0 and is_on_floor() and (_edge_ahead(direction) or _wall_ahead(direction)):
		if not _chasing:
			_direction = -direction
			_turn_pause = 0.35
		direction = 0.0
	if _turn_pause > 0.0:
		direction = 0.0

	velocity.x = move_toward(velocity.x, direction * move_speed, ACCELERATION * delta)

	if absf(velocity.x) > 4.0:
		visual.face(signf(velocity.x))
	elif _chasing and is_instance_valid(target):
		visual.face(signf(target.global_position.x - global_position.x))
	visual.sprite.speed_scale = 0.35 if absf(velocity.x) < 4.0 else (1.5 if _chasing else 1.0)

	move_and_slide()
	_check_contact()

func _choose_direction() -> float:
	_chasing = false
	if is_instance_valid(target):
		var distance_x: float = target.global_position.x - global_position.x
		var distance_y: float = absf(target.global_position.y - global_position.y)
		if absf(distance_x) < chase_range and distance_y < 180.0:
			_chasing = true
			if absf(distance_x) < 6.0:
				return 0.0
			return signf(distance_x)
	if global_position.x > _origin_x + patrol_distance:
		_direction = -1.0
	elif global_position.x < _origin_x - patrol_distance:
		_direction = 1.0
	return _direction

func _edge_ahead(direction: float) -> bool:
	var probe_x: float = global_position.x + direction * (half_width + 4.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		Vector2(probe_x, global_position.y - 6.0),
		Vector2(probe_x, global_position.y + EDGE_PROBE_DEPTH),
		1
	)
	if is_instance_valid(target):
		query.exclude = [target.get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _wall_ahead(direction: float) -> bool:
	return test_move(global_transform, Vector2(direction * 3.0, 0.0))

func _update_tint() -> void:
	if _hurt_flash > 0.07:
		visual.set_tint(Color(2.6, 2.6, 2.6, 1.0))
	elif _hurt_flash > 0.0:
		visual.set_tint(Color(1.0, 0.45, 0.45, 1.0))
	else:
		visual.set_tint(Color.WHITE)

func _check_contact() -> void:
	# A checagem de dano é manual (por distância), então precisa verificar
	# o estado de morte independentemente das colisões do PhysicsServer.
	if _dead or health <= 0 or not is_instance_valid(target) or _contact_cooldown > 0.0:
		return
	var center: Vector2 = global_position + Vector2(0.0, -body_height * 0.5)
	var diff: Vector2 = target.global_position - center
	var reach_x: float = half_width + (36.0 if is_boss else 18.0)
	if absf(diff.x) < reach_x and absf(diff.y) < body_height * 0.5 + 26.0 and target.has_method("take_damage"):
		target.call("take_damage", contact_damage, global_position.x)
		_contact_cooldown = 0.9

func take_hit(amount: int, from_x: float = NAN) -> void:
	# Também ignora sinais de ataque que possam chegar atrasados no mesmo frame.
	if _dead or health <= 0:
		return
	var damage: int = maxi(amount, 0)
	health = maxi(0, health - damage)
	_hurt_flash = 0.14

	var push: float = 1.0
	if not is_nan(from_x):
		push = signf(global_position.x - from_x)
		if push == 0.0:
			push = 1.0
	var resist: float = 0.3 if is_boss else 1.0
	velocity.x = push * 230.0 * resist
	velocity.y = -140.0 * resist
	_stun_time = 0.18

	visual.squash(1.3, 0.76, 0.22)
	var center: Vector2 = global_position + Vector2(0.0, -body_height * 0.5)
	var scene: Node = get_parent()
	FX.burst(scene, center, Color.WHITE, 5, 230.0, 0.22, 2.0, 200.0, Vector2(push, -0.3), 80.0)
	FX.burst(scene, center, visual.average_color.lightened(0.3), 9, 170.0, 0.45, 3.0, 640.0, Vector2(push, -0.5), 75.0)
	FX.popup(scene, global_position + Vector2(0.0, -body_height - 6.0), "-%d" % damage, Color("#ffe27a"))
	health_changed.emit(health, max_health)
	if health == 0:
		_die(push)

func _die(push: float) -> void:
	if _dead:
		return
	_dead = true

	# Desliga a lógica de jogo antes de iniciar a animação de morte.
	# O sprite permanece na cena para que o efeito visual termine normalmente.
	set_physics_process(false)
	velocity = Vector2.ZERO
	target = null
	remove_from_group("enemies")

	# Desativa camada, máscara e todas as formas de colisão do inimigo.
	# set_deferred evita alterar o PhysicsServer durante uma consulta física.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	for shape_node in find_children("*", "CollisionShape2D", true, false):
		(shape_node as CollisionShape2D).set_deferred("disabled", true)
	for polygon_node in find_children("*", "CollisionPolygon2D", true, false):
		(polygon_node as CollisionPolygon2D).set_deferred("disabled", true)

	var scene: Node = get_parent()
	var center: Vector2 = global_position + Vector2(0.0, -body_height * 0.5)
	if not is_boss:
		GameState.add_coins(1)
		FX.popup(scene, global_position + Vector2(0.0, -body_height - 18.0), "+1", Color("#ffd24a"))
	died.emit(self)
	FX.burst(scene, center, visual.average_color.lightened(0.3), 18 if not is_boss else 40, 240.0, 0.6, 4.0, 640.0, Vector2(push, -0.6), 120.0)
	FX.burst(scene, center, Color.WHITE, 8, 260.0, 0.3, 2.0, 100.0)
	FX.shake_player(get_tree(), 7.0 if is_boss else 3.5)
	FX.hit_stop(get_tree(), 0.14 if is_boss else 0.07)
	visual.set_tint(Color(2.6, 2.6, 2.6, 1.0))
	visual.stop_squash()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector2(1.35, 0.05), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "modulate:a", 0.0, 0.32)
	tween.tween_property(self, "position:x", position.x + push * 14.0, 0.32).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
