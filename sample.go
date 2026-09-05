// Package inventory tracks stock levels for a small warehouse.
package inventory

import (
	"errors"
	"fmt"
)

// MAX_ITEMS is the maximum number of distinct items allowed.
const MAX_ITEMS = 128

// ErrNotFound is returned when an item is missing from the store.
var ErrNotFound = errors.New("item not found")

// Item represents a single product in the warehouse.
type Item struct {
	Name     string
	Quantity int
	Price    float64
}

// Store holds a collection of items keyed by name.
type Store struct {
	items map[string]Item
}

// NewStore constructs an empty Store ready for use.
func NewStore() *Store {
	return &Store{items: make(map[string]Item)}
}

// Add inserts or updates an item in the store.
func (s *Store) Add(item Item) error {
	if len(s.items) >= MAX_ITEMS {
		return fmt.Errorf("store full: cannot exceed %d items", MAX_ITEMS)
	}
	s.items[item.Name] = item
	return nil
}

// Total computes the combined value of all stocked items.
func (s *Store) Total() float64 {
	var sum float64
	for _, it := range s.items {
		sum += it.Price * float64(it.Quantity)
	}
	return sum
}

func main() {
	store := NewStore()
	widget := Item{Name: "widget", Quantity: 3, Price: 9.99}
	if err := store.Add(widget); err != nil {
		fmt.Println("failed to add:", err)
		return
	}
	fmt.Printf("total value: %.2f\n", store.Total())
}
