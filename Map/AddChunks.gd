@tool
class_name TankTerrain
extends Heights
@export var terrainViewer : PackedScene
var heightmapImage : Texture2D
var tilesNeededEachDir : int = 4
const tileSize : float = 128.0;
var sideSize = tilesNeededEachDir * tileSize

#var bufferFloat : PackedFloat32Array 

func getHeightAt(input : Vector2) -> float :
	return get_height(int(position.x),int(position.y),0)

func getHeightBilinear(pos: Vector2) -> float:
	return get_height_interpolated(pos.x,pos.y,0)

## returns length the ray traveled.
func traceRay(origin : Vector3,direction : Vector3) :
	return cast_ray(origin,direction)

func createCrater(origin : Vector2,radius : int) :
	pass

func _ready() -> void:
	set_process_priority(100)
	
	heightmapImage = await $ComputeSimplex.generate_noise_texture(4096,4096)
	$BakeHorizonMap._initialize_gpu()
	$BakeHorizonMap._update_input_texture(heightmapImage.get_image())
	$GetHorizons.heightmapImage = heightmapImage.get_image()
	
	var bufferFloat : PackedFloat32Array = heightmapImage.get_image().get_data().to_float32_array()
	set_whole_map(bufferFloat)
	#var heightShape : HeightMapShape3D = $StaticBody3D/CollisionShape3D.shape
	#heightShape.map_depth = 4096
	#heightShape.map_width = 4096
	#heightShape.map_data = bufferFloat
	
	if Engine.is_editor_hint() :
		tilesNeededEachDir = 32
	RenderingServer.global_shader_parameter_set("heightMap", heightmapImage)
	
	for x in range(tilesNeededEachDir) :
		for y in range(tilesNeededEachDir) :
			var newTerrain : MeshInstance3D = terrainViewer.instantiate()
			self.add_child(newTerrain)
			if not Engine.is_editor_hint() :
				newTerrain.position = Vector3((x-tilesNeededEachDir/2) * tileSize,0,(y+1-tilesNeededEachDir/2)*tileSize)
			else :
				newTerrain.position = Vector3((x) * tileSize,0,(y+1)*tileSize)
			newTerrain.name = str(x) + "," + str(y)
			newTerrain.owner = null

func _process(delta: float) -> void:
	pass
