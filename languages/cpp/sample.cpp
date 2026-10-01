// C++23 (with C++26 additions marked) — syntax showcase

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

// ══ Latest-standard additions ══════════════════════════════════════════
#include <expected>
#include <print>
#include <utility>

#ifdef ACME_WIN
#  define ACME_API __declspec(dllexport)
#elifdef ACME_POSIX
#  define ACME_API __attribute__((visibility("default")))
#elifndef ACME_OTHER
#  define ACME_API
#else
#  define ACME_API
#endif
#warning "C++23 #warning directive"
#line 900 "generated.cpp"

namespace latest {

// ── Alternative tokens and remaining operators ──
bool tokens(unsigned a, unsigned b) {
    unsigned x = a bitand b;
    unsigned y = a bitor b;
    unsigned z = compl a;
    unsigned w = a | b;
    unsigned v = a ^ b;
    unsigned s = a >> 2;
    short sh = 1;
    signed int si = -1;
    void* null = NULL;
    (void)null; (void)sh; (void)si;
    return (a not_eq b) and (x or y) and (z xor w) and (v != s);
}
std::vector<std::vector<int>> nested_templates;
static_assert(offsetof(extras::Point3, y) == sizeof(int));

// ── Raw string prefixes ──
const wchar_t*  kLR   = LR"(wide raw)";
const char16_t* kuR   = uR"(utf16 raw)";
const char32_t* kUR   = UR"(utf32 raw)";
const char8_t*  ku8R  = u8R"(utf8 raw)";

// ── C++23 literals and escapes ──
constexpr std::size_t kSize = 42uz;
constexpr std::ptrdiff_t kDiff = 42z;

// ── Explicit object parameter (deducing this), static operators ──
struct Counter {
    int n = 0;
    int get(this const Counter& self) { return self.n; }
    template <typename Self>
    auto&& value(this Self&& self) { return std::forward<Self>(self).n; }
    static int operator()(int x) { return x + 1; }
    static int operator[](int x, int y) { return x * y; }
    int ref_get() const & { return n; }
    int ref_take() && { return n; }
    virtual int pure() const noexcept = 0;
    virtual void later() volatile && = 0;
    template <typename T> T cast() const { return static_cast<T>(n); }
};
template <typename T> struct Box {
    T t;
    template <typename U> U as() const { return static_cast<U>(t); }
};
template <typename B> int use_template_method(B& b) {
    return b.template as<int>() + b.template as<long>();
}

// ── Lambdas, latest forms ──
template <typename... Xs>
auto init_pack_capture(Xs... xs) {
    return [... captured = xs] { return sizeof...(captured); };
}
void lambdas() {
    int x = 1, y = 2;
    int arr[3] = {1, 2, 3};
    auto a = [x = 10, &r = y] { return x + r; };
    auto b = [x, y]() noexcept -> int { return x + y; };
    auto c = [] static { return 0; };
    auto d = [] consteval { return 1; };
    auto e = []<typename T>(T t) requires std::integral<T> { return t; };
    auto f = [&](this auto&& self, int n) -> int { return n <= 1 ? 1 : n * self(n - 1); };
    (void)a; (void)b; (void)c; (void)d; (void)e; (void)f; (void)arr;
}

// ── if consteval, auto(x), assume, [[no_unique_address]] ──
constexpr int cx(int n) {
    if consteval { return n; } else { return n + 1; }
}
constexpr int cx2(int n) {
    if !consteval { return n; }
    return auto(n) + 1;
}
int assumed(int v) {
    [[assume(v > 0)]];
    return v;
}
struct Empty {};
struct Holder { [[no_unique_address]] Empty e; int v [[maybe_unused]]; int arr [[deprecated]] [3]; };

// ── Constraints: disjunction, conjunction, nested requirements ──
template <typename T>
concept Number = std::integral<T> || std::floating_point<T>;
template <typename T>
concept Printable = requires(T t, std::ostream& os) {
    { os << t } -> std::same_as<std::ostream&>;
    requires sizeof(T) > 0;
    typename T::value_type;
    { t.size() } noexcept;
};
template <typename T>
    requires std::integral<T> or std::floating_point<T>
T mixed(T v) { return v; }

// ── Dependent names ──
template <typename T>
struct Dep {
    using value = typename T::value_type;
    using rebound = typename T::template rebind<int>::other;
    typename T::value_type member;
    static constexpr auto n = T::template count<3>();
};

// ── Explicit instantiation ──
template <typename T> T clamp_qty_t(T v) { return v; }
template int clamp_qty_t<int>(int);
} // namespace latest
namespace acme::warehouse {
template class Ring<int, 4>;
extern template class Ring<long, 8>;
}
namespace latest {

// ── Comma expressions and designated array initialisers ──
void commas() {
    int i = 0, j = 10;
    int r = (i++, j--, i + j);
    for (i = 0, j = 5; i < j; ++i, --j) { r += i; }
    (void)r;
}
int designated[4] = {[1] = 5, [2] = 6};
int ranged[6] = {[0 ... 2] = 1, [3 ... 5] = 2};

// ── std::expected, std::print, placeholder `_` (C++26) ──
std::expected<int, std::string> parse(std::string_view s) {
    if (s.empty()) return std::unexpected("empty");
    return 1;
}
void print_all() {
    std::print("{} {}\n", 1, "two");
    std::println("{:>8}", 3.5);
}
void placeholder() {
    auto _ = parse("x");
    auto _ = parse("y");
}

// ── Compiler extensions ──
void gnu_extensions(int in) {
    int out = 0;
    asm("mov %1, %0" : "=r"(out) : "r"(in) : "cc");
    asm volatile("" : "+r"(out) : : "memory");
    asm goto("jmp %l0" : : : : done);
done:
    int v = __extension__ 5;
    extras::Guarded gd;
    int extras::Guarded::* mp = &extras::Guarded::v;
    int (extras::Guarded::*fp)() const = &extras::Guarded::get;
    extras::Guarded* gp = &gd;
    int viaDot = gd.*mp + (gd.*fp)();
    int viaArrow = gp->*mp + (gp->*fp)();
    (void)viaDot; (void)viaArrow;
    switch (in) { case 1 ... 3: break; default: break; }
    auto g = _Generic(in, int: 1, long: 2, default: 3);
    (void)v; (void)g;
}
__attribute__((noreturn)) void die();
[[noreturn]] void die2();

} // namespace latest

