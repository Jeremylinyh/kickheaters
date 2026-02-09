use godot::prelude::*;
use godot::classes::Node;
use godot::classes::INode; // The interface trait

#[derive(GodotClass)]
#[class(base=Node)]
pub struct Heights {
    #[base]
    base: Base<Node>,
}

#[godot_api]
impl INode for Heights {
    fn init(base: Base<Node>) -> Self {
        godot_print!("Heights initialized!");
        Self { base }
    }
}

#[godot_api]
impl Heights {
    #[func]
    fn hello_world(&self) {
        godot_print!("Hello from the inherent impl!");
    }
}

