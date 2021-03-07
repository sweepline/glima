extends Node

var spell_data
var spell_by_id


func _ready():
	var spell_data_file = File.new()
	spell_data_file.open("res://Data/Skills.json", File.READ)
	var spell_data_json = JSON.parse(spell_data_file.get_as_text())
	spell_data_file.close()
	spell_data = spell_data_json.result
	spell_by_id = {}
	for spell_name in spell_data.keys():
		var spell = spell_data[spell_name]
		spell_by_id[spell.id] = spell
		spell_by_id[spell.id].name = spell_name
