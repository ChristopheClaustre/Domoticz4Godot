extends Resource
class_name Device


static func get_class_name():
	return "Device"
func get_class():
	return get_class_name()


var name : String = ""
var idx : int = -1
var type : String = ""
var dzMainNode : Node = null


func _internal_init(device_info, dz_main_node):
	name = device_info["Name"]
	idx = str2var(device_info["idx"])
	type = device_info["Type"]
	dzMainNode = dz_main_node


func switch_stop():
	dzMainNode.request_switchlight(idx, "Stop")


func _to_string():
	return get_class() + ": " + name + "," + str(idx)
