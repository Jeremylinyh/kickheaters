use godot::prelude::*;
use godot::classes::{Node, INode};

#[derive(GodotClass)]
#[class(base=Node)]
struct Player {
    base: Base<Node>
}

#[godot_api]
impl INode for Player {
    fn init(base: Base<Node>) -> Self {
        godot_print!("Hello, world!"); // Prints to the Godot console
        
        Self {
            base,
        }
    }
}
