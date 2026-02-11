use godot::prelude::*;

// Import Heights from the library
#[path = "../src/heights.rs"]
mod heights;

use heights::Heights;

// Pure algorithm for testing (no Godot dependencies)
fn cast_ray_pure(layers: &[Vec<f32>], ray_start: Vector3, ray_dir: Vector3) -> f32 {
    let mut current_mip: i32 = 0;
    let horizontal_len = Vector2::new(ray_dir.x, ray_dir.z).length();
    if horizontal_len == 0.0 {
        return 0.0;
    }
    
    let base_step_size = horizontal_len / ray_dir.length();
    let mut dist_traveled = 0.0;
    let max_distance = 1000.0;
    
    while dist_traveled <= max_distance {
        let current_pos3d = ray_start + ray_dir * dist_traveled;
        let current_pos = Vector2::new(current_pos3d.x, current_pos3d.z);
        
        // Get height at this position and mip level
        let scale = (1u32 << current_mip.max(0) as u32).max(1);
        let x = (current_pos.x as u32) / scale;
        let y = (current_pos.y as u32) / scale;
        let morton_idx = morton_encode(x, y);
        
        let height = if (current_mip as usize) < layers.len() && morton_idx < layers[current_mip as usize].len() {
            layers[current_mip as usize][morton_idx]
        } else {
            0.0
        };
        
        if height >= current_pos3d.y {
            if current_mip > 0 {
                current_mip -= 1;
            } else {
                break;
            }
        } else {
            current_mip = (current_mip + 1).min((layers.len() - 1) as i32);
            
            // Step size calculation
            let cell_size = (2.0f32).powi(current_mip.max(0) as i32);
            let mut step = base_step_size * cell_size;
            
            let off_x = current_pos.x.rem_euclid(cell_size);
            let off_y = current_pos.y.rem_euclid(cell_size);
            
            let to_grid_x = if off_x == 0.0 { cell_size } else { cell_size - off_x };
            let to_grid_y = if off_y == 0.0 { cell_size } else { cell_size - off_y };
            
            let min_to_grid = to_grid_x.min(to_grid_y);
            step = step.min(min_to_grid).max(1.0);
            dist_traveled += step;
        }
    }
    
    dist_traveled
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

// Helper: Build mipmaps from base heightmap (convert linear to morton order)
fn build_mips(size: u32, linear_values: Vec<f32>) -> Vec<Vec<f32>> {
    // First, convert from linear (row-major) to morton order
    let mut morton_base = vec![0.0; linear_values.len()];
    
    for y in 0..size {
        for x in 0..size {
            let linear_idx = (y * size + x) as usize;
            let morton_idx = morton_encode(x, y);
            morton_base[morton_idx] = linear_values[linear_idx];
        }
    }
    
    // Now build the mipmap hierarchy
    let mut layers = vec![morton_base];
    let mut current_size = size as usize;
    
    while current_size > 1 {
        let prev = &layers[layers.len() - 1];
        let mut next = Vec::new();
        
        for chunk in prev.chunks(4) {
            let max = chunk[0].max(chunk[1]).max(chunk[2]).max(chunk[3]);
            next.push(max);
        }
        
        layers.push(next);
        current_size /= 2;
    }
    
    layers
}

// Helper: Create a Heights instance with a 4x4 heightmap
fn create_test_heights(size: u32, values: Vec<f32>) -> Heights {
    let mut heights = Heights {
        heightmap_dimensions: size as f32,
        heightmap_height: 100.0,
        layers: vec![],
        base: unsafe { std::mem::MaybeUninit::zeroed().assume_init() },
    };
    
    let packed = PackedFloat32Array::from(values.as_slice());
    heights.set_whole_map(packed);
    heights
}

#[test]
fn test_horizontal_spike() {
    // 4x4 heightmap with spike at (1,0): [5, 20, 5, 5, ...]
    // Ray from (0, 15, 0) heading right (1, 0, 0)
    // Should hit the spike at x≈1
    println!("TEST: Horizontal spike");
    
    let mut values = vec![5.0; 16];
    values[1] = 20.0; // Spike at position 1
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {}", dist);
    assert!(dist > 0.5 && dist < 2.0, "Should hit around x=1, got {}", dist);
}

#[test]
fn test_diagonal_spike() {
    // 4x4 heightmap with spike at (1,1)
    // Ray from (0, 15, 0) heading diagonally (1, 0, 1)
    // Should hit around distance √2 ≈ 1.41
    println!("TEST: Diagonal spike");
    
    let mut values = vec![5.0; 16];
    values[5] = 20.0; // Position (1,1) in 4x4 grid
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 1.0).normalized();
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected ~1.4)", dist);
    assert!(dist > 0.8 && dist < 2.5, "Should hit diagonal spike, got {}", dist);
}

