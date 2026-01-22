@tool
class_name HorizonComputer
extends Node

# --- Public Settings ---
@export var shader_file: RDShaderFile
@export var output_size := Vector2i(4096, 1024)

# --- Private Internals (Don't touch) ---
var _rd: RenderingDevice
var _pipeline: RID
var _shader: RID
var _output_tex_rid: RID
var _params_buffer: RID
var _texture_wrapper: Texture2DRD
var _cached_input_rid: RID
var _initialized := false

func _notification(what):
	# Automatic Cleanup when node is deleted
	if what == NOTIFICATION_PREDELETE:
		_cleanup_gpu()

# --- The Only Function You Need To Call ---
# 1. input_img: The heightmap Image (or Texture2D)
# 2. settings: Dictionary with { "origin": Vector2, "scale": float, "stride": float }
# 3. target_global: The string name of the Global Shader Uniform to update
func run_compute(input_img: Image, settings: Dictionary, target_global: String) -> void:
	if not _initialized:
		_initialize_gpu()

	# 1. Update Inputs
	_update_params(settings.get("origin", Vector2.ZERO), settings.get("scale", 10.0), settings.get("stride", 1.0))
	_update_input_texture(input_img)

	# 2. Assign the result to the requested Global Variable
	# The wrapper points to our internal GPU texture. We just tell Godot "This name = This texture"
	RenderingServer.global_shader_parameter_set(target_global, _texture_wrapper)

	# 3. Run the magic
	_dispatch()

# --- Internal "Engine Magic" Below ---

func _initialize_gpu():
	_rd = RenderingServer.get_rendering_device()
	
	# Compile Shader
	var spirv = shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(spirv)
	_pipeline = _rd.compute_pipeline_create(_shader)
	
	# Create Output Texture (R32F)
	var fmt = RDTextureFormat.new()
	fmt.width = output_size.x
	fmt.height = output_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	_output_tex_rid = _rd.texture_create(fmt, RDTextureView.new())
	
	# Create Wrapper
	_texture_wrapper = Texture2DRD.new()
	_texture_wrapper.texture_rd_rid = _output_tex_rid
	
	# Create Param Buffer (24 bytes)
	_params_buffer = _rd.storage_buffer_create(24)
	
	_initialized = true

func _update_params(origin: Vector2, h_scale: float, stride: float):
	var data = PackedByteArray()
	data.resize(24)
	data.encode_float(0, origin.x)
	data.encode_float(4, origin.y)
	data.encode_float(8, float(output_size.x))
	data.encode_float(12, float(output_size.y))
	data.encode_float(16, h_scale)
	data.encode_float(20, stride)
	_rd.buffer_update(_params_buffer, 0, 24, data)

func _update_input_texture(img: Image):
	# Only recreate if we strictly have to (Optimization)
	# Ideally, check if RID exists, but simpler to recreate for robustness in this example
	if _cached_input_rid.is_valid():
		_rd.free_rid(_cached_input_rid)
		
	img.convert(Image.FORMAT_RF)
	var fmt = RDTextureFormat.new()
	fmt.width = img.get_width()
	fmt.height = img.get_height()
	fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	_cached_input_rid = _rd.texture_create(fmt, RDTextureView.new(), [img.get_data()])

func _dispatch():
	# Uniforms
	var u_param = RDUniform.new()
	u_param.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u_param.binding = 0
	u_param.add_id(_params_buffer)
	
	var u_in = RDUniform.new()
	u_in.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u_in.binding = 1
	var sampler = _rd.sampler_create(RDSamplerState.new())
	u_in.add_id(sampler)
	u_in.add_id(_cached_input_rid)
	
	var u_out = RDUniform.new()
	u_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u_out.binding = 2
	u_out.add_id(_output_tex_rid)
	
	var setUni = _rd.uniform_set_create([u_param, u_in, u_out], _shader, 0)
	
	# Execute
	var list = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(list, _pipeline)
	_rd.compute_list_bind_uniform_set(list, setUni, 0)
	_rd.compute_list_dispatch(list, int(ceil(output_size.x / 64.0)), 1, 1)
	_rd.compute_list_end()
	
	# Barrier
	#_rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE, RenderingDevice.BARRIER_MASK_FRAGMENT)
	
	# Cleanup Loop Garbage
	_rd.free_rid(setUni)
	_rd.free_rid(sampler)

func _cleanup_gpu():
	if _rd: # Check if RD still exists
		if _output_tex_rid.is_valid(): _rd.free_rid(_output_tex_rid)
		if _params_buffer.is_valid(): _rd.free_rid(_params_buffer)
		if _pipeline.is_valid(): _rd.free_rid(_pipeline)
		if _shader.is_valid(): _rd.free_rid(_shader)
		if _cached_input_rid.is_valid(): _rd.free_rid(_cached_input_rid)