// ── Microsoft extensions (labelled; accepted by MSVC/clang-cl only) ──
#ifdef ACME_MSVC
__declspec(dllexport) int ms_exported();
__declspec(align(16)) struct MsAligned { int x; };
int __cdecl ms_cdecl(int);
int __stdcall ms_stdcall(int);
int __fastcall ms_fastcall(int);
void ptr_modifiers(int* __ptr32 p32, int* __ptr64 p64, int* __restrict r, int* __unaligned u,
                   int* __sptr s, int* __uptr uu);
char __based(void) *based_ptr;
void seh() {
    __try {
        ms_cdecl(1);
        __leave;
    } __except (1) {
    }
    __try {
        ms_cdecl(2);
    } __finally {
    }
}
#endif

// ── Modules (a separate translation unit; shown here for syntax only) ──
#ifdef ACME_MODULE_UNIT
module;
#include <cstdint>
export module acme.warehouse:inventory;
export import :stock;
import std;
import <vector>;
import "local.h";
export module acme.warehouse [[deprecated]];
export namespace acme { int exported_fn(); }
export { int a(); int b(); }
export template <typename T> T exported_tpl(T v) { return v; }
module :private;
#endif

// ── C++26: reflection, expansion statements, contracts, annotations ──
#ifdef ACME_CPP26
namespace cpp26 {
constexpr auto info = ^^Item;
constexpr auto global = ^^::;
constexpr auto typ = ^^int;
using Spliced = typename [: ^^int :];
[: info :] make_item();
constexpr int spliced_value = [: ^^kDecimal :];
template <auto R> struct Splice { using T = typename [: R :]; };
void expand() {
    template for (auto x : std::tuple{1, 2.0, 'c'}) { (void)x; }
}
const char* kNamed = "\N{LATIN CAPITAL LETTER A}";
const char* kDelim = "\u{1F4E6} \x{41} \o{101}";
struct NoCopy {
    NoCopy(const NoCopy&) = delete("copying is disabled");
};
template <typename... Ts>
using First = Ts...[0];
int checked(int x) pre(x > 0) post(r : r > 0) { contract_assert(x != 3); return x; }
[[=1]] int annotated;
}
#endif
