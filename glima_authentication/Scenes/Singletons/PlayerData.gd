extends Node

var player_data


func _ready():
	var player_data_file = File.new()
	player_data_file.open("res://Data/PlayerData.json", File.READ)
	var player_data_json = JSON.parse(player_data_file.get_as_text())
	player_data_file.close()
	player_data = player_data_json.result
