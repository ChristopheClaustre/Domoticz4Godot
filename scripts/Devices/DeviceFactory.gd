extends Object
class_name DeviceFactory


const cDeviceTypes = {
	"Color Switch": preload("res://addons/Domoticz4Godot/scripts/Devices/ColorSwitch.gd"),
	"Light/Switch": preload("res://addons/Domoticz4Godot/scripts/Devices/Switch.gd")
}
const cDefaultDeviceType = preload("res://addons/Domoticz4Godot/scripts/Devices/Device.gd")


static func createDevice(device_info, dzClient):
	var type = device_info["Type"]
	if device_info["Name"] == "Unknown":
		return null
	var deviceType = cDeviceTypes.get(type, cDefaultDeviceType)
	var device = deviceType.new()
	device._internal_init(device_info, dzClient)
	return device