#[test]
fn test_no_collision() {
    // All heights at 5.0, ray at 15.0
    // Ray should travel without hitting
    println!("TEST: No collision");
    
    let values = vec![5.0; 16];
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Travel distance: {} (expected > 3)", dist);
    assert!(dist > 3.0, "Ray should travel full distance, got {}", dist);
}

#[test]
fn test_immediate_collision() {
    // Spike at (0,0) with height 20.0
    // Ray starts at (0, 15, 0) - inside terrain
    // Should hit immediately
    println!("TEST: Immediate collision");
    
    let mut values = vec![5.0; 16];
    values[0] = 20.0; // Spike at start position
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected <1)", dist);
    assert!(dist < 1.0, "Should hit immediately, got {}", dist);
}

#[test]
fn test_multiple_spikes() {
    // Spikes at (1,0) height 20 and (3,0) height 25
    // Should hit first spike at x≈1
    println!("TEST: Multiple spikes - should hit first");
    
    let mut values = vec![5.0; 16];
    values[1] = 20.0;  // First spike
    values[3] = 25.0;  // Second spike (further away)
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  First hit distance: {} (expected ~1)", dist);
    assert!(dist > 0.5 && dist < 2.0, "Should hit first spike at x≈1, got {}", dist);
}

#[test]
fn test_spike_at_grid_boundary() {
    // Spike at (2,0) - exactly at power-of-2 boundary
    println!("TEST: Spike at grid boundary");
    
    let mut values = vec![5.0; 16];
    values[2] = 20.0;
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected ~2)", dist);
    assert!(dist > 1.5 && dist < 2.5, "Should hit at x≈2, got {}", dist);
}

#[test]
fn test_vertical_ray() {
    // Spike at (0,1)
    // Ray from (0, 20, 0) traveling downward (0, -1, 0)
    // Should hit at distance 1
    println!("TEST: Vertical ray");
    
    let mut values = vec![5.0; 16];
    values[4] = 20.0; // Position (0,1) in 4x4
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 20.0, 0.0);
    let ray_dir = Vector3::new(0.0, -1.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected ~1)", dist);
    assert!(dist > 0.5 && dist < 2.0, "Should hit descending ray, got {}", dist);
}

#[test]
fn test_angled_ray() {
    // Spike at (2,0)
    // Ray from (0, 20, 0) heading at angle (1, -1, 0)
    // Should hit spike
    println!("TEST: Angled ray");
    
    let mut values = vec![5.0; 16];
    values[2] = 20.0;
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 20.0, 0.0);
    let ray_dir = Vector3::new(1.0, -1.0, 0.0).normalized();
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected ~2-3)", dist);
    assert!(dist > 0.5 && dist < 4.0, "Should hit angled ray, got {}", dist);
}

#[test]
fn test_dense_terrain() {
    // Checkerboard pattern with spikes
    // Should hit first spike
    println!("TEST: Dense terrain");
    
    let mut values = Vec::with_capacity(64);
    for y in 0..8 {
        for x in 0..8 {
            if (x + y) % 2 == 0 {
                values.push(20.0); // Spike
            } else {
                values.push(5.0);  // Valley
            }
        }
    }
    
    let layers = build_mips(8, values);
    let ray_start = Vector3::new(0.5, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected <1)", dist);
    assert!(dist < 1.5, "Should hit first spike quickly, got {}", dist);
}

#[test]
fn test_ray_below_terrain() {
    // Ray at height 3.0, terrain at 5.0
    // Should NOT hit
    println!("TEST: Ray below terrain");
    
    let values = vec![5.0; 16];
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 3.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Travel distance: {} (expected >3)", dist);
    assert!(dist > 3.0, "Ray below terrain should not hit, got {}", dist);
}

#[test]
fn test_grazing_ray() {
    // Ray at height exactly at spike height
    // Should hit at boundary
    println!("TEST: Ray at exact spike height");
    
    let mut values = vec![5.0; 16];
    values[1] = 15.0;
    
    let layers = build_mips(4, values);
    let ray_start = Vector3::new(0.0, 15.0, 0.0);
    let ray_dir = Vector3::new(1.0, 0.0, 0.0);
    
    let dist = cast_ray_pure(&layers, ray_start, ray_dir);
    println!("  Hit distance: {} (expected ~1)", dist);
    assert!(dist > 0.5 && dist < 2.0, "Should hit at exact height, got {}", dist);
}
