@tool
extends Node

@export var compute_node: HorizonComputer # Link to the node above
@export var Heightmap: Texture2D
var heightmapImage : Image

@onready var sibling = $"../BakeHorizonMap"

var memorizedLightPositions : Array[Vector3] = []

func _ready() -> void:
	#memorizedLightPositions.resize(4)
	heightmapImage = Heightmap.get_image()
	if heightmapImage.is_compressed() :
		heightmapImage.decompress()
	if heightmapImage.has_mipmaps() :
		heightmapImage.clear_mipmaps()
	#sibling.update_input_texture(heightmapImage)
	
	while (is_inside_tree()) :
		await get_tree().process_frame
		iterateViewers()

func updateTank(heightmapImage : Image,position : Vector2,id : int,height : float,distance : float) :
	# stride means height above ground, it is named well truss
	var settings = {
		"origin": position,
		"scale": 60.0,
		"stride": height
	}
	RenderingServer.global_shader_parameter_set("tankPos" + str(id), position)
	sibling.run_compute(heightmapImage,settings, "Horizon", (id),distance)

var expectedCount = 0
func iterateViewers() -> void :
	if not is_inside_tree() :
		return
	var sightseers = get_tree().get_nodes_in_group("Viewers")
	var index : int = 0
	var arrayResized : bool = false
	if sightseers.size() != expectedCount :
		arrayResized = true
		expectedCount = sightseers.size()
		RenderingServer.global_shader_parameter_set("horizonLayerCount", expectedCount)
		memorizedLightPositions.resize(expectedCount)
		sibling.layer_count = 4
	
	for seeker : Node3D in sightseers :
		if not is_inside_tree() :
			return
		#if index >= memorizedLightPositions.size() :
			
		var oldPosition = memorizedLightPositions[index]
		#print(seeker)
		var forward_direction_3d: Vector3 = -seeker.global_transform.basis.z
		var facingAngle : float = atan2(forward_direction_3d.z,forward_direction_3d.x)
		RenderingServer.global_shader_parameter_set("tankFacing"+str(index), facingAngle)
		if seeker.global_position != oldPosition :
			#print("seeking")
			memorizedLightPositions[index] = seeker.global_position
			updateTank(
				heightmapImage,
				Vector2(memorizedLightPositions[index].x,memorizedLightPositions[index].z),
				index,
				memorizedLightPositions[index].y,
				1.0
			)
			if not arrayResized :
				await get_tree().process_frame
		index += 1
	#updateTank(Vector2(1024,1535),0)
