#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer Params {
    vec2 origin;        // Fits in bytes 0-8
    vec2 output_size;   // Fits in bytes 8-16 (Perfectly aligned!)
    float height_scale; // Fits in bytes 16-20
    float selfHeight;// Fits in bytes 20-24
    int layer_index;
    float hullDist;
} params;

layout(set = 0, binding = 1) uniform sampler2D input_heightmap;
layout(set = 0, binding = 2, rg16f) uniform writeonly image2DArray output_texture;

const float PI = 3.14159265359;

void main() {
    int out_x = int(gl_GlobalInvocationID.x);

    if (out_x >= int(params.output_size.x)) return;

    // Angle Setup
    float theta = ((float(out_x) + 0.5) / params.output_size.x) * 2.0 * PI;
    vec2 dir = vec2(cos(theta), sin(theta));

    // Origin Height
    vec2 tex_size = vec2(textureSize(input_heightmap, 0));
    vec2 origin_uv = params.origin / tex_size;
    float height_origin = textureLod(input_heightmap, origin_uv,0.0).r * params.height_scale;
    height_origin += params.selfHeight;

    float max_slope = -10000.0; // Start very low
    float max_slope_hull = max_slope;
    int max_dist = int(params.output_size.y);

    // Start marching at 1 pixel away
    for (int d = 1; d <= 1024; d++) { // Prev: max_dist as length, however, yes.
        
        // 1. Calculate Physics
        vec2 sample_pos_px = params.origin + (dir * float(d));
        vec2 sample_uv = sample_pos_px / tex_size;

        // Boundary Check
        if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
            // Fill remaining pixels with current max_slope to avoid streaks
            for (int fill_d = d; fill_d <= max_dist; fill_d++) {
                 imageStore(output_texture, ivec3(out_x, fill_d - 1, params.layer_index), vec4(1000000, 0.0, 0.0, 1.0));
            }
            break;
        }

        float height_current = textureLod(input_heightmap, sample_uv,0.0).r * params.height_scale;
        
        // Slope = Rise / Run. We use float(d) because that is the distance.
        float current_slope = (height_current - height_origin) / float(d);
        max_slope = max(max_slope, current_slope);
        float current_hull_slope = (height_current - params.hullDist - height_origin) / float(d);
        max_slope_hull = max(max_slope, current_slope);

        // 2. Write to Texture
        // d=1 writes to y=0
        // d=2 writes to y=1
        ///imageStore(output_texture, ivec2(out_x, d - 1), vec4(max_slope*d+height_origin, 0.0, 0.0, 1.0));
        // Use ivec3(x, y, layer) to index the Array Texture
        imageStore(output_texture, ivec3(ivec2(out_x,d-1), params.layer_index), vec4(max_slope*d+height_origin, max_slope_hull*d+height_origin, 0.0, 1.0));
    }
}