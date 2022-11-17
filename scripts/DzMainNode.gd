extends Node
class_name DzMainNode

# signal 4 errors
signal timeout_error(status)
signal configuration_error(err)
signal connection_error(status)
signal request_error(err)
signal requesting_error(status)
# signal 4 answers
signal switchlight_error(body)
signal devices_list_retrieved(devices)


export var host = "127.0.0.1" setget _set_host
export(int, -1, 65535) var port = -1 setget _set_port
export var use_ssl = false setget _set_use_ssl
export var verify_host = true setget _set_verify_host
export var username_encoded = "" setget _set_username_encoded
export var password_encoded = "" setget _set_password_encoded


onready var _client := DzClient.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	_client.host = host
	_client.port = port
	_client.use_ssl = use_ssl
	_client.verify_host = verify_host
	_client.username_encoded = username_encoded
	_client.password_encoded = password_encoded


# setter on DzClient attributes
func _set_host(value):
	host = value
	_client.host = host
func _set_port(value):
	port = value
	_client.port = port
func _set_use_ssl(value):
	use_ssl = value
	_client.use_ssl = use_ssl
func _set_verify_host(value):
	verify_host = value
	_client.verify_host = verify_host
func _set_username_encoded(value):
	username_encoded = value
	_client.username_encoded = username_encoded
func _set_password_encoded(value):
	password_encoded = value
	_client.password_encoded = password_encoded


# connect to the signal devices_list_retrieved to have the answer of your request
func request_devices_list(plan = -1):
	_request_in_progress = _request_devices_list_coroutine(plan)


func request_switchlight(idx : int, switch_cmd : String, other_params = {}):
	_request_in_progress = _request_switchlight_coroutine(idx, switch_cmd, other_params)


func _request_devices_list_coroutine(plan = -1):
	var _request_body := {"type" : "devices"}
	if plan != -1:
		_request_body.merge({"plan" : plan })
	yield(_request_post_coroutine(_request_body), "completed")

	if not _client._last_body_received.empty():
		var _bodyJSON = JSON.parse(_client._last_body_received)
		assert(_bodyJSON.result is Dictionary)
		assert(_bodyJSON.result.has("result"))
		var _devicesJSON = _bodyJSON.result["result"]
		var _devices_retrieved := []
		for _deviceJSON in _devicesJSON:
			var _device = DeviceFactory.createDevice(_deviceJSON, self)
			if _device != null:
				_devices_retrieved.push_back(_device)
		emit_signal("devices_list_retrieved", _devices_retrieved)


func _request_switchlight_coroutine(idx : int, switch_cmd : String, other_params = {}):
	var body = {
		"type" : "command",
		"param" : "switchlight",
		"idx" : str(idx),
		"switchcmd" : switch_cmd
	}
	body.merge(other_params)
	yield(_request_post_coroutine(body), "completed")

	if not _client._last_body_received.empty():
		var _bodyJSON = JSON.parse(_client._last_body_received)
		assert(_bodyJSON.result is Dictionary)
		if not _bodyJSON.result.has("status") or _bodyJSON.result["status"] == "OK":
			emit_signal("switchlight_error", body)


var _request_in_progress = null
func _request_post_coroutine(body):
	yield(get_tree(), "idle_frame") # wait one frame just to always return a coroutine object
	# ask for connection
	var err = _client.connect_to_domoticz(true)
	if err != OK:
		emit_signal("configuration_error", err)
		close_connection()
		return

	# check connection
	var _connected = yield(_check_status_coroutine(HTTPClient.STATUS_CONNECTED, [HTTPClient.STATUS_RESOLVING,HTTPClient.STATUS_CONNECTING], "connection_error"), "completed")
	if not _connected:
		close_connection()
		return

	# connected now we can send the body
	err = _client.request_post(body)
	if err != OK:
		emit_signal("request_error", err)
		close_connection()
		return

	# waiting for answer
	var _answered = yield(_check_status_coroutine(HTTPClient.STATUS_BODY, [HTTPClient.STATUS_REQUESTING], "requesting_error"), "completed")
	if not _answered:
		close_connection()
		return

	# answered
	close_connection()
	return


func close_connection():
	_client.close_connection()
	_request_in_progress = null # clean _request_in_progress


func _check_status_coroutine(wanted_status : int, allowed_status : Array, error_signal : String):
	var _checked = false
	var _started := Time.get_ticks_msec()
	while not _checked:
		_client.polling()
		if Time.get_ticks_msec() - _started < 10000:
			if _client._last_status == wanted_status:
				_checked = true
			elif allowed_status.find(_client._last_status) != -1:
				yield(get_tree(), "idle_frame") # wait one frame
			else:
				emit_signal("connection_error", _client._last_status)
				break
		else:
			emit_signal("timeout_error", _client._last_status)
			break
	return _checked
