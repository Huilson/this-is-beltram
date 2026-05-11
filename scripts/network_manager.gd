extends Node

const PORT = 7000
const DEFAULT_IP = "127.0.0.1" # IP local para testes

func criar_host():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Erro ao criar servidor: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Servidor iniciado na porta ", PORT)

func entrar_no_host(ip = DEFAULT_IP):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Erro ao conectar: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Conectando ao servidor...")
