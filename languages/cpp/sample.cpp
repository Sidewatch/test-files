// ── Comments ──
// Line comment. TODO: shard the bins. FIXME: handle overflow.
/* Block comment
   spanning lines */
/** Doxygen block.
 *  @brief  Warehouse inventory showcase.
 *  @param  sku   the stock keeping unit
 *  @return the quantity
 *  @tparam T     element type
 *  @see    Warehouse
 */
/// Triple-slash doc comment with \c code and \a arg.
//! Qt-style doc comment.

// ── Preprocessor ──
#pragma once
#pragma GCC diagnostic ignored "-Wunused-variable"
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <concepts>
#include <cstdint>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <thread>
#include <tuple>
#include <variant>
#include <vector>
#include <cstdlib>
#include <stdexcept>
#include <iomanip>
#include "warehouse_config.h"

#define STR_(x) #x
#define STR(x) STR_(x)
#define CAT(a, b) a##b
#define MAX_BINS 64
#define SQUARE(x) ((x) * (x))
#define LONG_MACRO(a, b) \
    do {                 \
        (void)(a);       \
        (void)(b);       \
    } while (0)
#ifndef WAREHOUSE_VERSION
#define WAREHOUSE_VERSION "1.0"
#endif
#if defined(__clang__) && __cplusplus >= 202002L
#  define HAS_CPP20 1
#elif defined(_MSC_VER)
#  define HAS_CPP20 0
#else
#  define HAS_CPP20 1
#endif
#undef MAX_BINS
#define MAX_BINS 128
#if 0
#error "never compiled"
#endif

// ── Namespaces and aliases ──
namespace acme::warehouse {

using Sku = std::string;
using Quantity = std::uint32_t;
using Prices = std::map<Sku, double>;
typedef unsigned long long ull;
namespace chr = std::chrono;
inline namespace v1 {}

// ── Constants and literals ──
constexpr int kDecimal = 1'000'000;
constexpr int kHex = 0xFF'EC;
constexpr int kOctal = 0755;
constexpr int kBinary = 0b1010'1010;
constexpr unsigned kUnsigned = 42u;
constexpr long kLong = 42L;
constexpr unsigned long long kBig = 18446744073709551615ULL;
constexpr double kPi = 3.14159;
constexpr double kExp = 6.02e23;
constexpr double kNegExp = 1.5E-10;
constexpr float kFloat = 2.5f;
constexpr long double kLD = 1.0L;
constexpr double kHexFloat = 0x1.8p1;
constexpr char kChar = 'a';
constexpr char kEscape = '\n';
constexpr char kOctalChar = '\101';
constexpr char kHexChar = '\x41';
constexpr char16_t kU16 = u'é';
constexpr char32_t kU32 = U'\U0001F600';
constexpr wchar_t kWide = L'W';
constexpr char8_t kU8 = u8'x';
constexpr bool kYes = true;
constexpr bool kNo = false;
constexpr std::nullptr_t kNull = nullptr;

// ── Strings ──
const char* kPlain = "Warehouse \"north\"\tbin\n";
const char* kUnicode = "café \U0001F4E6 \x41\101";
const wchar_t* kWideStr = L"wide";
const char16_t* kU16Str = u"utf16";
const char32_t* kU32Str = U"utf32";
const char8_t* kU8Str = u8"utf8";
const char* kRaw = R"(raw "string" with \n no escapes)";
const char* kRawDelim = R"sql(SELECT * FROM stock WHERE qty > 0)sql";
const char* kMulti = "adjacent "
                     "concatenated";

// ── Concepts and templates ──
template <typename T>
concept Countable = requires(T t) {
    { t.count() } -> std::convertible_to<Quantity>;
    typename T::value_type;
};

template <typename T, std::size_t N = 8>
class Ring {
public:
    using value_type = T;
    explicit Ring() = default;
    void push(const T& v) { data_[head_++ % N] = v; }
    [[nodiscard]] constexpr std::size_t capacity() const noexcept { return N; }
private:
    std::array<T, N> data_{};
    std::size_t head_ = 0;
};

template <Countable C>
auto total(const C& c) -> Quantity { return c.count(); }

template <typename... Args>
constexpr auto sum(Args... args) { return (args + ... + 0); }


// ── Enums ──
enum class Category : std::uint8_t { Tools, Fasteners, Safety = 10, Bulk };
enum Legacy { LEGACY_A = 1, LEGACY_B = 1 << 2 };

// ── Structs, classes, inheritance ──
struct Item {
    Sku sku;
    Quantity qty{};
    double price = 0.0;
    Category cat = Category::Tools;
    unsigned flags : 4;
    auto operator<=>(const Item&) const = default;
};

class Auditable {
public:
    virtual ~Auditable() = default;
    virtual void audit() const = 0;
};

class Bin final : public Auditable, private Ring<Item> {
public:
    Bin() noexcept : capacity_(MAX_BINS) {}
    Bin(const Bin&) = default;
    Bin(Bin&&) noexcept = default;
    Bin& operator=(const Bin&) = delete;
    ~Bin() override { std::cout << "bin closed\n"; }

