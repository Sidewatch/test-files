// Go 1.25 — syntax showcase
//go:build linux || darwin
// +build linux darwin (deprecated: superseded by //go:build)

// Package inventory tracks stock levels for a small warehouse.
//
// It demonstrates every syntactic category of Go:
// comments, literals, declarations, generics, concurrency and control flow.
//
// Deprecated: showcase only. TODO: split into packages. FIXME: locking.
package inventory

/* Block comment spanning
   several lines. */

import (
	"context"
	"errors"
	"fmt"
	"math"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	str "strconv"
	. "unicode"
	_ "embed"
)

import "io"

//go:embed banner.txt
var banner string

//go:generate stringer -type=Status
//go:noinline

// ── Constants and iota ──
const MAX_ITEMS = 128

const (
	KB = 1 << (10 * (iota + 1))
	MB
	GB
)

type Status int

const (
	Pending Status = iota
	Paid
	Shipped
	_
	Cancelled
)

const (
	typedInt     int     = 42
	typedFloat   float64 = 3.14
	untypedBig           = 1 << 100
	complexConst         = 3 + 4i
)

// ── Variables and literals ──
var ErrNotFound = errors.New("item not found")

var (
	decimal     = 1_000_000
	hexadecimal = 0xFF_EE
	octal       = 0o755
	legacyOctal = 0755
	binary      = 0b1010_0101
	floating    = 6.02e23
	negExp      = 1.5E-3
	hexFloat    = 0x1p-2
	imaginary   = 2.5i
	complexVal  = complex(1, 2)
	truth       = true
	falsity     = false
	nothing     = nil
	mathInf     = math.Inf(1)
	mathNaN     = math.NaN()
)

var (
	rune1     = 'a'
	rune2     = '\n'
	rune3     = 'é'
	rune4     = '\U0001F600'
	rune5     = '\x41'
	rune6     = '\101'
	rune7     = '\''
	text      = "interpreted \"string\" with \\ backslash, \t tab, é, \x41, \101"
	rawString = `raw string with \n no escapes
and a second line, "quotes" and 'apostrophes'`
	unicode = "日本語 café ☕"
	bytes   = []byte("bytes")
	runes   = []rune("runes")
)

// ── Types ──
type Item struct {
	Name     string `json:"name" db:"name"`
	Quantity int    `json:"quantity,omitempty"`
	Price    float64
	Tags     []string
	Meta     map[string]any
	embedded
	*Pointer
}

type embedded struct{ id int }
type Pointer struct{}

type Store struct {
	mu    sync.RWMutex
	items map[string]Item
}

type (
	ID      string
	Handler func(ctx context.Context, item Item) error
	Matrix  [3][3]float64
	Ptr     *int
	Chans   struct {
		in  <-chan int
		out chan<- int
		bi  chan int
	}
)

type Alias = map[string][]int

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Named interface {
	Shape
	fmt.Stringer
	Name() string
}

// ── Generics ──
type Number interface {
	~int | ~int32 | ~int64 | ~float32 | ~float64
}

type Stack[T any] struct {
	items []T
}

type Pair[K comparable, V any] struct {
	Key K
	Val V
}

func (s *Stack[T]) Push(v T) { s.items = append(s.items, v) }

func (s *Stack[T]) Pop() (T, bool) {
	var zero T
	if len(s.items) == 0 {
		return zero, false
	}
	v := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return v, true
}

func Sum[T Number](values ...T) T {
	var total T
	for _, v := range values {
		total += v
	}
	return total
}

func Map[T, U any](in []T, f func(T) U) []U {
	out := make([]U, 0, len(in))
	for _, v := range in {
		out = append(out, f(v))
	}
	return out
}

// ── Functions and methods ──
func NewStore() *Store {
	return &Store{items: make(map[string]Item)}
}

