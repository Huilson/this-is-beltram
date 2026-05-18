# res://scripts/character_select.gd
# Controla a tela de seleção de personagens.
# Gerencia a escolha local, a confirmação e a sincronização via RPC com os outros jogadores,
# além de permitir criar ou entrar em um servidor multiplayer.
extends CanvasLayer

# Referências aos nós da interface, obtidas automaticamente quando a cena estiver pronta.
@onready var confirm_button = $VBoxContainer/ConfirmButton  # Botão de confirmação da escolha
@onready var label_status = $VBoxContainer/Label            # Label que exibe o personagem selecionado ou mensagens de status
@onready var lineEdit = $VBoxContainer/LineEdit             # Campo de texto para digitar o IP do servidor

# Chamado quando a cena é carregada.
func _ready():
	if confirm_button:
		confirm_button.disabled = true     # Garante que o botão de confirmar começa desativado (nenhum personagem escolhido ainda)
	Global.selected_char_key = ""          # Reseta qualquer seleção anterior ao entrar nesta tela

# Chamado quando o jogador clica em um personagem na tela de seleção.
# Recebe a chave do personagem clicado (ex: "char_2").
func _on_personagem_clicado(chave: String):
	Global.selected_char_key = chave                              # Salva globalmente o personagem escolhido
	var nome = Global.characters_data[chave].name                 # Busca o nome do personagem nos dados globais
	label_status.text = "Selecionado: " + nome                    # Atualiza a label com o nome do personagem
	confirm_button.disabled = false                               # Habilita o botão de confirmar
	print("Personagem pronto para o mapa: ", nome)

# Chamado ao pressionar o botão "Confirmar" para entrar no mapa.
func _on_confirm_button_pressed():
	# Valida se um personagem foi de fato selecionado
	if Global.selected_char_key == "":
		print("Selecione um personagem!")
		return

	# Valida se o jogador está conectado a uma rede antes de prosseguir
	if multiplayer.multiplayer_peer == null:
		print("Você não está conectado a nenhuma rede!")
		return

	var meu_id = multiplayer.get_unique_id()   # Obtém o ID único deste jogador na rede

	# Envia via RPC para todos (servidor e clientes) o registro da escolha deste jogador
	registrar_escolha_no_servidor.rpc(meu_id, Global.selected_char_key)

	# Somente o host tem autoridade para mudar a cena para todos os jogadores
	if multiplayer.is_server():
		await get_tree().create_timer(0.2).timeout             # Pequena espera para garantir que o RPC acima foi recebido por todos
		mudar_cena_para_todos.rpc("res://scenes/map_scene.tscn") # Ordena a troca de cena para todos os peers
	else:
		# Clientes ficam aguardando — apenas o host inicia a partida
		label_status.text = "Aguardando o Host iniciar a partida..."
		confirm_button.disabled = true   # Desativa o botão para evitar envios duplicados
		print("Aguardando o Host iniciar a partida...")

# RPC confiável que pode ser chamado por qualquer peer e também executa localmente.
# Registra no dicionário global qual personagem cada jogador escolheu.
@rpc("any_peer", "call_local", "reliable")
func registrar_escolha_no_servidor(id_jogador: int, chave_personagem: String):
	Global.escolhas_multiplayer[id_jogador] = chave_personagem   # Mapeia o ID do jogador à chave do personagem escolhido
	print("Registro: Jogador ", id_jogador, " escolheu ", chave_personagem)

# RPC confiável que só pode ser chamado pelo servidor (authority) e também executa localmente.
# Força todos os jogadores a trocar de cena simultaneamente.
@rpc("authority", "call_local", "reliable")
func mudar_cena_para_todos(caminho_da_cena: String):
	print("Mudando de cena para: ", caminho_da_cena)
	get_tree().change_scene_to_file(caminho_da_cena)   # Troca a cena atual pela cena do mapa

# Chamado ao pressionar o botão "Host" — cria um servidor e exibe o IP local.
func _on_btn_host_pressed():
	NetworkManager.criar_host()                        # Inicia o servidor via NetworkManager
	var ip = NetworkManager.obter_meu_ip()             # Obtém o IP local desta máquina
	print("Servidor Iniciado! Seu IP: ", ip)
	lineEdit.text = ip                                 # Exibe o IP no campo de texto para facilitar o compartilhamento

# Chamado ao pressionar o botão "Entrar" — conecta ao servidor cujo IP está no campo de texto.
func _on_btn_join_pressed():
	NetworkManager.entrar_no_host(lineEdit.text)       # Usa o IP digitado para conectar ao servidor
	print("Tentando conectar ao servidor...")
