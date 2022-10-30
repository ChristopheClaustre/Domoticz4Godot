extends Reference
class_name DomoticzClient


signal connected
signal polling_error(error)
signal new_status(status)
signal body_received(message)


var host = "127.0.0.1"
var port = -1
var use_ssl = false
var verify_host = true
var username_encoded = ""
var password_encoded = ""


var _last_body_received := ""


var _client : HTTPClient = null
var _url = "/json.htm"


# Called when the node enters the scene tree for the first time.
func _ready():
	var err = connect_to_domoticz()
	if err != OK:
		push_warning("Problem with the configuration of DomoticzClient." +
			"Please modify parameter of your client and retry connection by calling connect_to_domoticz(true).")


func _process(_delta):
	if not _client:
		return

	polling()


# connect to the signal devices_list_retrieved to have the answer of your request
func request_devices_list():
	if not _client:
		return
	
	request_post({"type" : "devices"})
	pass


func connect_to_domoticz(force := false):
	if _client:
		if not force:
			return OK
		close_connection()
	
	_client = HTTPClient.new()
	var err = _client.connect_to_host(host, port, use_ssl, verify_host)
	if err != OK:
		close_connection()
	
	return err


func close_connection():
	if _client:
		_client.close()
		_client = null
		_last_status = HTTPClient.STATUS_DISCONNECTED


func request_post(body) -> String:
	var body_str = _client.query_string_from_dict(body)
	var query_string = _client.query_string_from_dict({"username" : username_encoded, "password" : password_encoded})
	var headers =  ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body_str.length())]
	_client.request(HTTPClient.METHOD_POST, _url + "?" + query_string, headers, body_str)
	return ""


var _last_status = HTTPClient.STATUS_DISCONNECTED
func polling():
	if not _client:
		return
	
	var err = _client.poll()
	if err != OK:
		emit_signal("polling_error", err)
		close_connection()
		return

	# check if status has changed
	var status = _client.get_status()
	if status == _last_status:
		return
	_last_status = status

	if _last_status == HTTPClient.STATUS_CONNECTED:
		emit_signal("connected")
	elif _last_status == HTTPClient.STATUS_BODY:
		var body = _client.read_response_body_chunk()
		while _client.has_response() and _client.get_status() == HTTPClient.STATUS_BODY:
			body.append_array(_client.read_response_body_chunk())
		_last_body_received = body.get_string_from_utf8()
		emit_signal("body_received", _last_body_received)
	
	emit_signal("new_status", _last_status)
