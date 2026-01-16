shader_type spatial;

render_mode unshaded, cull_disabled, depth_test_disabled, fog_disabled;

// Automatically grabs the depth buffer of the viewport
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void vertex() {
	// This forces the mesh to cover the entire screen (Screen Space Quad)
	// regardless of where the camera is looking.
	POSITION = vec4(VERTEX.xy*2.0, 1.0, 1.0);
}

void fragment() {
	// 1. Get the raw non-linear, reversed depth (0.0 to 1.0)
    float depth = texture(depth_texture, SCREEN_UV).r;

    // 2. Linearize it to get View Space depth (Meters)
    // The PROJECTION_MATRIX contains the math needed to undo the non-linear curve
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z; // This is now actual units (e.g., meters)

    // 3. Normalize it for display (Optional)
    // Divide by, say, 100.0 so that 100 meters = 1.0 (White)
    // Everything past 100m will clip to white, everything closer is a gradient.
    ALBEDO = vec3(linear_depth/1000.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