    void audit() const override;
    Item& operator[](std::size_t i) { return items_.at(i); }
    explicit operator bool() const { return !items_.empty(); }
    friend std::ostream& operator<<(std::ostream& os, const Bin& b);
    static int created;
    mutable int cache_hits = 0;
    virtual Bin* clone() const { return new Bin(*this); }

protected:
    int capacity_;
private:
    std::vector<Item> items_;
};

union Raw { int i; float f; };

// ── Functions ──
inline int Bin::created = 0;

void Bin::audit() const {
    for (const auto& it : items_) std::cout << it.sku << '\n';
}

std::ostream& operator<<(std::ostream& os, const Bin& b) {
    return os << "Bin(" << b.capacity_ << ")";
}

int clamp_qty(int value, int lo = 0, int hi = kDecimal) noexcept {
    return value < lo ? lo : (value > hi ? hi : value);
}

[[deprecated("use clamp_qty")]] int old_clamp(int v);

consteval int cube(int x) { return x * x * x; }
static_assert(cube(3) == 27, "cube works");

std::optional<Item> find(const std::vector<Item>& v, std::string_view sku) {
    auto it = std::ranges::find_if(v, [&](const Item& i) { return i.sku == sku; });
    if (it == v.end()) return std::nullopt;
    return *it;
}

// ── Operators and expressions ──
int operators(int a, int b) {
    int r = a + b - a * b / (b ? b : 1) % 7;
    r += 1; r -= 2; r *= 3; r /= 2; r %= 5;
    r <<= 2; r >>= 1; r &= 0xF; r |= 0x1; r ^= 0x3;
    r = ~r; r = -r; r = +r;
    r++; ++r; r--; --r;
    bool ok = (a < b) && (a <= b) || (a > b) || (a >= b) && !(a == b) || (a != b);
    auto cmp = a <=> b;
    int* p = &r;
    int v = *p;
    Item item{};
    Item* ip = &item;
    int q = ip->qty + item.qty;
    int sz = sizeof(int) + alignof(double);
    int nested = a ? b ? 1 : 2 : 3;
    int sc = std::string::npos == 0;
    int (Item::*member)  = nullptr;
    return r + v + q + sz + nested + (ok ? 1 : 0) + (cmp < 0);
}

// ── Lambdas ──
auto make_adder(int n) {
    return [n](int x) mutable -> int { return x + n; };
}
auto generic = [](auto&& a, auto&&... rest) { return a; };
auto templ = []<typename T>(T x) { return x; };
auto cap = [] { return 0; };

// ── Control flow ──
void control(const std::vector<Item>& items) {
    if (items.empty()) {
        return;
    } else if (items.size() == 1) {
        std::cout << "one\n";
    } else {
        std::cout << "many\n";
    }
    if (auto n = items.size(); n > 3) { std::cout << n; }
    if constexpr (sizeof(int) == 4) {}
    if consteval {}

    for (std::size_t i = 0; i < items.size(); ++i) { if (i == 2) continue; }
    for (const auto& [sku, qty, price, cat, fl] : std::vector<Item>{}) {}
    for (auto& it : items) { (void)it; }
    int n = 3;
    while (n--) { if (n == 1) break; }
    do { --n; } while (n > -2);

    switch (n) {
        case 0: [[fallthrough]];
        case 1: std::cout << "low"; break;
        case 2 ... 5: break;
        default: break;
    }
outer:
    for (int a = 0; a < 3; ++a)
        for (int b = 0; b < 3; ++b)
            if (b == 2) goto outer_done;
outer_done:;

    try {
        throw std::runtime_error("bad bin");
    } catch (const std::runtime_error& e) {
        std::cerr << e.what();
    } catch (...) {
        throw;
    }
}

// ── Memory and casts ──
void memory() {
    auto up = std::make_unique<Item>();
    auto sp = std::make_shared<Item>();
    Item* raw = new Item[4];
    delete[] raw;
    Item* one = new (std::nothrow) Item;
    delete one;
    int i = static_cast<int>(3.7);
    auto d = dynamic_cast<Bin*>(static_cast<Auditable*>(nullptr));
    auto c = const_cast<char*>("x");
    auto r = reinterpret_cast<std::uintptr_t>(c);
    auto t = typeid(Item).name();
    int arr[3] = {1, 2, 3};
    int& ref = arr[0];
    int&& rref = 5;
    auto moved = std::move(up);
    decltype(auto) dt = (ref);
    thread_local int tl = 0;
    volatile int vol = 0;
    register_t reg = 0;
}

// ── Coroutines and threads ──
std::atomic<int> counter{0};
std::mutex mtx;

void worker(int id) {
    std::lock_guard<std::mutex> lock(mtx);
    counter.fetch_add(id, std::memory_order_relaxed);
}

// ── Variant and visit ──
using Value = std::variant<int, double, std::string>;
std::string describe(const Value& v) {
    return std::visit([](auto&& x) -> std::string {
        using T = std::decay_t<decltype(x)>;
        if constexpr (std::is_same_v<T, int>) return "int";
        else return "other";
    }, v);
}

} // namespace acme::warehouse

