use godot::prelude::*;
use godot::classes::Node3D;
use godot::classes::INode3D; // The interface trait

#[derive(GodotClass)]
#[class(base=Node3D)]
pub struct Heights {
    #[export]
    heightmap_dimensions : f32,
    #[export]
    heightmap_height : f32,
    height_map: Vec<f32>,
    layers: Vec<Vec<f32>>,
    #[base]
    base: Base<Node3D>,
}

#[godot_api]
impl INode3D for Heights {
    fn init(base: Base<Node3D>) -> Self {
        let default_dimension : f32 = 4096.0;
        //godot_print!("Heights initialized!");
        let len :usize = (default_dimension * default_dimension) as usize;

        Self { 
            height_map : vec![0.0;len],
            base ,
            heightmap_dimensions : default_dimension,
            heightmap_height : 60.0,
        }
    }
}

#[godot_api]
impl Heights {
    #[func]
    fn cast_ray(&mut self,start : Vector3,direction : Vector3) {
        let slice = self.height_map.as_mut_slice();
    }

    #[func]
    fn get_height(&self, x: u32, y: u32) -> f32 {
        let morton_idx = morton_encode(x, y);
        
        // Return 0.0 if out of bounds, or the actual value
        if morton_idx < self.height_map.len() {
            self.height_map[morton_idx]
        } else {
            0.0
        }
    }

    #[func]
    fn set_height_at(&mut self, x: u32, y: u32, height: f32) {
        let morton_idx = morton_encode(x, y);
        // .set() on PackedFloat32Array is safe and relatively fast
        if morton_idx < self.height_map.len() {
            self.height_map[morton_idx] = height;
        }
    }

    #[func]
    fn set_height_map(&mut self, input_array: PackedFloat32Array) {
        let size = self.heightmap_dimensions as u32;
        
        // Safety check: ensure input matches expected dimensions
        if input_array.len() != (size * size) as usize {
            godot_warn!("HeightMap size mismatch! Expected {}, got {}", size * size, input_array.len()); 
            return;
        }

        // Convert to Vec for fast manipulation in Rust
        let input_vec = input_array.to_vec();
        
        // Create a buffer for the swizzled result
        // Initialize with 0.0 or clone input to ensure size
        let mut swizzled_vec = vec![0.0f32; input_vec.len()];

        for y in 0..size {
            for x in 0..size {
                // Calculate linear index in the input (row-major standard)
                let linear_idx = (y * size + x) as usize;
                
                // Calculate Morton index (Z-order curve)
                let morton_idx = morton_encode(x, y);

                // Map linear input to Morton storage
                if morton_idx < swizzled_vec.len() {
                     swizzled_vec[morton_idx] = input_vec[linear_idx];
                }
            }
        }

        // Store the swizzled data back into the Godot field
        self.height_map = swizzled_vec;
    }
}

fn morton_encode(x: u32, y: u32) -> usize {
    let mut part1 = (x & 0x0000_FFFF) as u64;
    part1 = (part1 ^ (part1 << 8)) & 0x00FF_00FF;
    part1 = (part1 ^ (part1 << 4)) & 0x0F0F_0F0F;
    part1 = (part1 ^ (part1 << 2)) & 0x3333_3333;
    part1 = (part1 ^ (part1 << 1)) & 0x5555_5555;

    let mut part2 = (y & 0x0000_FFFF) as u64;
    part2 = (part2 ^ (part2 << 8)) & 0x00FF_00FF;
    part2 = (part2 ^ (part2 << 4)) & 0x0F0F_0F0F;
    part2 = (part2 ^ (part2 << 2)) & 0x3333_3333;
    part2 = (part2 ^ (part2 << 1)) & 0x5555_5555;

    (part1 | (part2 << 1)) as usize
}
