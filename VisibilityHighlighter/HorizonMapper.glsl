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

// Sample height that matches a rasterized mesh (Split: Top-Left to Bottom-Right)
float GetTriangularHeight(sampler2D heightMap, vec2 uv, float textureSize) {
    // 1. Scale UVs to texel space (0.0 to textureSize)
    vec2 texelPos = uv * textureSize;

    // 2. Determine the integer coordinate of the Top-Left texel
    // We use floor() to find the "grid cell" we are currently in.
    vec2 basePos = floor(texelPos - 0.5); 
    
    // 3. Get the fractional part (0.0 to 1.0) inside that texel cell
    vec2 f = texelPos - 0.5 - basePos;

    // 4. Fetch the 4 neighbor heights (the corners of the quad)
    // We use texelFetch for exact integer lookups to avoid unwanted filtering.
    // Ensure you clamp/wrap manually if needed, or rely on sampler state if using texture() with offset.
    float hTL = texelFetch(heightMap, ivec2(basePos) + ivec2(0, 0), 0).r; // Top-Left
    float hTR = texelFetch(heightMap, ivec2(basePos) + ivec2(1, 0), 0).r; // Top-Right
    float hBL = texelFetch(heightMap, ivec2(basePos) + ivec2(0, 1), 0).r; // Bottom-Left
    float hBR = texelFetch(heightMap, ivec2(basePos) + ivec2(1, 1), 0).r; // Bottom-Right

    // 5. The "Funni Triangle" Logic
    // We check if we are above or below the diagonal.
    // The diagonal is defined where the local x coordinate equals the local y coordinate.
    
    // NOTE: This assumes the standard TL->BR split. 
    // If f.x > f.y, we are in the Top-Right triangle.
    // If f.x <= f.y, we are in the Bottom-Left triangle.
    
    float height = 0.0;
    
    if (f.x > f.y) {
        // Upper-Right Triangle (defined by TL, TR, BR)
        // Barycentric weights simplify nicely here:
        // P = TL + (TR-TL)*f.x + (BR-TR)*f.y  <-- Wait, this is bilinear.
        // Let's derive the planar equation for the triangle TL-TR-BR.
        // On the top edge (f.y=0), height is mix(TL, TR, f.x).
        // On the right edge (f.x=1), height is mix(TR, BR, f.y).
        // The gradient in X is (TR - TL).
        // The gradient in Y is (BR - TR).
        
        height = hTL + (hTR - hTL) * f.x + (hBR - hTR) * f.y;
    } else {
        // Bottom-Left Triangle (defined by TL, BL, BR)
        // The gradient in X is (BR - BL).
        // The gradient in Y is (BL - TL).
        
        height = hTL + (hBR - hBL) * f.x + (hBL - hTL) * f.y;
    }

    return height;
}

void main() {
    int out_x = int(gl_GlobalInvocationID.x);

    if (out_x >= int(params.output_size.x)) return;

    // Angle Setup
    float theta = ((float(out_x) + 0.5) / params.output_size.x) * 2.0 * PI;
    vec2 dir = vec2(cos(theta), sin(theta));

    // Origin Height
    vec2 tex_size = vec2(textureSize(input_heightmap, 0));
    vec2 origin_uv = params.origin / tex_size;
    //float height_origin = GetTriangularHeight(input_heightmap, origin_uv,4096.0).r * params.height_scale;
    float height_origin = params.selfHeight;

    float max_slope = -10000.0; // Start very low
    float max_slope_hull = max_slope;
    //int max_dist = int(params.output_size.y);

    // Start marching at 1 pixel away
    for (int d = 1; d <= 1024; d++) { // Prev: max_dist as length, however, yes.
        
        // 1. Calculate Physics
        vec2 sample_pos_px = params.origin + (dir * float(d));
        vec2 sample_uv = sample_pos_px / tex_size;

        // Boundary Check
        if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
            // Fill remaining pixels with current max_slope to avoid streaks
            for (int fill_d = d; fill_d <= 1024; fill_d++) {
                 imageStore(output_texture, ivec3(out_x, fill_d - 1, params.layer_index), vec4(1000000, 0.0, 0.0, 1.0));
            }
            break;
        }

        float height_current = GetTriangularHeight(input_heightmap, sample_uv,4096.0).r * params.height_scale;
        
        float current_slope = (height_current - height_origin) / float(d);
        max_slope = max(max_slope, current_slope);

        float current_hull_slope = (height_current + params.hullDist - height_origin) / float(d);

        
        max_slope_hull = max(max_slope_hull, current_hull_slope); 

        imageStore(output_texture, ivec3(ivec2(out_x, d - 1), params.layer_index), 
            vec4(
                max_slope * d + height_origin,   
                max_slope_hull * d + (height_origin - params.hullDist), 
                0.0, 
                1.0
            )
        );
    }
}