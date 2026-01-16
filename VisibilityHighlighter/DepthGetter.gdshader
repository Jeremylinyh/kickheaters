shader_type spatial;

render_mode unshaded, cull_disabled, depth_test_disabled, fog_disabled;

// Automatically grabs the depth buffer of the viewport
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void vertex() {
	// This forces the mesh to cover the entire screen (Screen Space Quad)
	// regardless of where the camera is looking.
	//POSITION = vec4(VERTEX.xy*2.0, 1.0, 1.0);
}

void fragment() {
	// 1. Get the raw non-linear, reversed depth (0.0 to 1.0)
    float depth = texture(depth_texture, SCREEN_UV).r;

    // 2. Linearize it to get View Space depth (Meters)
    // The PROJECTION_MATRIX contains the math needed to undo the non-linear curve
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z * 10.0; // This is now actual units (e.g., meters)

    // 3. Pack it (you may be wondering why we aren't using 100% of the memory avaliable to us, it is totally not because I think that is unnecessarily complicated but that I decided this is enough precision)
	float red_val   = mod(linear_depth, 100.0);
	float green_val = mod(floor(linear_depth / 100.0), 100.0);
	float blue_val  = mod(floor(linear_depth / 10000.0), 100.0);
	
    ALBEDO = vec3(red_val,green_val,blue_val)/100.0;
}
