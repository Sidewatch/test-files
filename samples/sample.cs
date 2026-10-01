// Inventory management sample exercising common C# constructs
using System;
using System.Collections.Generic;

namespace WarehouseApp
{
    public enum Category
    {
        Electronics,
        Grocery,
        Hardware
    }

    public class Product
    {
        // Maximum allowed quantity per order
        public const int MAX_QUANTITY = 500;

        public string Name { get; set; }
        public decimal Price { get; set; }
        public Category Kind { get; set; }

        public Product(string name, decimal price, Category kind)
        {
            Name = name;
            Price = price;
            Kind = kind;
        }

        // Computes discounted price for a given quantity
        public decimal TotalCost(int quantity)
        {
            if (quantity > MAX_QUANTITY)
            {
                throw new ArgumentException("Quantity exceeds limit");
            }

            decimal subtotal = Price * quantity;
            return subtotal * 0.95m;
        }
    }

    public static class Program
    {
        public static void Main(string[] args)
        {
            var catalog = new List<Product>
            {
                new Product("Laptop", 1299.99m, Category.Electronics),
                new Product("Coffee", 8.50m, Category.Grocery)
            };

            foreach (var item in catalog)
            {
                decimal cost = item.TotalCost(3);
                Console.WriteLine($"{item.Name}: {cost:C}");
            }
        }
    }
}
