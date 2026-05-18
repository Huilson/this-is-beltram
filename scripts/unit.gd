# res://scripts/unit.gd
# Controla o personagem no mapa: movimento, animações, combate e morte.
# Combate é autoritativo no servidor — só o servidor aplica e valida o dano.
extends CharacterBody2D

@onready var sprite = $Character
@onready var anim_player = $Character/AnimationPlayer

# Hitbox de ataque corpo a corpo. Deve existir na cena como filho direto de Unit.
# Sugestão de estrutura: Area2D com CollisionShape2D (CircleShape ou RectangleShape).
# Desativado por padrão; só ativa durante o frame do ataque.
@onready var melee_area = $MeleeArea

@export var speed = 150.0

# --- Estado de combate ---
var char_class: String = ""   # Classe deste personagem ("Warrior", "Cleric", "Archer", "Wizard")
var max_hp: int = 100
var current_hp: int = 100
var damage: int = 10
var attack_range: float = 40.0
var attack_type: String = "melee"  # "melee" ou "projectile"

var is_attacking = false
var is_dead = false

# Cena do projétil — carregada apenas se a classe usa projétil
var projectile_scene = preload("res://scenes/projectile.tscn")

# Configura o personagem com os dados vindos de Global.characters_data.
# Chamado pelo map_scene após instanciar o herói.
func setup(data: Dictionary):
	if not is_node_ready():
		await ready

	# Lê os stats da classe no Global e os aplica localmente
	char_class = data.get("class", "Warrior")
	var stats = Global.class_stats.get(char_class, {})
	max_hp       = stats.get("max_hp", 100)
	current_hp   = max_hp
	damage       = stats.get("damage", 10)
	attack_range = stats.get("attack_range", 40.0)
	attack_type  = stats.get("attack_type", "melee")

	# Configura o tamanho do hitbox corpo a corpo com base no range da classe
	if melee_area:
		var shape = melee_area.get_node_or_null("CollisionShape2D")
		if shape and shape.shape is CircleShape2D:
			shape.shape.radius = attack_range
		melee_area.monitoring = false   # Desativado até o momento do ataque

	sprite.texture = load(data.sprite_sheet)
	anim_player.play("idle")

	if is_multiplayer_authority():
		_sincronizar_sprite.rpc(data.sprite_sheet)

@rpc("authority", "call_local", "reliable")
func _sincronizar_sprite(sprite_path: String):
	sprite.texture = load(sprite_path)
	anim_player.play("idle")

func _physics_process(_delta):
	# Apenas o dono do nó lê input; mortos não se movem
	if not is_multiplayer_authority() or is_dead:
		return

	if is_attacking:
		return

	var direcao = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direcao * speed
	move_and_slide()
	_atualizar_animacoes(direcao)

	if Input.is_action_just_pressed("ui_accept"):
		atacar()

func _atualizar_animacoes(direcao: Vector2):
	var nova_anim = "idle"
	var flip = sprite.flip_h

	if direcao.length() > 0:
		nova_anim = "move"
		if direcao.x != 0:
			flip = direcao.x < 0

	if anim_player.current_animation != nova_anim or sprite.flip_h != flip:
		_sincronizar_animacao.rpc(nova_anim, flip)

@rpc("authority", "call_local", "unreliable")
func _sincronizar_animacao(nome_anim: String, flip_h: bool):
	sprite.flip_h = flip_h
	if anim_player.current_animation != nome_anim:
		anim_player.play(nome_anim)

# Ponto de entrada do ataque, chamado pelo jogador local.
func atacar():
	is_attacking = true
	velocity = Vector2.ZERO
	_iniciar_ataque.rpc()   # Toca a animação "attack" em todos os peers

	if attack_type == "melee":
		# Corpo a corpo: aplica o dano no meio da animação para coincidir com o frame de impacto.
		# Ajuste o tempo (0.3s) conforme a duração real da sua animação de ataque.
		await get_tree().create_timer(0.3).timeout
		_executar_ataque_melee()
		await anim_player.animation_finished
	else:
		# Mesma lógica acima.
		await get_tree().create_timer(0.6).timeout
		_disparar_projetil()
		await anim_player.animation_finished

	is_attacking = false

@rpc("authority", "call_local", "reliable")
func _iniciar_ataque():
	anim_player.play("attack")

# --- Corpo a corpo ---
# Ativa o hitbox por um frame e verifica quais unidades inimigas foram atingidas.
# Só o dono do nó chama isso; o dano é enviado via RPC para o servidor confirmar.
func _executar_ataque_melee():
	if not melee_area:
		return

	print("Tudo certo o ataque começou")
	# Posiciona o hitbox à frente do personagem conforme a direção que ele está olhando
	var direcao_x = -1.0 if sprite.flip_h else 1.0
	melee_area.position = Vector2(attack_range * 0.5 * direcao_x, 0)

	melee_area.monitoring = true
	# Força a atualização física para detectar sobreposições imediatamente
	await get_tree().physics_frame
	melee_area.monitoring = false

	# Verifica todos os corpos dentro do hitbox
	for area in melee_area.get_overlapping_areas():
		var alvo = area.get_parent()
		# Garante que o alvo é outra Unit, está viva e não é o próprio atacante
		if alvo is CharacterBody2D and alvo != self:
			# Envia o pedido de dano ao servidor (apenas o servidor aplica dano)
			receber_dano.rpc_id(alvo.get_path(), damage)

# --- Projétil ---
# Instancia o projétil e o lança na direção que o personagem está olhando.
# O projétil cuida da detecção de colisão por conta própria.
func _disparar_projetil():
	var proj = projectile_scene.instantiate()

	# Passa os dados necessários para o projétil funcionar corretamente
	proj.dono_path = get_path()         # Para o projétil saber de quem é
	proj.dano = damage

	# Direção com base no flip do sprite
	proj.direcao = Vector2(-1, 0) if sprite.flip_h else Vector2(1, 0)
	proj.global_position = global_position

	# Adiciona o projétil à cena no mesmo nível do personagem (não como filho)
	get_parent().add_child(proj)

# RPC chamado por qualquer peer mas processado apenas pelo servidor (rpc_id(1)).
# O servidor é a única fonte de verdade para HP — evita trapaças e conflitos.
# Recebe o caminho do nó alvo e o valor de dano a aplicar.
@rpc("any_peer", "reliable")
func receber_dano(alvo_path: NodePath, valor: int):
	# Apenas o servidor processa o dano de fato
	if not multiplayer.is_server():
		return

	var alvo = get_node_or_null(alvo_path)
	if alvo == null:
		return

	# Aplica o dano e propaga o novo HP para todos os peers
	var novo_hp = clamp(alvo.current_hp - valor, 0, alvo.max_hp)
	_aplicar_hp.rpc(alvo_path, novo_hp)

# RPC do servidor para todos: atualiza o HP do alvo e dispara a morte se necessário.
@rpc("authority", "call_local", "reliable")
func _aplicar_hp(alvo_path: NodePath, novo_hp: int):
	var alvo = get_node_or_null(alvo_path)
	if alvo == null:
		return

	alvo.current_hp = novo_hp
	print("[%s] HP: %d / %d" % [alvo.name, alvo.current_hp, alvo.max_hp])

	if alvo.current_hp <= 0:
		alvo._morrer()

# Toca a animação de morte e remove o nó ao terminar.
# Chamado localmente em todos os peers via _aplicar_hp.
func _morrer():
	is_dead = true
	velocity = Vector2.ZERO
	anim_player.play("dead")
	# Desativa colisões para não bloquear o cenário após a morte
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	await anim_player.animation_finished
	queue_free()