// Add inserts or updates an item in the store.
func (s *Store) Add(item Item) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.items) >= MAX_ITEMS {
		return fmt.Errorf("store full: cannot exceed %d items: %w", MAX_ITEMS, ErrNotFound)
	}
	s.items[item.Name] = item
	return nil
}

// Total computes the combined value of all stocked items.
func (s Store) Total() (sum float64) {
	for _, it := range s.items {
		sum += it.Price * float64(it.Quantity)
	}
	return
}

func (st Status) String() string {
	switch st {
	case Pending:
		return "pending"
	case Paid, Shipped:
		return "active"
	default:
		return fmt.Sprintf("Status(%d)", int(st))
	}
}

func variadic(prefix string, nums ...int) (count int, err error) {
	count = len(nums)
	if count == 0 {
		err = errors.New("no numbers: " + prefix)
	}
	return
}

func init() {
	fmt.Fprintln(os.Stderr, "initialising", banner)
}

// ── Operators ──
func operators() {
	a, b := 10, 3
	_ = a + b - a*b/a%b
	_ = a&b | a^b&^b
	_ = a<<2 | b>>1
	_ = a == b || a != b && a < b || a <= b || a > b || a >= b
	_ = !true
	a += 1
	a -= 1
	a *= 2
	a /= 2
	a %= 5
	a &= 0xF
	a |= 0x1
	a ^= 0x3
	a <<= 1
	a >>= 1
	a &^= 2
	a++
	b--
	p := &a
	*p = 5
	_ = *p
}

// ── Collections, slices, maps ──
func collections() {
	arr := [5]int{1, 2, 3, 4, 5}
	auto := [...]string{"a", "b"}
	indexed := [...]int{2: 10, 4: 20}
	slice := arr[1:3]
	full := arr[1:3:4]
	open := arr[:]
	m := map[string][]int{"a": {1, 2}, "b": nil}
	nested := []struct {
		X, Y int
	}{{1, 2}, {3, 4}}
	pts := []*Item{{Name: "ptr"}}
	slice = append(slice, 6, 7)
	copy(open, slice)
	delete(m, "a")
	clear(m)
	v, ok := m["b"]
	_, _, _, _, _, _, _ = auto, indexed, full, nested, pts, v, ok
	fmt.Println(len(arr), cap(slice), min(1, 2), max(3, 4))
	for i := range 3 {
		fmt.Println(i)
	}
	for i, v := range arr {
		_ = i + v
	}
	for k := range m {
		_ = k
	}
}

// ── Control flow ──
func control(x interface{}) string {
	if n, ok := x.(int); ok && n > 0 {
		return "positive"
	} else if s, ok := x.(string); ok {
		return strings.ToUpper(s)
	} else {
		_ = n
	}

	switch v := x.(type) {
	case nil:
		return "nil"
	case int, int64:
		return fmt.Sprint(v)
	case []byte:
		return string(v)
	case error:
		return v.Error()
	case func() string:
		return v()
	default:
		return "unknown"
	}
}

func labels() {
outer:
	for i := 0; i < 3; i++ {
		for j := 0; j < 3; j++ {
			switch {
			case i == j:
				continue outer
			case i > 1:
				break outer
			case j == 2:
				goto done
			}
			fallthrough_example(i)
		}
	}
done:
	fmt.Println("done")
}

func fallthrough_example(n int) {
	switch n {
	case 0:
		fmt.Println("zero")
		fallthrough
	case 1:
		fmt.Println("one or fallthrough")
	}
}

// ── Errors, panic, recover, defer ──
type InsufficientStock struct {
	SKU  string
	Want int
}

func (e *InsufficientStock) Error() string {
	return fmt.Sprintf("insufficient stock for %s: want %d", e.SKU, e.Want)
}

func safe(f func()) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("recovered: %v", r)
		}
	}()
	f()
	return nil
}

func check(err error) {
	var stock *InsufficientStock
	if errors.As(err, &stock) {
		panic(stock)
	}
	if errors.Is(err, ErrNotFound) {
		panic("not found")
	}
}

