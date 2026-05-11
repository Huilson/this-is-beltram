extends Node2D

@onready var tilemap = $TileMapLayer
@onready var units_container = $UnitsContainer
@onready var camera = $Camera2D

# Carrega a cena do boneco que tem o AnimationPlayer
var unit_scene = preload("res://scenes/unit.tscn")
var spawn_pos = Vector2i(6, 6) 

func _ready():
	if Global.selected_char_key == "":
		return
	
# Apenas o servidor gerencia conexões e instâncias
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(adicionar_jogador)
		multiplayer.peer_disconnected.connect(remover_jogador)
		
		# Adiciona o host (você)
		adicionar_jogador(1)
		
	#_instanciar_heroi()

func adicionar_jogador(id):
	var heroi = unit_scene.instantiate()
	
	# 1. Configurações de Identidade
	heroi.name = str(id)
	heroi.set_multiplayer_authority(id)
	
	# 2. Define a posição ANTES de adicionar à árvore
	# Converte a coordenada do tile (6,6) para pixels
	var posicao_spawn = tilemap.map_to_local(Vector2i(6, 6))
	heroi.global_position = posicao_spawn
	
	# 3. Adiciona ao container (isso dispara o spawn na rede)
	$UnitsContainer.add_child(heroi, true)
	
	# 4. Busca os dados de escolha salvos no Global
	var chave = Global.escolhas_multiplayer.get(id, "mago_homem")
	var dados = Global.characters_data[chave]
	heroi.setup(dados)
	
	# 5. Se este herói for o MEU, a câmera deve segui-lo
	if id == multiplayer.get_unique_id():
		_conectar_camera_ao_heroi(heroi)

func remover_jogador(id):
	var heroi = $UnitsContainer.get_node_or_null(str(id))
	if heroi: heroi.queue_free()

func _conectar_camera_ao_heroi(alvo):
	# Se você já tiver uma Camera2D na cena do mapa:
	var camera = $Camera2D 
	
	# Usamos um RemoteTransform2D para a câmera seguir o herói sem estar "dentro" dele
	var remote = RemoteTransform2D.new()
	remote.name = "CameraRemote"
	remote.remote_path = camera.get_path() # Diz para o herói: "Leve a câmera com você"
	alvo.add_child(remote)
	
	# Garante que a câmera pule imediatamente para o herói
	camera.global_position = alvo.global_position
