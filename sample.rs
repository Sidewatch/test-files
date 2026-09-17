// Track inventory for a small shop.
use std::collections::HashMap;
use std::io::{self, Write};

/// Maximum number of items a single order may contain.
const MAX_ITEMS: u32 = 100;

#[derive(Debug, Clone)]
struct Product {
    name: String,
    price: f64,
    quantity: u32,
}

impl Product {
    fn new(name: &str, price: f64) -> Self {
        Product {
            name: name.to_string(),
            price,
            quantity: 0,
        }
    }

    fn total_value(&self) -> f64 {
        self.price * self.quantity as f64
    }
}

fn restock(product: &mut Product, amount: u32) {
    product.quantity += amount;
}

fn main() {
    let mut catalog: HashMap<String, Product> = HashMap::new();
    let widget = Product::new("Widget", 9.99);
    catalog.insert(widget.name.clone(), widget);

    if let Some(item) = catalog.get_mut("Widget") {
        restock(item, 25);
        println!("Total value: {:.2}", item.total_value());
    }

    println!("Order limit is {}", MAX_ITEMS);
}