// ── Concurrency ──
func workers(ctx context.Context, jobs <-chan int, results chan<- int) {
	var wg sync.WaitGroup
	for w := 0; w < 4; w++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for {
				select {
				case j, ok := <-jobs:
					if !ok {
						return
					}
					results <- j * 2
				case <-ctx.Done():
					return
				case <-time.After(time.Second):
					continue
				default:
				}
			}
		}(w)
	}
	wg.Wait()
	close(results)
}

func pipeline() {
	ch := make(chan int, 3)
	done := make(chan struct{})
	go func() {
		defer close(done)
		for v := range ch {
			fmt.Println(v)
		}
	}()
	ch <- 1
	ch <- 2
	close(ch)
	<-done
}

var once sync.Once

func sorted(items []Item) []Item {
	sort.Slice(items, func(i, j int) bool { return items[i].Name < items[j].Name })
	return items
}

func conversions() {
	n, _ := str.Atoi("42")
	f := float64(n)
	r := IsUpper('A')
	var iface any = f
	_ = iface.(float64)
	_ = io.EOF
	_ = r
	_ = new(int)
	_ = unsafeSize()
}

func unsafeSize() uintptr { return 0 }

func main() {
	store := NewStore()
	widget := Item{Name: "widget", Quantity: 3, Price: 9.99}
	if err := store.Add(widget); err != nil {
		fmt.Println("failed to add:", err)
		return
	}
	fmt.Printf("total value: %.2f\n", store.Total())
	fmt.Printf("%v %+v %#v %T %q %x %08.3f %-5d|\n", widget, widget, widget, widget, "s", 255, 3.14159, 7)
}

// ── Constraints, type sets and generic methods ──
type Stringish interface {
	~string
	Len() int
}

type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr |
		~float32 | ~float64 | ~string
}

type Set[T comparable] map[T]struct{}

func (s Set[T]) Add(v T)           { s[v] = struct{}{} }
func (s Set[T]) Has(v T) bool      { _, ok := s[v]; return ok }
func Keys[M ~map[K]V, K comparable, V any](m M) []K {
	r := make([]K, 0, len(m))
	for k := range m {
		r = append(r, k)
	}
	return r
}

func MaxOf[T Ordered](a, b T) T {
	if a > b {
		return a
	}
	return b
}

type List[T any] struct {
	head *node[T]
}

type node[T any] struct {
	val  T
	next *node[T]
}

func (l *List[T]) All() func(yield func(int, T) bool) {
	return func(yield func(int, T) bool) {
		i := 0
		for n := l.head; n != nil; n = n.next {
			if !yield(i, n.val) {
				return
			}
			i++
		}
	}
}

var _ = MaxOf[int]
var _ Set[string] = make(Set[string])

// ── Method values and expressions, function types, closures ──
type Counter struct{ n int }

func (c *Counter) Inc() int { c.n++; return c.n }
func (c Counter) Get() int  { return c.n }

type Op func(a, b int) int

func apply(op Op, xs ...int) int {
	acc := 0
	for _, x := range xs {
		acc = op(acc, x)
	}
	return acc
}

func adder() func(int) int {
	sum := 0
	return func(x int) int {
		sum += x
		return sum
	}
}

func methodForms() {
	c := &Counter{}
	inc := c.Inc
	get := Counter.Get
	incExpr := (*Counter).Inc
	_ = inc() + get(*c) + incExpr(c)
	nums := []int{1, 2, 3}
	_ = apply(func(a, b int) int { return a + b }, nums...)
	f := adder()
	_ = f(1)
	func() { defer fmt.Println("immediately invoked") }()
}

// ── Anonymous structs, embedding, struct comparison ──
type Animal struct{ Name string }

func (a Animal) Speak() string { return a.Name }

type Dog struct {
	Animal
	Breed string
}

