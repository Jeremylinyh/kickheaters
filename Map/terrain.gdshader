shader_type spatial;
render_mode world_vertex_coords,unshaded;
global uniform sampler2D heightMap : repeat_disable;
//uniform sampler2D mapTexture : repeat_disable;
const float maxHeight = 60.0;
const vec2 mapSize = vec2(4096.0,4096.0);
const float mapScale = 1.0;

#include "res://VisibilityHighlighter/visibleHorizon.gdshaderinc"

varying vec2 v_world_pos;
varying float heightSampled;

void vertex() {
	// Called for every vertex the material is visible on.
	v_world_pos = VERTEX.xz;

	vec2 effectivePosition = mapScale * (VERTEX.xz/mapSize);
	float height = textureLod(heightMap, effectivePosition,0.0).r;
	VERTEX.y = height * maxHeight;
	heightSampled = VERTEX.y;
	//VERTEX.y = max(VERTEX.y,isUnderground(VERTEX));
}

float random (vec2 st) {
	st = floor(st*1.0);
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123) * 0.5 + 0.5;
}

vec2 gradientDir(vec2 st) 
{
    return vec2(1.0,0.0);
    vec2 towards = st - vec2(0.0);
    //return normalize(towards);
    return normalize(vec2(-towards.y,towards.x));
}

float accumulateLIC(vec2 startPos) {
    const float steps = 16.0;
    
    float totalWeight = 0.0;
    float totalColor = 0.0;
    float dt = 0.01;
    
    vec2 p = startPos;
    for (float i = 0.0; i < steps; i++) {
        vec2 v = gradientDir(p);
        p += v * dt; 
        float weight = exp(-0.1 * i);
        totalColor += random(p) * weight;
        totalWeight += weight;
    }
    
    p = startPos;
    for (float i = 0.0; i < steps; i++) {
        vec2 v = gradientDir(p);
        p -= v * dt; 
        float weight = exp(-0.1 * i);
        totalColor += random(p) * weight;
        totalWeight += weight;
    }

    return totalColor / totalWeight;
}


vec3 mapColor(vec2 position) {
	return vec3(0.016, 0.569, 0.035) * accumulateLIC(position);
	//* random(position);
	//(random(floor(position * 36.0)) *0.5 + 1.0);
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 pixelPos = v_world_pos/mapSize;
	vec3 worldPos = vec3(v_world_pos.x,heightSampled,v_world_pos.y); // brainfart
	ALBEDO = mix(mapColor(pixelPos).rgb , (isUnderground(worldPos) + 0.1),0.5) * ((heightSampled*0.5) + 6.0)/60.0;
	///ALBEDO = vec3(isUnderground(worldPos) * fract(UV*10.0)/100.0,0.5);
	//ALBEDO = vec3(heightSampled);
	//ALBEDO = worldPos;
	//ALBEDO = vec3(isUnderground(worldPos));
}

//void light() {
	//// Called for every pixel for every light affecting the material.
	//// Uncomment to replace the default light processing function with this one.
	//vec3 litColor = LIGHT_COLOR; //vec3(0.5);
	//bool shouldOverrideLight = length(DIFFUSE_LIGHT) <= 0.;
	//shouldOverrideLight = shouldOverrideLight || (litColor.x == litColor.y); // or if self is white
	//shouldOverrideLight = shouldOverrideLight && ATTENUATION > 0.0;
	//if (shouldOverrideLight)
	//{
		//DIFFUSE_LIGHT = max(litColor * ATTENUATION,DIFFUSE_LIGHT);
	//}
//}
