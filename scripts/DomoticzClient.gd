extends Resource
class_name DomoticzClient


signal polling_error(error)
signal new_status(status)
signal body_received(bodyType, message)
signal unexpected_body_received(message)
signal devices_list_retrieved(devices)
signal switchlight_error(body)


const _url = "/json.htm"


var host = "127.0.0.1"
var port = -1
var use_ssl = false
var verify_host = true
var username_encoded = ""
var password_encoded = ""


enum BodyType {
	eNone = 0,
	eBodyDevices,
	eBodySwitchLight,
	eNbBodyType
}


var _client : HTTPClient = null
var _last_body_received := ""
var _last_status = HTTPClient.STATUS_DISCONNECTED
var _last_devices_retrieved : Array = []

var _waitingForBodyType = BodyType.eNone


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_received", self, "_on_body_received")
	connect("new_status", self, "_on_new_status")
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
	var err = request_post({"type" : "devices"})
	if err == OK:
		_waitingForBodyType = BodyType.eBodyDevices
	return err


func request_switchlight(idx : int, switch_cmd : String, other_params = {}):
	var body = {
		"type" : "command",
		"param" : "switchlight",
		"idx" : str(idx),
		"switchcmd" : switch_cmd
	}
	body.merge(other_params)
	
	var err = request_post(body)
	if err == OK:
		_waitingForBodyType = BodyType.eBodySwitchLight
	return err


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


func request_post(body) -> int:
	if not _client:
		var err = connect_to_domoticz(true)
		if err != OK:
			return err
	
	if _waitingForBodyType != BodyType.eNone:
		return ERR_ALREADY_IN_USE
	var body_str = _client.query_string_from_dict(body)
	var query_string = _client.query_string_from_dict({"username" : username_encoded, "password" : password_encoded})
	var headers =  ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(body_str.length())]
	var err = _client.request(HTTPClient.METHOD_POST, _url + "?" + query_string, headers, body_str)
	return err


func polling() -> int:
	if not _client:
		return ERR_CONNECTION_ERROR

	# polling
	var err = _client.poll()
	if err != OK:
		emit_signal("polling_error", err)
		close_connection()
		return err

	# check if status has changed
	var status = _client.get_status()
	if status != _last_status:
		_last_status = status
		_new_status(_last_status)

	return OK


func _new_status(status):
	emit_signal("new_status", status)
	if status == HTTPClient.STATUS_BODY:
		var body = _client.read_response_body_chunk()
		while _client.has_response() and _client.get_status() == HTTPClient.STATUS_BODY:
			body.append_array(_client.read_response_body_chunk())
		_last_body_received = body.get_string_from_utf8()

		if _waitingForBodyType == BodyType.eNone:
			emit_signal("unexpected_body_received", _last_body_received)
		else:
			_body_received(_waitingForBodyType, _last_body_received)
		_waitingForBodyType = BodyType.eNone


func _body_received(bodyType, body):
	emit_signal("body_received", bodyType, body)
	var _bodyJSON = JSON.parse(body)
	assert(_bodyJSON.result is Dictionary)
	if bodyType == BodyType.eBodyDevices:
		assert(_bodyJSON.result.has("result"))
		var _devicesJSON = _bodyJSON.result["result"]
		_last_devices_retrieved.clear()
		for _deviceJSON in _devicesJSON:
			_last_devices_retrieved.push_back(DeviceFactory.createDevice(_deviceJSON, self))
		emit_signal("devices_list_retrieved", _last_devices_retrieved)
	elif bodyType == BodyType.eBodySwitchLight:
		if _bodyJSON.result.has("status") and _bodyJSON.result["status"] == "OK":
			emit_signal("switchlight_error", body)
	else:
		pass # @TODO
