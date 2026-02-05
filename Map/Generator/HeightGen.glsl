#[compute]
#version 450

// Define a workgroup size (8x8 is standard for 2D image processing)
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Output image buffer (Write-only)
layout(set = 0, binding = 0, r32f) uniform image2D output_image;

// -----------------------------------------------------------
// Simplex 2D Noise Implementation
// -----------------------------------------------------------
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}
// -----------------------------------------------------------

void main() {
    // 1. Get the current pixel coordinate (Global Invocation ID)
    ivec2 id = ivec2(gl_GlobalInvocationID.xy);
    
    // 2. Get the resolution from the output image itself
    ivec2 size = imageSize(output_image);

    // 3. Boundary check: Stop if we are outside the image bounds
    if (id.x >= size.x || id.y >= size.y) {
        return;
    }

    // 4. Normalize coordinates (equivalent to gl_FragCoord / u_resolution)
    vec2 u_resolution = vec2(size);
    vec2 st = vec2(id) / 1024.0;
    
    // Aspect ratio correction
    st.x *= u_resolution.x / u_resolution.y;

    float height = snoise(st * 8.0) * 0.5 + 0.5;
    
    float amplitude = snoise(st * 3.0 + vec2(100.0));
    // Splines and stuff
    amplitude = smoothstep(-0.25, 0.25, amplitude) * 0.08;
    height *= amplitude + 0.1;

    float continentalness = snoise(st * 0.75 - vec2(67.0));
    continentalness *= continentalness;
    height += (smoothstep(0.1, 0.5, continentalness)) * 0.5;
    imageStore(output_image, id, vec4(height * 1.0,0.0,0.0, 1.0));
}