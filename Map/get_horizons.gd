extends Node

func horizonLoop() :
	var heights : Image = $"..".heightmapImage.get_image()
	if heights.is_compressed() :
		heights.decompress()
	if heights.has_mipmaps() :
		heights.clear_mipmaps()
	while (true) :
		
		$"../BakeHorizonMap".dispatchCompute(heights,Vector2(128,128),60.0,1.0)
		for i in range(3) :
			await get_tree().process_frame
		var horizonMap : Image = $"../BakeHorizonMap".getComputeResult()

func _ready() -> void:
	horizonLoop()