func anonymous() {
	point := struct {
		X, Y int
	}{1, 2}
	pts := []struct{ A, B string }{{"a", "b"}, {A: "c"}}
	d := Dog{Animal: Animal{Name: "rex"}, Breed: "lab"}
	_ = d.Speak() + d.Name + fmt.Sprint(point.X) + pts[0].A
	var empty struct{}
	_ = empty
}

// ── More statements: select with send, switch with init, goto ──
func selects(ch chan int, quit <-chan struct{}) {
	for {
		select {
		case v := <-ch:
			fmt.Println(v)
		case ch <- 42:
		case <-quit:
			return
		case v, ok := <-ch:
			_, _ = v, ok
		}
	}
}

func switches(x int) string {
	switch y := x * 2; {
	case y > 10:
		return "big"
	}
	switch x := interface{}(x).(type) {
	case int:
		return fmt.Sprint(x)
	}
	if v := x * 2; v > 5 {
		goto end
	} else if v < 0 {
		return "neg"
	}
	for range 3 {
	}
	for range []int{1, 2} {
	}
	for i := range 10 {
		_ = i
	}
end:
	return "end"
}

// ── Builtins and packages ──
func builtins() {
	var c chan int = make(chan int, 1)
	c <- 1
	close(c)
	s := make([]int, 2, 10)
	s = append(s, 1, 2, 3)
	s = append(s[:1], s[2:]...)
	n := copy(s, []int{9, 9})
	m := map[string]int{"a": 1}
	delete(m, "a")
	clear(s)
	p := new(int)
	cx := complex(1, 2)
	re, im := real(cx), imag(cx)
	println("builtin println", len(s), cap(s), n, *p, re, im, min(1, 2, 3), max(1.5, 2))
	print("no newline")
	defer func() { _ = recover() }()
	panic(fmt.Sprintf("%v", m))
}

// ── cgo and linkname are shown as comments to stay buildable ──
// #include <stdio.h>
// import "C"
//go:linkname runtimeNano runtime.nanotime
func runtimeNano() int64

// ── Unicode identifiers and labels ──
func uniçode() {
	π := 3.14159
	名前 := "name"
	_, _ = π, 名前
}

// ── Printf verbs ──
func verbs() {
	fmt.Printf("%v %+v %#v %T %% %t %b %c %d %o %O %q %x %X %U %e %E %f %F %g %G %s %p %8.3f|%-8d|%+d|%08b|% x|%[2]d %[1]d %*d\n",
		1, 1, 1, 1, true, 5, 'x', 10, 8, 8, "q", 255, 255, 0x1F600, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, "s", &struct{}{}, 3.14159, 7, 7, 5, 1, 2, 4, 9)
}

// ── Go 1.24+: generic type aliases, iterators, WaitGroup.Go, parenthesised types, empty statements ──
type Vec[T any] = []T // generic alias (Go 1.24)

type Table[K comparable, V any] = map[K]V

func Zip[A, B any](a []A, b []B) func(yield func(A, B) bool) { // iter.Seq2-shaped
	return func(yield func(A, B) bool) {
		for i := 0; i < min(len(a), len(b)); i++ {
			if !yield(a[i], b[i]) {
				return
			}
		}
	}
}

func Convert[From, To any](f From, conv func(From) To) To { return conv(f) }

func newForms() {
	var parenthesised (int) = 3 // parenthesised type
	var fnType (func(int) int) = func(i int) int { return i }
	var ptr *(int) = &parenthesised
	_ = fnType
	_ = ptr
	explicit := Convert[int, string] // explicit instantiation without a call
	_ = explicit
	pair := Convert[int, string](7, func(i int) string { return fmt.Sprint(i) })
	_ = pair
	;
	for a, b := range Zip([]int{1}, []string{"x"}) {
		_, _ = a, b
	}
	var wg sync.WaitGroup
	wg.Go(func() {}) // Go 1.25
	wg.Wait()
	for i := range 3 {
		defer func() { _ = i }() // per-iteration loop variable (Go 1.22)
	}
}
