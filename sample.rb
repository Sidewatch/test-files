# frozen_string_literal: true

# A small inventory module demonstrating common Ruby constructs.
module Inventory
  MAX_ITEMS = 100
  DEFAULT_TAX_RATE = 0.075

  # Represents a single product in the catalog.
  class Product
    attr_reader :name, :price

    def initialize(name, price)
      @name = name
      @price = price
      @tags = []
    end

    # Returns the price including tax.
    def total_price(rate = DEFAULT_TAX_RATE)
      subtotal = @price
      subtotal + (subtotal * rate)
    end

    def to_s
      "#{@name}: $#{format('%.2f', price)}"
    end
  end

  # Builds a catalog from a list of raw hashes.
  def self.build_catalog(rows)
    products = rows.map do |row|
      Product.new(row[:name], row[:price].to_f)
    end
    products.first(MAX_ITEMS)
  end
end

widget = Inventory::Product.new("Widget", 9.99)
puts widget.total_price
puts widget.to_s
