# res://scripts/network_manager.gd
# Gerencia a criação do servidor (host) e a conexão de clientes via protocolo ENet.
# Deve ser adicionado como Autoload para ser acessível globalmente (ex: NetworkManager).
extends Node

# Porta de rede usada para o servidor e para os clientes se conectarem.
const PORT = 7000

# IP padrão usado quando nenhum endereço é fornecido — útil para testes locais.
const DEFAULT_IP = "127.0.0.1"

# Cria e inicia um servidor ENet nesta máquina.
# Chamado pelo jogador que quer hospedar a partida.
func criar_host():
	var peer = ENetMultiplayerPeer.new()          # Cria um novo peer ENet (camada de rede)
	var error = peer.create_server(PORT)           # Tenta abrir o servidor na porta definida
	if error != OK:                                # Se houver falha, exibe o erro e encerra a função
		print("Erro ao criar servidor: ", error)
		return
	multiplayer.multiplayer_peer = peer            # Registra o peer como a conexão ativa do multiplayer
	print("Servidor iniciado na porta ", PORT)

# Conecta este cliente a um servidor existente no IP informado.
# Chamado pelo jogador que quer entrar em uma partida já criada.
func entrar_no_host(ip = DEFAULT_IP):
	var peer = ENetMultiplayerPeer.new()          # Cria um novo peer ENet para a conexão cliente
	var error = peer.create_client(ip, PORT)       # Tenta conectar ao IP e porta informados
	if error != OK:                                # Se houver falha, exibe o erro e encerra a função
		print("Erro ao conectar: ", error)
		return
	multiplayer.multiplayer_peer = peer            # Registra o peer como a conexão ativa do multiplayer
	print("Conectando ao servidor...")

# Retorna o endereço IPv4 local desta máquina (o IP que outros jogadores usarão para se conectar).
func obter_meu_ip() -> String:
	var ips = IP.get_local_addresses()             # Obtém todos os endereços de rede da máquina
	for ip in ips:
		# Filtra: ignora IPv6 (contêm ":"), o loopback (127.0.0.1) e IPs de link-local (169.x.x.x)
		if ":" not in ip and ip != "127.0.0.1" and not ip.begins_with("169"):
			return ip                              # Retorna o primeiro IPv4 válido encontrado
	return "127.0.0.1"                             # Fallback: retorna loopback se nenhum IP válido for achado
