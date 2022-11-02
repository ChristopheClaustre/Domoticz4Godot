extends Node
class_name DomoticzMainNode


signal connected
signal devices_list_retrieved(devices)


export var host = "127.0.0.1"
export(int, -1, 65535) var port = -1
export var use_ssl = false
export var verify_host = true
export var username_encoded = ""
export var password_encoded = ""


onready var _client := DomoticzClient.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	_client.connect("polling_error", self, "_on_client_polling_error")
	_client.connect("new_status", self, "_on_client_new_status")
	_client.connect("devices_list_retrieved", self, "_on_client_devices_list_retrieved")

	_client.host = host
	_client.port = port
	_client.use_ssl = use_ssl
	_client.verify_host = verify_host
	_client.username_encoded = username_encoded
	_client.password_encoded = password_encoded

	var err = _client.connect_to_domoticz()
	if err != OK:
		push_warning("Problem with the configuration of DomoticzClient." +
			"Please modify parameter of your client and retry connection by calling connect_to_domoticz(true).")


func _process(_delta):
	_client.polling()


func request_devices_list():
	_client.request_devices_list()


func _on_client_polling_error(error):
	print_log("Polling failed. Connection must have been closed by server.", true)


func _on_client_new_status(status):
	if status == HTTPClient.STATUS_DISCONNECTED:
		print_log("Disconnected!")
	elif status == HTTPClient.STATUS_RESOLVING:
		print_log("Resolving...")
	elif status == HTTPClient.STATUS_CANT_RESOLVE:
		print_log("Can't resolve hostname. Check the given hostname.", true)
	elif status == HTTPClient.STATUS_CONNECTING:
		print_log("Connecting...")
	elif status == HTTPClient.STATUS_CANT_CONNECT:
		print_log("Can't connect to server. Check the settings of your client and your server.", true)
	elif status == HTTPClient.STATUS_CONNECTED:
		print_log("Connected!")
		emit_signal("connected")
	elif status == HTTPClient.STATUS_REQUESTING:
		print_log("Requesting...")
	elif status == HTTPClient.STATUS_BODY:
		print_log("New body received!")
	elif status == HTTPClient.STATUS_CONNECTION_ERROR:
		print_log("HTTP connection error. Check the settings of your client and your server. Check internet connection.", true)
	elif status == HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
		print_log("SSL handshake error. Is your server configured to accepts ssl connection (https) ?", true)
	else:
		print_log("Unknown status", true)


func _on_client_devices_list_retrieved(devices):
	emit_signal("devices_list_retrieved", devices)


func print_log(message : String, warning := false):
	var _message = "DOMOTICZPLUGIN: " + message
	if warning:
		push_warning(_message)
	else:
		print(_message)
