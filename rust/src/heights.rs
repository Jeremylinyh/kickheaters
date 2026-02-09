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
    //height_map: Vec<f32>,
    layers: Vec<Vec<f32>>,
    #[base]
    base: Base<Node3D>,
}

#[godot_api]
impl INode3D for Heights {
    fn init(base: Base<Node3D>) -> Self {
        let default_dimension : f32 = 4096.0;
        let len :usize = (default_dimension * default_dimension) as usize;
        let base_layer = vec![0.0; len];

        Self { 
            //height_map : base_layer,
            base ,
            heightmap_dimensions : default_dimension,
            heightmap_height : 60.0,
            layers: vec![base_layer],
        }
    }
}

#[godot_api]
impl Heights {
    #[func]
    fn cast_ray(&mut self,start : Vector3,direction : Vector3) {
        //let slice = self.height_map.as_mut_slice();
    }

    #[func]
    fn get_height(&self, x: u32, y: u32) -> f32 {
        let morton_idx = morton_encode(x, y);
        
        // Return 0.0 if out of bounds, or the actual value
        if morton_idx < self.layers[0].len() {
            self.layers[0][morton_idx]
        } else {
            0.0
        }
    }

    #[func]
    fn set_height_at(&mut self, x: u32, y: u32, height: f32) {
        let mut idx = morton_encode(x, y);

        // 1. Update Base Layer
        if idx < self.layers[0].len() {
            self.layers[0][idx] = height;
        } else {
            return;
        }

        // FIX 2: Bubble the change up the Quadtree
        // If we don't do this, the raycast optimization will break.
        for layer_idx in 0..self.layers.len() - 1 {
            let parent_idx = idx / 4;
            let block_start = parent_idx * 4;
            
            // Read from current layer to find new max of the 2x2 block
            let l = &self.layers[layer_idx];
            let max_val = l[block_start].max(l[block_start+1])
                                        .max(l[block_start+2])
                                        .max(l[block_start+3]);

            // Write to parent layer
            self.layers[layer_idx + 1][parent_idx] = max_val;
            
            idx = parent_idx;
        }
    }

    #[func]
    fn set_whole_map(&mut self, input_array: PackedFloat32Array) {
        let size = self.heightmap_dimensions as u32;
        
        if input_array.len() != (size * size) as usize {
             godot_warn!("Size mismatch");
             return;
        }

        // --- Step 1: Base Layer (Swizzle) ---
        let input_vec = input_array.to_vec();
        
        // Ensure layers[0] exists and is sized correctly
        if self.layers.is_empty() {
            self.layers.push(vec![0.0; (size * size) as usize]);
        } else {
            self.layers[0].resize((size * size) as usize, 0.0);
        }

        // Swizzle directly into layers[0]
        for y in 0..size {
            for x in 0..size {
                let linear_idx = (y * size + x) as usize;
                let morton_idx = morton_encode(x, y);
                self.layers[0][morton_idx] = input_vec[linear_idx];
            }
        }

        // --- Step 2: Build Quadtree Levels ---
        self.rebuild_mipmaps();
    }

    fn rebuild_mipmaps(&mut self) {
        let mut current_dim = self.heightmap_dimensions as usize;
        
        // Remove old upper layers, keep layer 0
        self.layers.truncate(1);

        while current_dim > 1 {
            // Get reference to the last layer we built
            let prev_layer = self.layers.last().unwrap();
            
            // Prepare next layer (1/4th the size)
            let next_len = prev_layer.len() / 4;
            let mut next_layer = Vec::with_capacity(next_len);

            // Iterate in chunks of 4 (These are spatially 2x2 blocks!)
            for chunk in prev_layer.chunks(4) {
                // Find max of the 4 pixels
                let max = chunk[0].max(chunk[1]).max(chunk[2]).max(chunk[3]);
                next_layer.push(max);
            }

            self.layers.push(next_layer);
            current_dim /= 2;
        }
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
