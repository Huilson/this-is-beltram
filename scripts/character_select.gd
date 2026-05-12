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
		print("Selecione um personagem!")
		return
		
	if multiplayer.multiplayer_peer == null:
		print("Você não está conectado a nenhuma rede!")
		return

	# Primeiro: Avisa o servidor quem você escolheu
	var meu_id = multiplayer.get_unique_id()
	registrar_escolha_no_servidor.rpc(meu_id, Global.selected_char_key)
	
	# Segundo: Se você for o Host, manda todo mundo mudar de cena
	if multiplayer.is_server():
		# Damos um pequeno tempo (0.1s) para o RPC da escolha chegar antes da troca de cena
		await get_tree().create_timer(0.1).timeout
		mudar_cena_para_todos.rpc("res://scenes/map_scene.tscn")
	else:
		print("Aguardando o Host iniciar a partida...")

# 5. COMUNICAÇÃO RPC
@rpc("any_peer", "call_local", "reliable")
func registrar_escolha_no_servidor(id_jogador, chave_personagem):
	Global.escolhas_multiplayer[id_jogador] = chave_personagem
	print("Registro: Jogador ", id_jogador, " escolheu ", chave_personagem)

@rpc("authority", "call_local", "reliable")
func mudar_cena_para_todos(caminho_da_cena: String):
	print("Mudando de cena para: ", caminho_da_cena)
	get_tree().change_scene_to_file(caminho_da_cena)

#BOTÃO HOST (CONECTE NO SINAL 'PRESSED' DO SEU BOTÃO HOST)
func _on_btn_host_pressed():
	NetworkManager.criar_host()
	var ip = NetworkManager.obter_meu_ip()
	print("Servidor Iniciado! Seu IP: ", ip)
	lineEdit.text = "IP para conexão: " + ip

#BOTÃO DE JOIN
func _on_btn_join_pressed():
# Substitua pelo IP do Host ou use um LineEdit: $IPEdit.text
	NetworkManager.entrar_no_host(lineEdit.text)
	print("Tentando conectar ao servidor...")
