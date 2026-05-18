# res://scripts/Global.gd
extends Node
 
# Estatísticas de combate por classe.
# Todos os personagens de uma mesma classe compartilham esses valores.
# - max_hp:        vida máxima
# - damage:        dano causado por ataque
# - attack_range:  alcance do hitbox corpo a corpo em pixels (ignorado por projétil)
# - attack_type:   "melee" (corpo a corpo) ou "projectile" (dispara projétil)
var class_stats = {
	"Cleric": {
		"max_hp": 120,
		"damage": 18,
		"attack_range": 40.0,
		"attack_type": "melee"
	},
	"Warrior": {
		"max_hp": 150,
		"damage": 25,
		"attack_range": 45.0,
		"attack_type": "melee"
	},
	"Archer": {
		"max_hp": 90,
		"damage": 20,
		"attack_range": 0.0,
		"attack_type": "projectile"
	},
	"Wizard": {
		"max_hp": 80,
		"damage": 35,
		"attack_range": 0.0,
		"attack_type": "projectile"
	},
}

# Dicionário central com os dados de todos os personagens jogáveis.
# Cada entrada usa uma chave string ("char_0", "char_1", etc.) para identificar o personagem.
var characters_data = {
	"char_0": {
		"name": "Cleriga",                                    # Nome exibido na interface
		"portrait": "res://sprites/portraits/cleric(f).png", # Caminho do retrato (imagem de seleção)
		"sprite_sheet": "res://sprites/cleric_female.png",   # Spritesheet usada no mapa
		"class": "Cleric"                                     # Classe do personagem (pode ser usada para lógica futura)
	},
	"char_1": {
		"name": "Clerigo",
		"portrait": "res://sprites/portraits/cleric(m)",
		"sprite_sheet": "res://sprites/cleric_male.png",
		"class": "Cleric"
	},
	"char_2": {
		"name": "Arqueira",
		"portrait": "res://sprites/portraits/ranger(f).png",
		"sprite_sheet": "res://sprites/ranger_female.png",
		"class": "Archer"
	},
	"char_3": {
		"name": "Arqueiro",
		"portrait": "res://sprites/portraits/ranger(m).png",
		"sprite_sheet": "res://sprites/ranger_male.png",
		"class": "Archer"
	},
	"char_4": {
		"name": "Guerreira",
		"portrait": "res://sprites/portraits/warrior(f).png",
		"sprite_sheet": "res://sprites/warrior_female.png",
		"class": "Warrior"
	},
	"char_5": {
		"name": "Guerreiro",
		"portrait": "res://sprites/portraits/warrior(m).png",
		"sprite_sheet": "res://sprites/warrior_male.png",
		"class": "Warrior"
	},
	"char_6": {
		"name": "Maga",
		"portrait": "res://sprites/portraits/wizard(f).png",
		"sprite_sheet": "res://sprites/wizard_female.png",
		"class": "Wizard"
	},
	"char_7": {
		"name": "Mago",
		"portrait": "res://sprites/portraits/wizard(m).png",
		"sprite_sheet": "res://sprites/wizard_male.png",
		"class": "Wizard"
	},
}

# Dicionário usado durante o multiplayer para registrar qual personagem cada jogador escolheu.
# Formato: { id_do_jogador (int): chave_do_personagem (String) }
# Exemplo: { 1: "char_2", 58392: "char_5" }
var escolhas_multiplayer: Dictionary = {}

# Guarda temporariamente a chave do personagem selecionado na tela de seleção.
# É preenchida quando o jogador clica em um personagem e lida ao entrar no mapa.
var selected_char_key = ""
