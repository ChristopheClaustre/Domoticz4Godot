extends Device
class_name ColorSwitch


static func get_class_name():
	return "ColorSwitch"
func get_class():
	return get_class_name()


var color : DzColor
var status : String = ""


func _internal_init(device_info, dz_main_node):
	._internal_init(device_info, dz_main_node)
	status = device_info["Status"]
	if device_info.has("Color") and not device_info["Color"].empty():
		color = DzColor.new(parse_json(device_info["Color"]))
	else:
		color = DzColor.new()


func switch_on():
	status = "Off"
	dzMainNode.request_switchlight(idx, "On")


func switch_off():
	status = "Off"
	dzMainNode.request_switchlight(idx, "Off")


func switch_toggle():
	status = "Off" if status == "On" else "On"
	dzMainNode.request_switchlight(idx, "Toggle")


func _to_string():
	return get_class() + ": " + name + "," + str(idx)
