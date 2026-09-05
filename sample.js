// shop inventory utils
import { readFileSync } from "node:fs";

const MAX_ITEMS = 100;
const TAX_RATE = 0.08;

class Product {
  constructor(name, price) {
    this.name = name;
    this.price = price;
  }

  withTax() {
    return this.price * (1 + TAX_RATE);
  }
}

function formatPrice(value) {
  return `$${value.toFixed(2)}`;
}

function totalValue(products) {
  let sum = 0;
  for (const item of products) {
    sum += item.withTax();
  }
  return sum;
}

const widget = new Product("Widget", 9.99);
const grandTotal = totalValue([widget]);
console.log(`Total: ${grandTotal}`);
