use godot::prelude::*;
use godot::classes::Node3D;
use godot::classes::INode3D; // The interface trait

#[derive(GodotClass)]
#[class(tool,base=Node3D)]
pub struct Heights {
    #[export]
    pub heightmap_dimensions : f32,
    #[export]
    pub heightmap_height : f32,
    //height_map: Vec<f32>,
    pub layers: Vec<Vec<f32>>,
    #[base]
    pub base: Base<Node3D>,
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
    pub fn cast_ray(&self,start : Vector3,direction : Vector3) -> f32 {
        let mut current_mip: i32 = 0;
        let travel_dist = Vector2::new(direction.x, direction.z).length();
        
        if travel_dist <= 0.0
        {
            if direction.y > 0.0
            {
                return direction.length();
            }
            let ground_height = self.get_height_interpolated(start.x,start.z, 0);
            return (start.y - ground_height).max(0.0);
        }

        let dir_norm = direction/travel_dist;
        // let travel_dir = Vector2::new(direction.x,direction.z) / travel_dist.max(1.0); // Normalize and prevent division by zero

        let base_step_size = travel_dist / (direction).length(); // Base step size for fine sampling
        let mut dist_traveled = 0.0;
        // let starting2d = Vector2::new(start.x, start.z);
        while dist_traveled <= travel_dist {
            let current_pos3d = start + dir_norm * dist_traveled;
            let current_pos = Vector2::new(current_pos3d.x, current_pos3d.z);
            

            if current_pos3d.x < 0.0 || current_pos3d.z < 0.0 || current_pos3d.x >= 4096.0 || current_pos3d.z >= 4096.0 
            {
                break;
            }
            let mut height = self.get_height(current_pos.x as u32, current_pos.y as u32, current_mip);
            
            if current_mip == 0
            {
                height = self.get_height_interpolated(current_pos.x, current_pos.y, current_mip);
            }
            if height >= current_pos3d.y {
                if current_mip > 0 {
                    current_mip -= 1; // Move to finer mip level for more precise checks
                } else {
                    //godot_print!("Hit at position {},{} with height {}", current_pos.x, current_pos.y, height);
                    break; // Already at finest level, stop here
                }
            }
            else {
                current_mip = (current_mip + 1).min((self.layers.len() - 1) as i32); // Move to next mip level for coarser checks
                dist_traveled += base_step_size; //self.determine_step_size(current_pos,Vector2::new(dir_norm.x,dir_norm.z), base_step_size, current_mip);
            }
        }

        return (dir_norm * dist_traveled).length();
    }

    pub fn determine_step_size(&self, position: Vector2, dir2d_norm: Vector2, minimum_step_size: f32, mip: i32) -> f32 {
        // 1 << mip is a much faster way to calculate 2^mip for integers
        let cell_size = (1 << mip.max(0)) as f32; 

        let mut t_max_x = f32::INFINITY;
        let mut t_max_y = f32::INFINITY;

        // Distance to next X boundary
        if dir2d_norm.x.abs() > 1e-6 {
            let next_x = if dir2d_norm.x > 0.0 {
                (position.x / cell_size).floor() * cell_size + cell_size
            } else {
                let mut nx = (position.x / cell_size).ceil() * cell_size - cell_size;
                // If we are sitting exactly on the boundary, push to the next one
                if nx == position.x { nx -= cell_size; } 
                nx
            };
            t_max_x = (next_x - position.x) / dir2d_norm.x;
        }

        // Distance to next Y boundary
        if dir2d_norm.y.abs() > 1e-6 {
            let next_y = if dir2d_norm.y > 0.0 {
                (position.y / cell_size).floor() * cell_size + cell_size
            } else {
                let mut ny = (position.y / cell_size).ceil() * cell_size - cell_size;
                if ny == position.y { ny -= cell_size; }
                ny
            };
            t_max_y = (next_y - position.y) / dir2d_norm.y;
        }

        // Take the shortest distance to a boundary
        // Add a tiny epsilon (e.g., 0.001) so the step pushes the position mathematically INSIDE the next cell
        let step_to_boundary = t_max_x.min(t_max_y) + 0.001;

        // Ensure we don't take a step smaller than the allowed minimum
        step_to_boundary.max(minimum_step_size)
    }

    #[func]
    pub fn get_height(&self, x: u32, y: u32,mip : i32) -> f32 {
        let mip= mip.max(0);
        if mip >= self.layers.len() as i32 {
            godot_warn!("Requested mip level {} exceeds available layers {}", mip, self.layers.len());
            return 0.0;
        }
        
        let scale = (1u32 << mip.max(0) as u32).max(1);
        let x = x / scale;
        let y = y / scale;
        let morton_idx = morton_encode(x, y);
        
        // Return 0.0 if out of bounds, or the actual value
        if morton_idx < self.layers[mip as usize].len() {
            self.layers[mip as usize][morton_idx] * self.heightmap_height
        } else {
            0.0
        }
    }

    #[func]
    pub fn get_height_interpolated(&self, x: f32, y: f32, mip: i32) -> f32 {
        // Bilinear interpolation across mesh triangles
        // Samples 4 corners and interpolates based on fractional position
        
        if mip >= self.layers.len() as i32 {
            godot_warn!("Requested mip level {} exceeds available layers {}", mip, self.layers.len());
            return 0.0;
        }
        
        // Get integer and fractional parts
        let x_floor = x.floor() as u32;
        let y_floor = y.floor() as u32;
        let fx = x.fract(); // 0.0 to 1.0
        let fy = y.fract(); // 0.0 to 1.0
        
        // Sample 4 corners
        let h00 = self.get_height(x_floor, y_floor, mip);
        let h10 = self.get_height(x_floor + 1, y_floor, mip);
        let h01 = self.get_height(x_floor, y_floor + 1, mip);
        let h11 = self.get_height(x_floor + 1, y_floor + 1, mip);
        
        // Bilinear interpolation
        // First interpolate along x (bottom and top rows)
        let hx0 = h00 * (1.0 - fx) + h10 * fx;
        let hx1 = h01 * (1.0 - fx) + h11 * fx;
        
        // Then interpolate along y
        let height = hx0 * (1.0 - fy) + hx1 * fy;
        
        height
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
    pub fn set_whole_map(&mut self, input_array: PackedFloat32Array) {
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
