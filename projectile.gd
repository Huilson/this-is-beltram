# res://scripts/projectile.gd

extends Area2D

# Definidos pelo unit.gd antes de adicionar à cena
var direcao: Vector2 = Vector2.RIGHT
var dano: int = 0
var dono_path: NodePath

# Caminho do sprite da flecha — ajuste se o arquivo estiver em outro lugar
const SPRITE_FLECHA = "res://sprites/arrow.png"

@export var velocidade: float = 400.0   # Pixels por segundo
@export var alcance_max: float = 400.0  # Distância máxima antes de sumir

var _distancia_percorrida: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

	# Aplica a textura da flecha no Sprite2D filho
	var sprite = $Sprite2D
	sprite.texture = load(SPRITE_FLECHA)

	# Rotaciona o nó inteiro para apontar na direção do disparo.
	# Como o sprite base aponta para a direita (Vector2.RIGHT = ângulo 0),
	# o ângulo do vetor direção já é suficiente para alinhar corretamente.
	rotation = direcao.angle()

func _physics_process(delta):
	# Move na direção definida (a rotação é só visual — a direção de movimento não muda)
	var passo = direcao * velocidade * delta
	position += passo
	_distancia_percorrida += passo.length()

	if _distancia_percorrida >= alcance_max:
		queue_free()

func _on_body_entered(body: Node):
	# Ignora colisão com o próprio atirador
	if body.get_path() == dono_path:
		return

	# Acertou um personagem vivo — aplica dano e some
	if body is CharacterBody2D and body.has_method("receber_dano") and not body.is_dead:
		body.receber_dano.rpc_id(1, body.get_path(), dano)
		queue_free()
		return

	# Acertou uma parede do TileMapLayer ou um StaticBody2D ou qualquer outro corpo sólido — some
	if body is TileMapLayer or StaticBody2D:
		print("bateu na parede")
		queue_free()
