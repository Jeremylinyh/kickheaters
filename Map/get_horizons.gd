@tool
extends Node

@export var compute_node: HorizonComputer # Link to the node above
@export var Heightmap: Texture2D
var heightmapImage : Image

@onready var sibling = $"../BakeHorizonMap"

func _ready() -> void:
	heightmapImage = Heightmap.get_image()
	if heightmapImage.is_compressed() :
		heightmapImage.decompress()
	if heightmapImage.has_mipmaps() :
		heightmapImage.clear_mipmaps()

func _process(_delta):
	# Prepare your settings
	var settings = {
		"origin": Vector2(1024, 1024),
		"scale": 60.0,
		"stride": 1.0
	}
	
	sibling.run_compute(heightmapImage, settings, "Horizon0")
