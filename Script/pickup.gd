extends Area2D

var kind: String = "coin"
var amount: int = 1
var collected: bool = false

func configure(p_kind: String, p_amount: int) -> void:
	kind = p_kind
	amount = p_amount

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	collected = true
	if kind == "coin":
		GameState.add_coins(amount)
	elif kind == "potion":
		GameState.heal(amount)
	queue_free()
