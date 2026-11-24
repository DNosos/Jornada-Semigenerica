extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died(enemy: Node)

var max_health: int = 3
var health: int = 3
var move_speed: float = 55.0
var patrol_distance: float = 100.0
var chase_range: float = 250.0
var contact_damage: int = 1
var is_boss: bool = false
var target: CharacterBody2D
var _origin_x: float = 0.0
var _direction: float = 1.0
var _contact_cooldown: float = 0.0
var _hurt_flash: float = 0.0
var _sprite: Sprite2D

func configure(texture_path: String, hp: int, speed: float, patrol: float, size_scale: float = 0.75, boss: bool = false) -> void:
	max_health = hp
	health = hp
	move_speed = speed
	patrol_distance = patrol
	is_boss = boss
	contact_damage = 2 if boss else 1
	_origin_x = global_position.x
	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")

	_sprite = Sprite2D.new()
	_sprite.texture = load(texture_path) as Texture2D
	_sprite.scale = Vector2.ONE * size_scale
	add_child(_sprite)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34.0, 42.0) * size_scale
	collision.shape = shape
	add_child(collision)

func set_target(player: CharacterBody2D) -> void:
	target = player
	_origin_x = global_position.x

func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if not is_on_floor():
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity")) * delta

	var direction := 0.0
	if is_instance_valid(target):
		var distance_x := target.global_position.x - global_position.x
		var distance_y := absf(target.global_position.y - global_position.y)
		if absf(distance_x) < chase_range and distance_y < 180.0:
			direction = signf(distance_x)
		else:
			if global_position.x > _origin_x + patrol_distance:
				_direction = -1.0
			elif global_position.x < _origin_x - patrol_distance:
				_direction = 1.0
			direction = _direction
	else:
		direction = _direction

	velocity.x = direction * move_speed
	if _sprite and direction != 0.0:
		_sprite.flip_h = direction < 0.0
	move_and_slide()

	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if _sprite and _hurt_flash <= 0.0:
		_sprite.modulate = Color.WHITE
	if is_instance_valid(target) and _contact_cooldown <= 0.0:
		var close_x := absf(target.global_position.x - global_position.x) < (34.0 if not is_boss else 58.0)
		var close_y := absf(target.global_position.y - global_position.y) < 52.0
		if close_x and close_y and target.has_method("take_damage"):
			target.call("take_damage", contact_damage)
			_contact_cooldown = 0.9

func take_hit(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(amount, 0))
	_hurt_flash = 0.12
	if _sprite:
		_sprite.modulate = Color(1.0, 0.45, 0.45)
	health_changed.emit(health, max_health)
	if health == 0:
		if not is_boss:
			GameState.add_coins(1)
		died.emit(self)
		queue_free()
