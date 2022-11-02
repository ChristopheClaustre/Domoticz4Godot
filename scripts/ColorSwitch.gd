extends Device
class_name ColorSwitch


static func get_class_name():
	return "ColorSwitch"
func get_class():
	return get_class_name()


var color : DzColor


func _internal_init(device_info):
	._internal_init(device_info)
	if device_info.has("Color") and not device_info["Color"].empty():
		color = DzColor.new(parse_json(device_info["Color"]))
	else:
		color = DzColor.new()
	pass


func _to_string():
	return get_class() + ": " + name + "," + str(idx)
