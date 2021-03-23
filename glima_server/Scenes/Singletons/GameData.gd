extends Node

var spell_data
var spell_by_id
var server_config

var test_data = {"stats": {"kills": 12}}

func _ready():
	var spell_data_file = File.new()
	spell_data_file.open("res://Data/Skills.json", File.READ)
	var spell_data_json = JSON.parse(spell_data_file.get_as_text())
	spell_data_file.close()
	spell_data = spell_data_json.result
	spell_by_id = {}
	for spell_name in spell_data.keys():
		spell_data[spell_name].id = int(spell_data[spell_name].id)
		var spell = spell_data[spell_name]
		spell_by_id[spell.id] = spell
		spell_by_id[spell.id].name = spell_name

func get_server_config():
	var server_config_file = File.new()
	server_config_file.open("user://server_config.json", File.READ)
	var server_config_json = JSON.parse(server_config_file.get_as_text())
	server_config_file.close()
	server_config = server_config_json.result
