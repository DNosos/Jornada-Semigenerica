extends Node2D

var sprite: AnimatedSprite2D
var base_scale: float = 1.0
var body_width: float = 0.0
var feet_height: float = 0.0
var average_color: Color = Color.WHITE
var _center_offset: float = 0.0
var _squash_tween: Tween

func setup(texture: Texture2D, style: String, p_scale: float, fps: float = 2.0) -> void:
	base_scale = p_scale
	if texture == null:
		texture = preload("res://Script/fx.gd").load_texture("")
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var used: Rect2i = image.get_used_rect()
	var width: int = image.get_width()
	var height: int = image.get_height()

	var frames: SpriteFrames = SpriteFrames.new()
	frames.set_animation_loop(&"default", true)
	frames.set_animation_speed(&"default", fps)
	frames.add_frame(&"default", texture)
	frames.add_frame(&"default", ImageTexture.create_from_image(_make_alt(image, used, style)))

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * p_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	body_width = float(used.size.x) * p_scale
	feet_height = float(used.size.y) * p_scale
	_center_offset = float(used.position.x) + float(used.size.x) * 0.5 - float(width) * 0.5
	sprite.position.y = -(float(used.end.y) - float(height) * 0.5) * p_scale
	average_color = preload("res://Script/fx.gd").average_color(image)
	face(1.0)
	sprite.frame = randi() % 2
	sprite.play(&"default")

func face(direction: float) -> void:
	if direction == 0.0 or not is_instance_valid(sprite):
		return
	sprite.flip_h = direction < 0.0
	sprite.position.x = _center_offset * base_scale * (1.0 if direction < 0.0 else -1.0)

func set_tint(color: Color) -> void:
	if is_instance_valid(sprite):
		sprite.modulate = color

func stop_squash() -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()

func squash(stretch_x: float, stretch_y: float, duration: float = 0.2) -> void:
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()
	scale = Vector2(stretch_x, stretch_y)
	_squash_tween = create_tween()
	_squash_tween.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _make_alt(image: Image, used: Rect2i, style: String) -> Image:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var step: int = maxi(1, int(round(float(used.size.y) / 28.0)))
	var out: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var split: int = used.position.y + int(float(used.size.y) * 0.55)
	match style:
		"float":
			var lift: int = step + 1
			out.blend_rect(image, Rect2i(0, lift, width, height - lift), Vector2i(0, 0))
		"sway":
			out.blend_rect(image, Rect2i(0, split, width, height - split), Vector2i(0, split))
			out.blend_rect(image, Rect2i(0, 0, width, split), Vector2i(step, maxi(1, step / 2)))
		"wave":
			var start: int = used.position.y + int(float(used.size.y) * 0.4)
			out.blend_rect(image, Rect2i(0, 0, width, start), Vector2i(0, 0))
			for row in range(start, height):
				var shift: int = int(round((sin(float(row) * 0.55) + 1.0) * 0.5 * float(step)))
				out.blend_rect(image, Rect2i(0, row, width, 1), Vector2i(shift, row))
		_:
			out.blend_rect(image, Rect2i(0, split, width, height - split), Vector2i(0, split))
			out.blend_rect(image, Rect2i(0, 0, width, split), Vector2i(0, step))
	return out
