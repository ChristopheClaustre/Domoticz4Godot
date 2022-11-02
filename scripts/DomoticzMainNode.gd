extends Node
class_name DomoticzMainNode

# signal 4 errors
signal configuration_error(err)
signal connection_error(status)
signal request_error(err)
signal requesting_error(status)
# signal 4 answer
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
	_client.host = host
	_client.port = port
	_client.use_ssl = use_ssl
	_client.verify_host = verify_host
	_client.username_encoded = username_encoded
	_client.password_encoded = password_encoded

	var err = _client.connect_to_domoticz()
	if err != OK:
		emit_signal("configuration_error", err)


# connect to the signal devices_list_retrieved to have the answer of your request
func request_devices_list():
	_request_in_progress = _request_devices_list_coroutine()


func request_switchlight(idx : int, switch_cmd : String, other_params = {}):
	_request_in_progress = _request_switchlight_coroutine(idx, switch_cmd, other_params)


func _request_devices_list_coroutine():
	yield(_request_post_coroutine({"type" : "devices"}), "completed")

	if not _client._last_body_received.empty():
		var _bodyJSON = JSON.parse(_client._last_body_received)
		assert(_bodyJSON.result is Dictionary)
		assert(_bodyJSON.result.has("result"))
		var _devicesJSON = _bodyJSON.result["result"]
		var _devices_retrieved := []
		for _deviceJSON in _devicesJSON:
			_devices_retrieved.push_back(DeviceFactory.createDevice(_deviceJSON, self))
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
	while not _checked:
		_client.polling()
		if _client._last_status == wanted_status:
			_checked = true
		elif allowed_status.find(_client._last_status) != -1:
			yield(get_tree(), "idle_frame") # wait one frame
		else:
			emit_signal("connection_error", _client._last_status)
			break
	return _checked
