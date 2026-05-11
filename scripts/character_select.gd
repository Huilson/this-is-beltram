extends CanvasLayer

# Referência para o botão de confirmar (arraste o nó para cá segurando CTRL)
@onready var confirm_button = $VBoxContainer/ConfirmButton 
@onready var label_status = $VBoxContainer/Label
@onready var lineEdit = $VBoxContainer/LineEdit

func _ready():
	# Começamos com o botão de confirmar desativado
	if confirm_button:
		confirm_button.disabled = true
	
	# Seus botões manuais já estão na cena, agora vamos garantir
	# que o Global saiba que nada foi escolhido ainda.
	Global.selected_char_key = ""

# Esta função será chamada por TODOS os botões de personagem
# O "extra_arg" é o nome da chave que definiremos no Editor (ex: "char_0")
func _on_personagem_clicado(chave: String):
	Global.selected_char_key = chave
	
	# Pega o nome do personagem no nosso dicionário Global
	var nome = Global.characters_data[chave].name
	label_status.text = "Selecionado: " + nome
	confirm_button.disabled = false
	
	print("Personagem pronto para o mapa: ", nome)

# Função para o botão de Confirmar
func _on_confirm_button_pressed():
	if Global.selected_char_key == "":
		print("Erro: Selecione um personagem!")
		return
		
	if multiplayer.multiplayer_peer == null:
		print("Erro: Você precisa Criar Host ou Entrar em um primeiro!")
		return

	# Avisa o servidor sobre a escolha
	var meu_id = multiplayer.get_unique_id()
	registrar_escolha_no_servidor.rpc(meu_id, Global.selected_char_key)
	
	# Vai para o mapa
	get_tree().change_scene_to_file("res://scenes/map_scene.tscn")

# 2. BOTÃO HOST (CONECTE NO SINAL 'PRESSED' DO SEU BOTÃO HOST)
func _on_btn_host_pressed():
	NetworkManager.criar_host()
	# Como host, você já está conectado. Pode liberar o botão confirmar.
	print("Host criado. Aguardando jogadores...")

func _on_btn_join_pressed():
	NetworkManager.entrar_no_host(lineEdit.text)
	print("Tentando conectar...")
	
#LÓGICA DE REDE (RPC)
@rpc("any_peer", "call_local")
func registrar_escolha_no_servidor(id_jogador, chave_personagem):
	# Esta parte roda no Servidor para organizar quem é quem
	Global.escolhas_multiplayer[id_jogador] = chave_personagem
	print("Jogador ", id_jogador, " registrado como ", chave_personagem)