// ── Entry point ──
using namespace acme::warehouse;
extern "C" int legacy_entry(void);

int main(int argc, char* argv[]) {
    std::cout << "Acme warehouse " << WAREHOUSE_VERSION << " " << __FILE__ << ":" << __LINE__ << std::endl;
    std::thread t(worker, 1);
    t.join();
    Bin bin;
    bin.audit();
    return argc > 1 ? EXIT_FAILURE : 0;
}

// ── Further constructs ──
#include <coroutine>
#include <bit>
#include <compare>
#include <cstddef>
#include <new>
#include <numeric>
#include <span>
#include <sstream>
#include <type_traits>
#include <utility>

#define VARIADIC(fmt, ...) std::printf(fmt __VA_OPT__(,) __VA_ARGS__)
#define PASTE3(a, b, c) a##b##c
#define STRINGIFY(x) #x
#if __has_include(<version>)
#include <version>
#endif
#if __has_cpp_attribute(nodiscard) >= 201603L
#define NODISCARD [[nodiscard]]
#endif
#pragma region extras
#pragma endregion
#pragma pack(push, 1)
struct Packed { char a; int b; };
#pragma pack(pop)
_Pragma("GCC diagnostic push")
_Pragma("GCC diagnostic pop")

namespace extras {

// User-defined literals
constexpr unsigned long long operator""_kg(unsigned long long v) { return v * 1000; }
constexpr long double operator""_m(long double v) { return v; }
std::string operator""_s(const char* s, std::size_t n) { return std::string(s, n); }
constexpr auto weight = 5_kg;
constexpr auto height = 1.8_m;
const auto label = "bin"_s;

// Template template parameters, requires clauses, fold expressions
template <template <typename...> class Container, typename T>
struct Wrapper { Container<T> inner; };

template <typename T>
    requires std::is_arithmetic_v<T> && (sizeof(T) >= 4)
T twice(T v) { return v * 2; }

template <typename T>
T halve(T v) requires std::floating_point<T> { return v / 2; }

template <auto N>
struct Constant { static constexpr auto value = N; };

template <typename... Ts>
constexpr bool all_arith = (std::is_arithmetic_v<Ts> && ...);

template <typename T> struct is_ptr : std::false_type {};
template <typename T> struct is_ptr<T*> : std::true_type {};

template <typename T, typename = std::enable_if_t<std::is_integral_v<T>>>
void only_ints(T) {}

template <class T> using Vec = std::vector<T>;

// Coroutines
struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_never initial_suspend() noexcept { return {}; }
        std::suspend_never final_suspend() noexcept { return {}; }
        std::suspend_never yield_value(int) { return {}; }
        void return_void() {}
        void unhandled_exception() {}
    };
};
Task coro() {
    co_await std::suspend_always{};
    co_yield 1;
    co_return;
}

