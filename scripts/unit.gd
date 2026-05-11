extends CharacterBody2D

@onready var sprite = $Character
@onready var anim_player = $Character/AnimationPlayer
@export var speed = 150.0
var is_attacking = false

func setup(data):
	print(data)
	if not is_node_ready():
		await ready
	
	# 1. Carrega a imagem específica (já cortada)
	sprite.texture = load(data.sprite_sheet)
	
	# 2. Como a imagem só tem um gênero, o frame 0 é sempre o início!
	# Não precisamos mais somar nada nem usar o _process.
	print("Começo com ", sprite)
	anim_player.play("idle")

func _physics_process(_delta):
	# ESSENCIAL: Só processa o input se este boneco for o meu!
	if not is_multiplayer_authority():
		return
		
	if is_attacking:
		return # Bloqueia movimento enquanto ataca

	# 1. PEGAR INPUT DE MOVIMENTO
	var direcao = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. APLICAR MOVIMENTO
	velocity = direcao * speed
	move_and_slide()

	# 3. GERENCIAR ANIMAÇÕES
	_atualizar_animacoes(direcao)
	
	# 4. INPUT DE ATAQUE
	if Input.is_action_just_pressed("ui_accept"): # Tecla Espaço/Enter por padrão
		atacar()

func _atualizar_animacoes(direcao):
	if direcao.length() > 0:
		anim_player.play("move")
		# Virar o sprite para o lado que está andando
		if direcao.x != 0:
			sprite.flip_h = direcao.x < 0
	else:
		anim_player.play("idle")

func atacar():
	is_attacking = true
	velocity = Vector2.ZERO # Para o boneco no lugar
	anim_player.play("attack")
	
	# Espera a animação de ataque terminar
	await anim_player.animation_finished
	
	is_attacking = false
