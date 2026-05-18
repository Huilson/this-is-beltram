# res://scripts/map_scene.gd
# Controla a cena principal do jogo (o mapa).
# Responsável por instanciar os personagens de cada jogador, posicioná-los no mapa,
# sincronizar a chegada de novos peers e conectar a câmera ao herói local.
extends Node2D

# Referências aos nós da cena, carregadas automaticamente após a cena estar pronta.
@onready var tilemap = $TileMapLayer         # O TileMap que representa o terreno do mapa
@onready var units_container = $UnitsContainer # Container que agrupa todos os personagens instanciados
@onready var camera = $Camera2D              # Câmera 2D que seguirá o herói local

# Cena do personagem (unit) que será instanciada para cada jogador.
var unit_scene = preload("res://scenes/unit.tscn")

# Lista de posições de spawn no tilemap (em coordenadas de tile), uma por jogador.
# Suporta até 8 jogadores simultâneos. O índice é determinado pela ordem de entrada.
var spawn_slots = [
	Vector2i(6, 6), Vector2i(9, 6), Vector2i(6, 9), Vector2i(9, 9),
	Vector2i(12, 6), Vector2i(12, 9), Vector2i(6, 12), Vector2i(9, 12)
]

# Executado quando a cena é carregada por qualquer jogador.
func _ready():
	# Se nenhum personagem foi selecionado, não inicializa nada (segurança contra entradas inválidas)
	if Global.selected_char_key == "":
		return

	if multiplayer.is_server():
		# O host conecta os sinais de entrada/saída de peers para gerenciar jogadores dinamicamente
		multiplayer.peer_connected.connect(_on_novo_peer_conectado)       # Novo jogador entrou
		multiplayer.peer_disconnected.connect(remover_jogador)            # Jogador saiu
		adicionar_jogador(multiplayer.get_unique_id())                    # Adiciona o próprio host como jogador
	else:
		adicionar_jogador(multiplayer.get_unique_id())                    # Cliente adiciona a si mesmo localmente
		pedir_spawn_existentes.rpc_id(1)                                  # Pede ao servidor os jogadores já presentes

# Sinal disparado pelo servidor quando um novo peer se conecta.
# Notifica todos os peers existentes para criarem o personagem do novo jogador.
func _on_novo_peer_conectado(novo_id: int):
	adicionar_jogador_em_todos.rpc(novo_id)    # RPC para todos instanciarem o personagem do novo jogador

# RPC que só o servidor pode chamar, mas também executa localmente.
# Garante que todos os peers (incluindo o servidor) instanciem o personagem do jogador indicado.
@rpc("authority", "call_local", "reliable")
func adicionar_jogador_em_todos(id: int):
	adicionar_jogador(id)    # Chama a função local de instanciação para o ID recebido

# RPC chamado por um cliente recém-chegado diretamente para o servidor (rpc_id(1)).
# O servidor responde enviando os dados de todos os jogadores que já estavam na cena.
@rpc("any_peer", "reliable")
func pedir_spawn_existentes():
	var novo_id = multiplayer.get_remote_sender_id()           # ID do cliente que fez a requisição
	adicionar_jogador_em_todos.rpc(novo_id)                    # Informa todos sobre o novo cliente
	for filho in $UnitsContainer.get_children():               # Itera todos os personagens já na cena
		var id_existente = int(filho.name)                     # O nome do nó é o ID do jogador
		if id_existente != novo_id:                            # Evita re-enviar o próprio jogador novo
			adicionar_jogador_em_todos.rpc_id(novo_id, id_existente) # Envia cada jogador existente só para o recém-chegado

# Instancia e configura o personagem de um jogador específico nesta máquina.
func adicionar_jogador(id: int):
	# Evita duplicatas: verifica se já existe um nó com esse ID no container
	if $UnitsContainer.get_node_or_null(str(id)) != null:
		return

	var heroi = unit_scene.instantiate()       # Cria uma instância da cena do personagem
	heroi.name = str(id)                       # Nomeia o nó com o ID do jogador para facilitar buscas
	heroi.set_multiplayer_authority(id)        # Define quem tem autoridade sobre este nó (quem pode mover, etc.)

	# Determina a posição de spawn com base na quantidade de jogadores já presentes
	var index = $UnitsContainer.get_child_count()              # Conta quantos jogadores já estão na cena
	var tile = spawn_slots[index % spawn_slots.size()]         # Escolhe o slot ciclicamente (evita índice fora do range)
	heroi.global_position = tilemap.map_to_local(tile)         # Converte a coordenada de tile para posição no mundo

	$UnitsContainer.add_child(heroi, true)     # Adiciona o herói ao container; "true" garante que o nome seja único na rede

	# Busca o personagem escolhido por este jogador; usa o primeiro personagem como fallback
	var chave = Global.escolhas_multiplayer.get(id, Global.characters_data.keys()[0])
	if Global.characters_data.has(chave):
		heroi.setup(Global.characters_data[chave])             # Configura o herói com os dados do personagem escolhido
	else:
		heroi.setup(Global.characters_data[Global.characters_data.keys()[0]]) # Fallback para o primeiro personagem disponível

	# Se este herói pertence ao jogador local, conecta a câmera a ele
	if id == multiplayer.get_unique_id():
		_conectar_camera_ao_heroi(heroi)

# Remove o personagem de um jogador que desconectou.
func remover_jogador(id: int):
	var heroi = $UnitsContainer.get_node_or_null(str(id))  # Busca o nó pelo ID
	if heroi:
		heroi.queue_free()    # Remove o nó da cena de forma segura (na próxima frame)

# Faz a câmera seguir o herói local usando um RemoteTransform2D.
# RemoteTransform2D é um nó que transmite sua posição para outro nó remoto (a câmera).
func _conectar_camera_ao_heroi(alvo: Node):
	var remote = RemoteTransform2D.new()           # Cria o nó de transformação remota
	remote.name = "CameraRemote"                   # Nomeia para facilitar debugs
	remote.remote_path = camera.get_path()         # Define a câmera como destino das transformações
	alvo.add_child(remote)                         # Anexa o RemoteTransform2D ao herói local
	camera.global_position = alvo.global_position  # Teleporta a câmera imediatamente para o herói (evita transição brusca)
	camera.enabled = true                          # Ativa a câmera (pode estar desabilitada por padrão)
