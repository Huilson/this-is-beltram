# res://scripts/Global.gd
extends Node

# Um dicionário para guardar as informações dos personagens
# Você pode expandir isso com status, habilidades, etc.
var characters_data = {
	"char_0": {
		"name": "Cleriga",
		"portrait": "res://sprites/portraits/cleric(f).png", # Caminho da imagem
		"sprite_sheet": "res://sprites/cleric_female.png",
		"offset_frame": 50,
		"class": "Cleric"
	},
	"char_1": {
		"name": "Clerigo",
		"portrait": "res:/sprites/portraits/cleric(m)",
		"sprite_sheet": "res://sprites/cleric_male.png",
		"offset_frame": 0,
		"class": "Cleric"
	},
	# Adicione os outros 6 personagens aqui da mesma forma
	"char_2": {
		"name": "Arqueira",
		"portrait": "res://sprites/portraits/ranger(f).png",
		"sprite_sheet": "res://sprites/ranger_female.png",
		"offset_frame": 50,
		"class": "Archer"
	},
	"char_3": {
		"name": "Arqueiro",
		"portrait": "res://sprites/portraits/ranger(m).png",
		"sprite_sheet": "res://sprites/ranger_male.png",
		"offset_frame": 0,
		"class": "Archer"
	},
	"char_4": {
		"name": "Guerreira",
		"portrait": "res://sprites/portraits/warrior(f).png",
		"sprite_sheet": "res://sprites/warrior_female.png",
		"offset_frame": 50,
		"class": "Warrior"
	},
	"char_5": {
		"name": "Guerreiro",
		"portrait": "res://sprites/portraits/warrior(m).png",
		"sprite_sheet": "res://sprites/warrior_male.png",
		"offset_frame": 0,
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

# Ele vai guardar quem é quem na rede. Ex: {1: "mago_homem", 58392: "mago_mulher"}
var escolhas_multiplayer: Dictionary = {}

# Variável para guardar o personagem selecionado no momento
var selected_char_key = ""
