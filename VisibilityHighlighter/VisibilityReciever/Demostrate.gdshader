shader_type spatial;
render_mode world_vertex_coords;
varying vec3 worldPos;

#include "res://VisibilityHighlighter/visibleHorizon.gdshaderinc"

void vertex() {
	// Called for every vertex the material is visible on.
	worldPos = VERTEX;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 visibility = isUnderground(worldPos);
	if (!(visibility.x == visibility.y && visibility.x == visibility.z && visibility.x > 0.0))
	{
		discard;
	}
	//ALBEDO = isUnderground(worldPos);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
