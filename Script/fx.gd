extends RefCounted

const FONT_PATH: String = "res://Font's/dogica.ttf"
const SLASH_PATH: String = "res://Image's/assets/The Skill.png"

static func load_texture(path: String) -> Texture2D:
	var candidates: Array[String] = [
		path,
		path.replace("ô", "#U00f4").replace("ú", "#U00fa"),
		path.replace("#U00f4", "ô").replace("#U00fa", "ú")
	]
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			var texture: Texture2D = load(candidate) as Texture2D
			if texture:
				return texture
	push_warning("Textura não encontrada: " + path)
	var image: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.0, 1.0, 0.6))
	return ImageTexture.create_from_image(image)

static func burst(parent: Node, at: Vector2, color: Color, count: int = 10, speed: float = 160.0, life: float = 0.45, size: float = 3.0, gravity: float = 620.0, direction: Vector2 = Vector2.UP, spread: float = 180.0) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = life
	particles.explosiveness = 1.0
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed * 0.35
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0.0, gravity)
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size
	particles.color = color
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = ramp
	particles.z_index = 50
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	parent.get_tree().create_timer(life + 0.3).timeout.connect(particles.queue_free)

static func dust(parent: Node, at: Vector2, side: float = 0.0, count: int = 5) -> void:
	var direction: Vector2 = Vector2.UP
	var spread: float = 180.0
	if side != 0.0:
		direction = Vector2(side, -0.35)
		spread = 35.0
	burst(parent, at, Color(0.86, 0.82, 0.72, 0.85), count, 70.0, 0.35, 3.0, 60.0, direction, spread)

static func popup(parent: Node, at: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 8) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", load(FONT_PATH) as Font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.global_position = at - label.get_minimum_size() * 0.5
	var tween: Tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 26.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.chain().tween_callback(label.queue_free)

static func slash(parent: Node, at: Vector2, facing: float) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(SLASH_PATH) as Texture2D
	sprite.flip_h = facing < 0.0
	sprite.z_index = 40
	sprite.scale = Vector2(0.55, 0.8)
	parent.add_child(sprite)
	sprite.global_position = at
	var tween: Tween = sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.45, 1.1), 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_position:x", at.x + facing * 10.0, 0.17)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.17).set_delay(0.04)
	tween.chain().tween_callback(sprite.queue_free)

static func hit_stop(tree: SceneTree, duration: float = 0.05, time_scale: float = 0.05) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = time_scale
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

static func shake_player(tree: SceneTree, strength: float) -> void:
	var player: Node = tree.get_first_node_in_group("player")
	if player and player.has_method("shake"):
		player.call("shake", strength)

static func average_color(image: Image) -> Color:
	var red: float = 0.0
	var green: float = 0.0
	var blue: float = 0.0
	var samples: int = 0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.5:
				red += pixel.r
				green += pixel.g
				blue += pixel.b
				samples += 1
	if samples == 0:
		return Color.WHITE
	return Color(red / samples, green / samples, blue / samples, 1.0)
