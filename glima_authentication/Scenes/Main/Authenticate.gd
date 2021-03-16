extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1911
var max_servers = 5


func _ready():
	start_server()


func start_server():
	network.create_server(port, max_servers)
	get_tree().set_network_peer(network)
	print("Authentication server started on port: ", port)

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")


func _on_peer_connected(gateway_id):
	print("Gateway " + str(gateway_id) + " connected")


func _on_peer_disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " disconnected")


remote func authenticate_player(username, password, player_id):
	print("authentication request recieved for user: ", username)
	var token
	var gateway_id = get_tree().get_rpc_sender_id()
	var result
	var hashed_password
	print("Starting authentication")
	if not PlayerData.player_data.has(username):
		print("No user named: ", username)
		result = false
	else:
		hashed_password = generate_hashed_password(password, PlayerData.player_data[username].salt)
		if not PlayerData.player_data[username].password == hashed_password:
			print("Incorrect password for user: ", username)
			result = false
		else:
			print("Succesful login for user: ", username)
			result = true

			randomize()
			token = str(randi()).sha256_text() + str(OS.get_unix_time())
			var gameserver = "gameserver1"
			GameServer.distribute_login_token(token, gameserver)

	print("Authentication result sent to gateway server")
	rpc_id(gateway_id, "authentication_result", result, player_id, token)

remote func create_account(username, password, player_id):
	var gateway_id = get_tree().get_rpc_sender_id()
	var result
	var message
	if PlayerData.player_data.has(username):
		result = false
		message = 2
	else:
		result = true
		message = 3
		var salt = generate_salt()
		var hashed_password = generate_hashed_password(password, salt)
		PlayerData.player_data[username] = {"password": hashed_password, "salt": salt}
		PlayerData.save_player_data()

	rpc_id(gateway_id, "create_account_result", result, player_id, message)


func generate_salt():
	randomize()
	var salt = str(randi()).sha256_text()
	return salt


func generate_hashed_password(password, salt):
	var hashed_password = password
	# Make the hashing slow
	var rounds = pow(2, 18)
	while rounds > 0:
		hashed_password = (hashed_password + salt).sha256_text()
		rounds -= 1
	return hashed_password
