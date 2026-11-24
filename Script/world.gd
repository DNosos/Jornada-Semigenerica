extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://Scene's/player.tscn")
const NPC_SCRIPT = preload("res://Script/npc.gd")
const ENEMY_SCRIPT = preload("res://Script/enemy.gd")
const PICKUP_SCRIPT = preload("res://Script/pickup.gd")
const CHECKPOINT_SCRIPT = preload("res://Script/checkpoint.gd")
const HAZARD_SCRIPT = preload("res://Script/hazard.gd")
const PORTAL_SCRIPT = preload("res://Script/portal.gd")
const HUD_SCRIPT = preload("res://Script/hud.gd")
const DIALOGUE_SCRIPT = preload("res://Script/dialogue_box.gd")

const FX = preload("res://Script/fx.gd")

const FLOOR_Y: float = 580.0

var level_index: int = 0
var world_width: float = 2200.0
var level_title: String = "Trilha da Floresta"
var background_color: Color = Color("#263c38")
var player
var hud
var dialogue
var boss
var boss_defeated: bool = false
var mage_helped: bool = false
var _ending_started: bool = false
var _solids: Array = []

func _ready() -> void:
	level_index = clampi(GameState.current_level, 0, GameState.LAST_LEVEL)
	_configure_level()
	_create_background()
	_create_geometry()
	_create_player()
	_create_hud()
	_create_dialogue()
	_spawn_level_contents()
	GameState.changed.connect(_on_game_state_changed)

func _configure_level() -> void:
	match level_index:
		0:
			level_title = "1 - Trilha da Floresta"
			world_width = 2200.0
			background_color = Color("#30483d")
		1:
			level_title = "2 - Ruínas Esquecidas"
			world_width = 2550.0
			background_color = Color("#343b48")
		2:
			level_title = "3 - Castelo do Rei Demônio"
			world_width = 2850.0
			background_color = Color("#382b39")

func _create_background() -> void:
	var sky := Polygon2D.new()
	sky.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(world_width, 0),
		Vector2(world_width, 760), Vector2(0, 760)
	])
	sky.color = background_color
	sky.z_index = -100
	add_child(sky)

	var far_hills := Polygon2D.new()
	far_hills.polygon = PackedVector2Array([
		Vector2(0, 455), Vector2(180, 350), Vector2(360, 425),
		Vector2(590, 315), Vector2(800, 420), Vector2(1050, 335),
		Vector2(1270, 430), Vector2(1510, 330), Vector2(1760, 420),
		Vector2(2010, 340), Vector2(world_width, 430),
		Vector2(world_width, 580), Vector2(0, 580)
	])
	far_hills.color = background_color.lightened(0.12)
	far_hills.z_index = -90
	add_child(far_hills)

	var near_hills := Polygon2D.new()
	near_hills.polygon = PackedVector2Array([
		Vector2(0, 510), Vector2(240, 430), Vector2(470, 500),
		Vector2(710, 410), Vector2(920, 500), Vector2(1190, 420),
		Vector2(1450, 505), Vector2(1710, 420), Vector2(1940, 505),
		Vector2(world_width, 430), Vector2(world_width, 580), Vector2(0, 580)
	])
	near_hills.color = background_color.lightened(0.06)
	near_hills.z_index = -80
	add_child(near_hills)

	for cloud_x in range(150, int(world_width), 510):
		var cloud := Polygon2D.new()
		cloud.position = Vector2(cloud_x, 120 + (cloud_x % 3) * 18)
		cloud.polygon = PackedVector2Array([
			Vector2(0, 12), Vector2(18, 12), Vector2(18, 0),
			Vector2(55, 0), Vector2(55, 10), Vector2(78, 10),
			Vector2(78, 24), Vector2(0, 24)
		])
		cloud.color = Color(0.88, 0.88, 0.79, 0.16)
		cloud.z_index = -70
		add_child(cloud)

