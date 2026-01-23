@tool
extends Node

@export var compute_node: HorizonComputer # Link to the node above
@export var Heightmap: Texture2D
var heightmapImage : Image

@onready var sibling = $"../BakeHorizonMap"

var memorizedLightPositions : Array[Vector3] = []

func _ready() -> void:
	memorizedLightPositions.resize(4)
	heightmapImage = Heightmap.get_image()
	if heightmapImage.is_compressed() :
		heightmapImage.decompress()
	if heightmapImage.has_mipmaps() :
		heightmapImage.clear_mipmaps()
		
	while (is_inside_tree()) :
		await get_tree().process_frame
		iterateViewers()

func updateTank(position : Vector2,id : int,height : float) :
	# stride means height above ground, it is named well truss
	var settings = {
		"origin": position,
		"scale": 60.0,
		"stride": height
	}
	RenderingServer.global_shader_parameter_set("tankPos" + str(id), position)
	sibling.run_compute(heightmapImage, settings, "Horizon", (id))

func iterateViewers() -> void :
	if not is_inside_tree() :
		return
	var sightseers = get_tree().get_nodes_in_group("Viewers")
	var index : int = 0
	for seeker : Node3D in sightseers :
		if not is_inside_tree() :
			return
		if index > memorizedLightPositions.size() :
			memorizedLightPositions.resize(index + 1)
			sibling.layer_count = index + 1
			RenderingServer.global_shader_parameter_set("horizonLayerCount", index + 1.0)
		var oldPosition = memorizedLightPositions[index]
		#print(seeker)
		if seeker.global_position != oldPosition :
			#print("seeking")
			memorizedLightPositions[index] = seeker.global_position
			updateTank(Vector2(memorizedLightPositions[index].x,memorizedLightPositions[index].z),index,memorizedLightPositions[index].y)
			await get_tree().process_frame
		index += 1
	#updateTank(Vector2(1024,1535),0)
