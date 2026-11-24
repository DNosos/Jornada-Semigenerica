extends Area2D

const FX = preload("res://Script/fx.gd")

var kind: String = "coin"
var amount: int = 1
var collected: bool = false
var _pivot: Node2D
var _pulse: Tween

func configure(p_kind: String, p_amount: int) -> void:
	kind = p_kind
	amount = p_amount

func setup_visual(texture: Texture2D, size_scale: float) -> void:
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var used: Rect2i = image.get_used_rect()

	_pivot = Node2D.new()
	add_child(_pivot)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * size_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(
		-(float(used.position.x) + float(used.size.x) * 0.5 - float(image.get_width()) * 0.5) * size_scale,
		-(float(used.end.y) - float(image.get_height()) * 0.5) * size_scale
	)
	_pivot.add_child(sprite)

	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	collision.position = Vector2(0.0, -float(used.size.y) * size_scale * 0.5)
	add_child(collision)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if _pivot:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_pivot, "scale", Vector2(1.06, 0.94), 0.55).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(_pivot, "scale", Vector2(0.96, 1.05), 0.55).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	var scene: Node = get_parent()
	var spot: Vector2 = global_position + Vector2(0.0, -14.0)
	if kind == "coin":
		GameState.add_coins(amount)
		FX.burst(scene, spot, Color("#ffd24a"), 9, 150.0, 0.45, 2.5, 420.0, Vector2.UP, 140.0)
		FX.popup(scene, spot + Vector2(0.0, -14.0), "+%d" % amount, Color("#ffd24a"))
	elif kind == "potion":
		GameState.heal(amount)
		FX.burst(scene, spot, Color("#ff8a4a"), 9, 130.0, 0.5, 2.5, 120.0, Vector2.UP, 140.0)
		FX.popup(scene, spot + Vector2(0.0, -14.0), "+%d VIDA" % amount, Color("#9dff8a"))
	set_deferred("monitoring", false)
	if _pivot == null:
		queue_free()
		return
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_pivot, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(_pivot, "position:y", -16.0, 0.15)
	tween.tween_property(_pivot, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