func _create_geometry() -> void:
	var segments: Array = []
	match level_index:
		0:
			segments = [[0.0, 690.0], [785.0, 1390.0], [1510.0, world_width]]
		1:
			segments = [[0.0, 560.0], [665.0, 1235.0], [1350.0, 1900.0], [2000.0, world_width]]
		2:
			segments = [[0.0, 850.0], [940.0, 1720.0], [1815.0, world_width]]
	for segment in segments:
		_make_platform(segment[0], FLOOR_Y, segment[1], 80.0, Color("#493d38"), Color("#83a65d"))

	var platforms: Array = []
	match level_index:
		0:
			platforms = [Rect2(340, 475, 135, 22), Rect2(525, 405, 120, 22), Rect2(850, 485, 125, 22), Rect2(1110, 440, 135, 22), Rect2(1515, 475, 130, 22), Rect2(1760, 415, 135, 22)]
		1:
			platforms = [Rect2(235, 470, 130, 22), Rect2(450, 400, 135, 22), Rect2(720, 475, 145, 22), Rect2(1040, 425, 125, 22), Rect2(1450, 470, 145, 22), Rect2(1760, 395, 150, 22), Rect2(2130, 465, 135, 22)]
		2:
			platforms = [Rect2(300, 465, 145, 22), Rect2(555, 405, 125, 22), Rect2(990, 465, 135, 22), Rect2(1290, 415, 145, 22), Rect2(1850, 470, 150, 22), Rect2(2150, 410, 145, 22)]
	for rect in platforms:
		_make_platform(rect.position.x, rect.position.y, rect.size.x, rect.size.y, Color("#58484a"), Color("#a6a078"))

	for x in range(40, int(world_width), 280):
		var half_width: float = 46.0 if level_index == 2 else 28.0
		if _on_floor_segment(float(x), half_width):
			_make_decoration(x, FLOOR_Y)

	match level_index:
		0:
			_spawn_spikes(960, 72)
			_spawn_spikes(1660, 82)
		1:
			_spawn_spikes(420, 75)
			_spawn_spikes(1430, 80)
			_spawn_spikes(2070, 80)
		2:
			_spawn_spikes(700, 80)
			_spawn_spikes(1745, 75)

func _make_platform(x: float, top_y: float, width: float, height: float, base_color: Color, top_color: Color) -> void:
	_solids.append(Rect2(x, top_y, width, height))
	var body := StaticBody2D.new()
	body.position = Vector2(x + width * 0.5, top_y + height * 0.5)
	body.collision_layer = 1
	body.collision_mask = 1
	var block := Polygon2D.new()
	block.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5),
		Vector2(width * 0.5, height * 0.5),
		Vector2(-width * 0.5, height * 0.5)
	])
	block.color = base_color
	body.add_child(block)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5),
		Vector2(width * 0.5, -height * 0.5 + 9),
		Vector2(-width * 0.5, -height * 0.5 + 9)
	])
	top.color = top_color
	body.add_child(top)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _make_decoration(x: float, y: float) -> void:
	var atlas_texture := AtlasTexture.new()
	var decoration := Sprite2D.new()
	if level_index == 2:
		atlas_texture.atlas = load("res://Image's/TileMaps/castle-02.png") as Texture2D
		atlas_texture.region = Rect2(224, 224, 64, 64)
		decoration.scale = Vector2(1.45, 1.45)
		decoration.position = Vector2(x, y - 64.0 * 1.45 * 0.5 + 4.0)
	else:
		atlas_texture.atlas = load("res://Image's/TileMaps/Florest - Tileset (2).png") as Texture2D
		atlas_texture.region = Rect2(64, 128, 32, 64)
		decoration.scale = Vector2(1.7, 1.7)
		decoration.position = Vector2(x, y - 64.0 * 1.7 * 0.5 + 4.0)
	decoration.texture = atlas_texture
	decoration.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	decoration.z_index = -1
	add_child(decoration)

func _spawn_spikes(x: float, width: float) -> void:
	var hazard := Area2D.new()
	hazard.set_script(HAZARD_SCRIPT)
	hazard.collision_layer = 0
	hazard.collision_mask = 1
	hazard.position = Vector2(x + width * 0.5, FLOOR_Y - 8.0)
	var teeth := Polygon2D.new()
	var points := PackedVector2Array()
	var tooth_count := int(width / 20.0)
	for i in range(tooth_count):
		var left := -width * 0.5 + i * 20.0
		points.append(Vector2(left, 8))
		points.append(Vector2(left + 10, -14))
		points.append(Vector2(left + 20, 8))
	teeth.polygon = points
	teeth.color = Color("#d6c7b2")
	hazard.add_child(teeth)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 18)
	collision.shape = shape
	collision.position = Vector2(0.0, -2.0)
	hazard.add_child(collision)
	add_child(hazard)

func _create_player() -> void:
	player = PLAYER_SCENE.instantiate() as CharacterBody2D
	add_child(player)
	var default_spawn := Vector2(115, FLOOR_Y - 29.0)
	player.global_position = GameState.get_spawn_position(default_spawn)
	player.interact_requested.connect(_on_interact_requested)
	player.respawned.connect(func(): hud.notify("Você voltou ao último checkpoint."))
	var camera := player.get_node_or_null("Camera") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_right = int(world_width)
		camera.limit_top = 0
		camera.limit_bottom = 850

