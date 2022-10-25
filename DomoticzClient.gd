extends Node
class_name DomoticzClient


export var host = "127.0.0.1"
export(int, -1, 65535) var port = -1
export var use_ssl = false
export var verify_host = true


var _client : HTTPClient = null


# Called when the node enters the scene tree for the first time.
func _ready():
	var err = connect_to_domoticz()
	if err != OK:
		push_warning("Problem with the configuration of DomoticzClient." +
			"Please modify parameter of your client and retry connection by calling connect_to_domoticz(true).")


func connect_to_domoticz(force := false):
	if _client:
		if not force:
			return OK
		_client.close()
		_client = null
	
	_client = HTTPClient.new()
	var err = _client.connect_to_host(host, port, use_ssl, verify_host)
	if err != OK:
		_client.close()
		_client = null
