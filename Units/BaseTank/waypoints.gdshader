shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled;
instance uniform float thickness = 0.1;

void vertex() {
	// Called for every vertex the material is visible on.
	vec3 next_vertex_position = CUSTOM0.xyz; 
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_next = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(next_vertex_position, 1.0);
	vec2 ndc_pos = clip_pos.xy / clip_pos.w;
	vec2 ndc_next = clip_next.xy / clip_next.w;
	vec2 dir = vec2(1.0, 0.0); // Safe fallback direction
	vec2 diff = ndc_next - ndc_pos;
	if (length(diff) > 0.00001) {
	    dir = normalize(diff);
	}
	vec2 perp = vec2(-dir.y, dir.x);
	
	vec2 offset = perp * UV.y * thickness;
	clip_pos.xy += offset * clip_pos.w;
	POSITION = clip_pos;
	
	//POSITION = vec4(UV,1.0,1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(UV,1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
