@tool
extends Node

func generate_noise_texture(width: int, height: int) -> Texture2D:
	# 1. Create a local rendering device to handle compute separate from the main loop
	var rd = RenderingServer.create_local_rendering_device()

	# Load your GLSL file
	var shader_file = load("res://Map/Generator/HeightGen.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader_rid = rd.shader_create_from_spirv(shader_spirv)

	# 2. Create the Output Texture (Must match r32f)
	var fmt = RDTextureFormat.new()
	fmt.width = width
	fmt.height = height
	# This specifically matches 'r32f' in GLSL
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT 
	# Usages: Storage (write), Sampling (read in shader), Can_Copy (read back to CPU)
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT

	var texture_rid = rd.texture_create(fmt, RDTextureView.new(), [])

	# 3. Create Uniform Set (Bind texture to binding 0)
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rid)

	var uniform_set = rd.uniform_set_create([uniform], shader_rid, 0)

	# 4. Pipeline & Dispatch
	var pipeline = rd.compute_pipeline_create(shader_rid)
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	# Calculate groups: (Total / LocalSize) -> ceil(512 / 8) = 64
	var x_groups = ceil(width / 8.0)
	var y_groups = ceil(height / 8.0)
	rd.compute_list_dispatch(compute_list, int(x_groups), int(y_groups), 1)

	rd.compute_list_end()

	# 5. Submit and Sync
	rd.submit()
	#await get_tree().process_frame
	#await get_tree().process_frame
	#await get_tree().process_frame
	rd.sync() # Wait for GPU to finish

	# 6. Retrieve Data & Convert to Texture2D
	# Get raw byte data from GPU memory
	var byte_data = rd.texture_get_data(texture_rid, 0)

	# Create an Image resource. FORMAT_RF maps to R32_SFLOAT
	var image = Image.create_from_data(width, height, false, Image.FORMAT_RF, byte_data)

	# Create the final Texture2D
	var texture = ImageTexture.create_from_image(image)

	# Cleanup manually since we used a local rendering device
	rd.free_rid(shader_rid)
	rd.free_rid(texture_rid)
	rd.free() 

	return texture