// explicit(bool), noexcept(expr), using enum, designated init
enum class Color { Red, Green };
struct Flexible {
    template <typename T> explicit(!std::is_integral_v<T>) Flexible(T) noexcept(noexcept(T{})) {}
};
struct Point3 { int x, y, z; };
constexpr Point3 origin{.x = 0, .y = 0, .z = 0};
std::string color_name(Color c) {
    switch (c) {
        using enum Color;
        case Red: return "red";
        case Green: return "green";
    }
    return {};
}

// Function try block, member pointers, placement new, alignment
struct Guarded {
    int v;
    Guarded() try : v(0) { } catch (...) { throw; }
    int get() const { return v; }
    static constexpr int kStatic = 3;
    static inline int kInline = 4;
    int Guarded::* member_ptr = &Guarded::v;
    int (Guarded::*func_ptr)() const = &Guarded::get;
};
alignas(64) static char buffer[sizeof(Guarded)];
void* place(void* p, int) noexcept { return ::new (p) char; }

// Asm, attributes, GNU extensions
void low_level() {
    [[maybe_unused]] int unused = 0;
    [[likely]] if (unused == 0) {}
    asm volatile("nop" ::: "memory");
    __asm__("" ::: );
    int x = __builtin_popcount(5u);
    auto lbl = &&target;
    goto *lbl;
target:
    (void)x;
}
__attribute__((always_inline)) inline int fast() { return 1; }
int deprecated_fn() __attribute__((deprecated("old")));

// Digraphs and alternative tokens
bool alt(bool a, bool b) { bool r = a; r and_eq b; r or_eq a; r xor_eq b; return (a and b) or (not a) xor r; }

// Structured bindings with refs, init-statement switch, range-for with init
void modern(std::map<std::string, int>& m) {
    for (auto& [key, value] : m) { value += key.size(); }
    for (std::vector<int> v{1, 2, 3}; auto n : v) { (void)n; }
    switch (int k = 2; k) { case 2: break; default: break; }
    auto [a, b] = std::pair{1, 2};
    static_assert(std::is_same_v<decltype(a), int>);
    auto sp = std::span<int>{};
    auto bits = std::bit_cast<unsigned>(1.0f);
    std::ostringstream os;
    os << std::hex << std::showbase << 255 << '\n';
    int local = std::accumulate(m.begin(), m.end(), 0, [](int acc, const auto& p) { return acc + p.second; });
    (void)local; (void)sp; (void)bits; (void)b;
}

union Variant2 { int i; double d; Variant2() : i(0) {} };
class Forward;
struct Incomplete;
typedef struct { int tag; } CStyle;
typedef int (*Callback)(int);
using FnPtr = void (*)(int, ...);
template <typename T> struct [[nodiscard]] Result { T value; };
class [[deprecated]] Old {};
int volatile_counter = 0;
extern "C++" { int cxx_linkage(); }
inline constexpr int kInlineConst = 1;
constinit int kConstInit = 2;
thread_local std::string tls_name;

} // namespace extras
