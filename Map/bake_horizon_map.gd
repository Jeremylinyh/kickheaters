extends Node

# Create a local rendering device.
@onready var rd := RenderingServer.create_local_rendering_device()

# stride: step size when marching heightmap
func dispatchCompute(heightmap : Image ,origin : Vector2,outputSize : Vector2, heightScale : float,stride : float) :
	# Load GLSL shader
	var shader_file := load("res://VisibilityHighlighter/HorizonMapper.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)

	# --- Binding 0: The Params Buffer ---
	# (vec2, vec2, float, float) creates a clean, packed 24-byte block.
	var input_data := PackedFloat32Array([
		origin.x, origin.y, 
		outputSize.x, outputSize.y, 
		heightScale, stride
	])
	var input_bytes := input_data.to_byte_array()
	var buffer_rid := rd.storage_buffer_create(input_bytes.size(), input_bytes)

	var uniform_params := RDUniform.new()
	uniform_params.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_params.binding = 0
	uniform_params.add_id(buffer_rid)


	# --- Binding 1: The Input Heightmap (Sampler2D) ---
	# You need two things here: A Sampler State and the Texture RID itself.
	# Note: See "How to get the Texture RID" below if you aren't sure where this comes from.

	# 1. Create a sampler (Linear filtering is usually what you want for heightmaps)
	var sampler_state := RDSamplerState.new()
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	var sampler_rid := rd.sampler_create(sampler_state)

	# 2. Create the Uniform
	var uniform_input := RDUniform.new()
	uniform_input.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform_input.binding = 1
	# IMPORTANT: For SAMPLER_WITH_TEXTURE, add the Sampler RID first, then the Texture RID.
	uniform_input.add_id(sampler_rid)
	var texture_input_rid := create_heightmap_rid(rd,heightmap)
	uniform_input.add_id(texture_input_rid) # <--- The RID of your input texture


	# --- Binding 2: The Output Texture (Image2D) ---
	# This is a "write-only" image in the shader (r32f).
	# This texture MUST have been created with the usage bit: TEXTURE_USAGE_STORAGE_BIT
	# 1. Define the format (Must match your shader's layout)
	var fmt = RDTextureFormat.new()
	fmt.width = 4096
	fmt.height = 1024
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT # Matches layout(r32f)

	# 2. Set Usage Bits (This is the most important part)
	fmt.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |    # Allows shader to write
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT # Allows CPU to read back
	)

	# 3. Create it on the GPU
	# We pass an empty array [] because there is no initial image data.
	var output_texture_rid = rd.texture_create(fmt, RDTextureView.new(), [])
	
	var uniform_output := RDUniform.new()
	uniform_output.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform_output.binding = 2
	uniform_output.add_id(output_texture_rid) 


	# --- Final Step: Create the Set ---
	# We pass all three uniforms in a single array.
	var uniform_set := rd.uniform_set_create(
		[uniform_params, uniform_input, uniform_output], 
		shader, 
		0 # This matches "set = 0" in GLSL
	)

	# Create a compute pipeline
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 64, 1, 1)
	rd.compute_list_end()
	
	# Submit to GPU and wait for sync
	rd.submit()
	rd.sync()
	
	# 1. Download the bytes from the GPU
	var output_bytes := rd.texture_get_data(output_texture_rid, 0)

	# 2. Create an Image from the bytes (Must match Image.FORMAT_RF for r32f)
	var output_image := Image.create_from_data(4096, 1024, false, Image.FORMAT_RF, output_bytes)
	
	# CLEANUP
	rd.free_rid(buffer_rid)
	rd.free_rid(texture_input_rid) # You'll need to store this from the helper
	rd.free_rid(output_texture_rid)
	
	return output_image

func create_heightmap_rid(rd: RenderingDevice, image: Image) -> RID:
	# 1. Prepare the image data
	# We convert to RF (Red Float) because heightmaps usually need high precision (32-bit float).
	# If your shader expects vec4 color, use FORMAT_RGBA8.
	# Since you have 'sampler2D', the shader will read the Red channel automatically.
	image.convert(Image.FORMAT_RF) 
	
	# 2. Describe the texture to the GPU
	var fmt := RDTextureFormat.new()
	fmt.width = image.get_width()
	fmt.height = image.get_height()
	
	# This must match the Image format converted above! 
	# R32_SFLOAT corresponds to Image.FORMAT_RF
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT 
	
	# 3. Define how the GPU is allowed to use this
	# SAMPLING_BIT = "I will read this inside a shader using a sampler"
	# CAN_UPDATE_BIT = "I will upload data to this from the CPU"
	# CAN_COPY_FROM_BIT = "I might want to read this back later" (Optional, but safe)
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	# 4. Create the Texture View (default settings are usually fine)
	var view := RDTextureView.new()
	
	# 5. Create the actual texture and upload the bytes
	var data := [image.get_data()] # Must be an array of byte arrays (for mipmaps)
	var texture_rid := rd.texture_create(fmt, view, data)
	
	return texture_rid
