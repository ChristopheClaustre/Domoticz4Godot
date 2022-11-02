extends Device
class_name ColorSwitch


static func get_class_name():
	return "ColorSwitch"
func get_class():
	return get_class_name()


var color : DzColor


func _internal_init(device_info, dzClient):
	._internal_init(device_info, dzClient)
	if device_info.has("Color") and not device_info["Color"].empty():
		color = DzColor.new(parse_json(device_info["Color"]))
	else:
		color = DzColor.new()
	pass


func switch_on():
	dzClient.request_switchlight(idx, "On")


func switch_off():
	dzClient.request_switchlight(idx, "Off")


func switch_toggle():
	dzClient.request_switchlight(idx, "Toggle")


func _to_string():
	return get_class() + ": " + name + "," + str(idx)