func _create_hud() -> void:
	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.set_level_name(level_title)

func _create_dialogue() -> void:
	dialogue = DIALOGUE_SCRIPT.new()
	add_child(dialogue)
	dialogue.dialogue_finished.connect(_on_dialogue_finished)

func _surface_y(x: float, hint_y: float) -> float:
	var best: float = INF
	for rect in _solids:
		var area: Rect2 = rect
		if x >= area.position.x and x <= area.end.x and area.position.y >= hint_y - 20.0 and area.position.y < best:
			best = area.position.y
	if best == INF:
		return FLOOR_Y
	return best

func _on_floor_segment(x: float, half_width: float) -> bool:
	for rect in _solids:
		var area: Rect2 = rect
		if is_equal_approx(area.position.y, FLOOR_Y) and area.position.x <= x - half_width and x + half_width <= area.end.x:
			return true
	return false

func _spawn_level_contents() -> void:
	if level_index == 0:
		_spawn_npc("master", "Mestra", "res://Image's/assets/A Menina.png", Vector2(245, 548), PackedStringArray([
			"Ah, você acordou! O Rei Demônio levou a princesa para o castelo.",
			"Use A e D para andar. W ou Espaço faz o herói pular.",
			"Clique com o botão esquerdo para atacar. Pressione F perto de alguém para conversar.",
			"Procure moedas e poções pelo caminho. O ferreiro troca moedas por melhorias na espada.",
			"Cuidado com os monstros e com os espinhos. Encontre o checkpoint antes de seguir!"
		]))
		_spawn_npc("smith", "Ferreiro", "res://Image's/assets/O Ferreiro.png", Vector2(525, 548), PackedStringArray(["Bem-vindo à minha forja!"]))
		_spawn_enemy("res://Image's/assets/O Zumbi.png", Vector2(900, 538), 3, 48.0, 95.0, 0.72, "sway")
		_spawn_enemy("res://Image's/assets/Os Servos do Rei Demônio.png", Vector2(1270, 538), 3, 58.0, 105.0, 0.72, "bob")
		_spawn_enemy("res://Image's/assets/O Zumbi.png", Vector2(1775, 538), 3, 52.0, 100.0, 0.72, "sway")
		_spawn_pickup("coin", Vector2(385, 440), 1, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("coin", Vector2(575, 370), 1, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("coin", Vector2(865, 440), 1, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("coin", Vector2(1130, 400), 2, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("potion", Vector2(1450, 535), 2, "res://Image's/assets/A Sopa.png")
		_spawn_pickup("coin", Vector2(1810, 360), 2, "res://Image's/assets/O Dinheiro.png")
		_spawn_checkpoint(1160)
	elif level_index == 1:
		_spawn_npc("mage", "Mago Viajante", "res://Image's/assets/O Mago.png", Vector2(245, 548), PackedStringArray([
			"As ruínas estão infestadas pelos servos do Rei Demônio.",
			"Não tente atravessar os espinhos correndo. Use as plataformas para alcançar lugares altos.",
			"Posso compartilhar uma sopa restauradora com você. Volte a falar comigo caso precise de orientação."
		]))
		_spawn_enemy("res://Image's/assets/Os Servos do Rei Demônio.png", Vector2(750, 538), 4, 64.0, 110.0, 0.78, "bob")
		_spawn_enemy("res://Image's/assets/O Polvo.png", Vector2(1080, 535), 4, 54.0, 100.0, 0.70, "wave")
		_spawn_enemy("res://Image's/assets/O Zumbi.png", Vector2(1620, 538), 4, 62.0, 115.0, 0.76, "sway")
		_spawn_enemy("res://Image's/assets/Os Servos do Rei Demônio.png", Vector2(2170, 538), 5, 68.0, 120.0, 0.8, "bob")
		_spawn_pickup("coin", Vector2(285, 430), 2, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("coin", Vector2(485, 360), 2, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("potion", Vector2(930, 535), 2, "res://Image's/assets/A Sopa.png")
		_spawn_pickup("coin", Vector2(1510, 430), 2, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("coin", Vector2(2220, 420), 3, "res://Image's/assets/O Dinheiro.png")
		_spawn_checkpoint(1280)
	else:
		_spawn_npc("smith", "Ferreiro Real", "res://Image's/assets/O Ferreiro.png", Vector2(245, 548), PackedStringArray(["A última melhoria custa caro. Se tiver moedas suficientes, posso reforçar sua espada."]))
		_spawn_enemy("res://Image's/assets/Os Servos do Rei Demônio.png", Vector2(700, 538), 5, 68.0, 125.0, 0.82, "bob")
		_spawn_enemy("res://Image's/assets/O Mago.png", Vector2(1190, 535), 5, 60.0, 105.0, 0.76, "bob")
		_spawn_enemy("res://Image's/assets/O Polvo.png", Vector2(1530, 535), 5, 62.0, 110.0, 0.76, "wave")
		_spawn_checkpoint(1300)
		_spawn_pickup("coin", Vector2(380, 425), 3, "res://Image's/assets/O Dinheiro.png")
		_spawn_pickup("potion", Vector2(1040, 535), 3, "res://Image's/assets/A Sopa.png")
		_spawn_pickup("coin", Vector2(1960, 430), 3, "res://Image's/assets/O Dinheiro.png")
		_spawn_boss()
		_spawn_npc("princess", "Princesa", "res://Image's/assets/A Princesa.png", Vector2(2630, 548), PackedStringArray([
			"Você conseguiu! O Rei Demônio foi derrotado!",
			"Obrigada por me salvar. O reino inteiro será grato pelo que você fez.",
			"Agora podemos voltar para casa. Fim da jornada!"
		]))

	if level_index < GameState.LAST_LEVEL:
		_spawn_portal()

func _spawn_npc(id: String, title: String, texture_path: String, at: Vector2, lines: PackedStringArray) -> StaticBody2D:
	var npc = StaticBody2D.new()
	npc.set_script(NPC_SCRIPT)
	npc.configure(id, title, lines)
	npc.collision_layer = 2
	npc.collision_mask = 0
	npc.position = Vector2(at.x, _surface_y(at.x, at.y))
	npc.add_to_group("NPC")
	npc.setup_visual(FX.load_texture(texture_path), "bob", 1.6)
	add_child(npc)
	return npc

func _spawn_enemy(texture_path: String, at: Vector2, hp: int, speed: float, patrol: float, size_scale: float, style: String = "bob") -> CharacterBody2D:
	var enemy = CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)
	enemy.position = Vector2(at.x, _surface_y(at.x, at.y) - 1.0)
	enemy.configure(texture_path, hp, speed, patrol, size_scale, false, style)
	add_child(enemy)
	enemy.set_target(player as CharacterBody2D)
	return enemy

func _spawn_boss() -> void:
	boss = CharacterBody2D.new()
	boss.set_script(ENEMY_SCRIPT)
	boss.position = Vector2(2110, _surface_y(2110, 532) - 1.0)
	boss.configure("res://Image's/assets/A Morte.png", 16, 42.0, 20.0, 1.25, true, "float")
	boss.chase_range = 760.0
	add_child(boss)
	boss.set_target(player as CharacterBody2D)
	boss.health_changed.connect(hud.set_boss_health)
	boss.died.connect(_on_boss_died)
	hud.set_boss_health(16, 16)

func _spawn_pickup(kind: String, at: Vector2, amount: int, texture_path: String) -> void:
	var pickup = Area2D.new()
	pickup.set_script(PICKUP_SCRIPT)
	pickup.configure(kind, amount)
	pickup.position = Vector2(at.x, _surface_y(at.x, at.y))
	pickup.collision_layer = 0
	pickup.collision_mask = 1
	pickup.setup_visual(FX.load_texture(texture_path), 0.75)
	add_child(pickup)

func _spawn_checkpoint(x: float) -> void:
	var ground: float = _surface_y(x, 535.0)
	var checkpoint = Area2D.new()
	checkpoint.set_script(CHECKPOINT_SCRIPT)
	checkpoint.position = Vector2(x, ground - 36.0)
	checkpoint.configure(level_index, Vector2(x, ground - 29.0))
	checkpoint.collision_layer = 0
	checkpoint.collision_mask = 1
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([Vector2(-3, -42), Vector2(3, -42), Vector2(3, 36), Vector2(-3, 36)])
	pole.color = Color("#d3c7a0")
	checkpoint.add_child(pole)
	var flag := Polygon2D.new()
	flag.polygon = PackedVector2Array([Vector2(3, -40), Vector2(38, -29), Vector2(3, -15)])
	flag.color = Color("#d8a64e")
	checkpoint.add_child(flag)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34, 86)
	collision.shape = shape
	checkpoint.add_child(collision)
	add_child(checkpoint)
	checkpoint.activated.connect(func(): hud.notify("Checkpoint ativado! Você voltará daqui."))
	checkpoint.activated.connect(func(): _celebrate_checkpoint(flag, checkpoint.global_position + Vector2(20.0, -30.0)))

func _celebrate_checkpoint(flag: Polygon2D, at: Vector2) -> void:
	flag.color = Color("#7bd36a")
	var tween: Tween = flag.create_tween()
	tween.tween_property(flag, "scale", Vector2(1.35, 1.35), 0.12)
	tween.tween_property(flag, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	FX.burst(self, at, Color("#7bd36a"), 12, 140.0, 0.6, 3.0, 160.0)
	FX.burst(self, at, Color("#f6ce78"), 8, 100.0, 0.5, 2.0, 100.0)

func _spawn_portal() -> void:
	var portal = Area2D.new()
	portal.set_script(PORTAL_SCRIPT)
	portal.position = Vector2(world_width - 105.0, FLOOR_Y - 54.0)
	portal.collision_layer = 0
	portal.collision_mask = 1
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(34, -38), Vector2(43, 0),
		Vector2(28, 43), Vector2(0, 54), Vector2(-28, 43),
		Vector2(-43, 0), Vector2(-34, -38)
	])
	glow.color = Color(0.38, 0.76, 0.72, 0.48)
	portal.add_child(glow)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(0, -42), Vector2(23, -30), Vector2(29, 0),
		Vector2(18, 32), Vector2(0, 40), Vector2(-18, 32),
		Vector2(-29, 0), Vector2(-23, -30)
	])
	inner.color = Color("#273b50")
	portal.add_child(inner)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 36.0
	collision.shape = shape
	portal.add_child(collision)
	add_child(portal)
	portal.player_entered.connect(_on_portal_entered)

func _on_interact_requested(actor: Node2D) -> void:
	if dialogue.is_open or not is_instance_valid(actor):
		return
	var npc_id: String = actor.get("npc_id")
	var speaker: String = actor.get("display_name")
	var lines: PackedStringArray = actor.get("dialogue_lines")

	match npc_id:
		"smith":
			var cost := GameState.get_upgrade_cost()
			if GameState.buy_weapon_upgrade():
				lines = PackedStringArray([
					"Negócio fechado! Usei %d moedas para reforçar sua espada." % cost,
					"Agora seus golpes causam %d ponto(s) de dano. Boa caçada!" % GameState.get_attack_damage()
				])
			else:
				lines = PackedStringArray([
					"Para melhorar sua espada, preciso de %d moedas." % cost,
					"Você tem %d. Explore as fases e derrote inimigos para conseguir mais." % GameState.coins
				])
		"mage":
			if not mage_helped:
				GameState.heal(2)
				mage_helped = true
				lines = PackedStringArray([
					"Tome esta sopa restauradora. Você recuperou até 2 pontos de vida.",
					"Siga com cuidado: as criaturas daqui são mais resistentes."
				])
			else:
				lines = PackedStringArray(["Que a magia proteja sua jornada. Fique de olho nos checkpoints!"])
		"princess":
			if not boss_defeated:
				lines = PackedStringArray(["O Rei Demônio ainda está de pé! Derrote-o para me libertar."])
			else:
				lines = PackedStringArray([
					"Você conseguiu! O Rei Demônio foi derrotado!",
					"Obrigada por me salvar. O reino inteiro será grato pelo que você fez.",
					"Agora podemos voltar para casa. Fim da jornada!"
				])

	player.set_controls_locked(true)
	dialogue.start_dialogue(speaker, lines, actor)

func _on_dialogue_finished(actor: Node) -> void:
	if is_instance_valid(player):
		player.set_controls_locked(false)
	if is_instance_valid(actor) and actor.get("npc_id") == "princess" and boss_defeated and not _ending_started:
		_ending_started = true
		player.set_controls_locked(true)
		hud.show_victory()

func _on_boss_died(_enemy: Node) -> void:
	boss_defeated = true
	hud.hide_boss_health()
	hud.notify("O Rei Demônio foi derrotado! Vá até a princesa.")

func _on_portal_entered() -> void:
	if level_index >= GameState.LAST_LEVEL:
		return
	hud.notify("Você avançou para a próxima região!")
	GameState.advance_level()
	get_tree().change_scene_to_file("res://Scene's/tutorial.tscn")

func _on_game_state_changed() -> void:
	if is_instance_valid(hud):
		hud.refresh()
