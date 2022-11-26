extends Resource
class_name DzClient


const _url = "/json.htm"


var server_settings := DzServerSettings.new()


var _client : HTTPClient = null
var _last_body_received := ""
var _last_status = HTTPClient.STATUS_DISCONNECTED
var _last_devices_retrieved : Array = []


# Called when the node enters the scene tree for the first time.
func _ready():
	var err = connect_to_domoticz()
	if err != OK:
		push_warning("Problem with the configuration of DzClient." +
			"Please modify parameter of your client and retry connection by calling connect_to_domoticz(true).")


func _process(_delta):
	if not _client:
		return

	polling()


func connect_to_domoticz(force := false):
	if _client:
		if not force and _last_status != HTTPClient.STATUS_DISCONNECTED:
			return OK
		close_connection()

	_last_status = HTTPClient.STATUS_DISCONNECTED
	_last_body_received = ""

	_client = HTTPClient.new()
	var err = _client.connect_to_host(server_settings.host, server_settings.port, server_settings.use_ssl, server_settings.verify_host)
	if err != OK:
		close_connection()

	return err


func close_connection():
	if _client:
		_client.close()
		_client = null


func is_connected_to_domoticz():
	return _client == null or _last_status == HTTPClient.STATUS_DISCONNECTED


func request_post(body) -> int:
	if not _client:
		return ERR_CONNECTION_ERROR

	var body_str = _client.query_string_from_dict(body)
	var query_string = _client.query_string_from_dict({"username" : server_settings.username_encoded, "password" : server_settings.password_encoded})
	var headers =  ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body_str.length())]
	var err = _client.request(HTTPClient.METHOD_POST, _url + "?" + query_string, headers, body_str)
	return err


func polling() -> int:
	if not _client:
		return ERR_CONNECTION_ERROR

	# polling
	var err = _client.poll()

	# check if status has changed
	var status = _client.get_status()
	if status != _last_status:
		_last_status = status

	if status == HTTPClient.STATUS_BODY:
		var body = _client.read_response_body_chunk()
		while _client.has_response() and _client.get_status() == HTTPClient.STATUS_BODY:
			body.append_array(_client.read_response_body_chunk())
		_last_body_received = body.get_string_from_utf8()

	if err != OK:
		close_connection()
	return err
