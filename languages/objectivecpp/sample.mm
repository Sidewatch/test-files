// Objective-C++ (Objective-C 2.0 + C++23 / C++26 as accepted by clang 21) — syntax showcase: C++ templates, lambdas and the STL behind Objective-C classes.
/* A block comment
   over several lines. */
/// Documentation comment.
/*!
 * @brief Headerdoc style.
 * @param sku The item identifier.
 */
// TODO: replace the vector with a flat map
// FIXME: total() ignores discounts

#import <Foundation/Foundation.h>
#include <vector>
#include <map>
#include <unordered_map>
#include <numeric>
#include <string>
#include <memory>
#include <optional>
#include <variant>
#include <algorithm>
#include <functional>
#include <iostream>
#include <stdexcept>

#define MAX_ITEMS 64
#define STRINGIFY(x) #x
#define CONCAT(a, b) a##b
#if defined(__cplusplus) && __cplusplus >= 201703L
#define HAS_CPP17 1
#endif
#pragma once
#pragma mark - Types

// ── C++ namespaces, constants, aliases ──
namespace warehouse {
namespace detail { constexpr int kPad = 4; }
inline namespace v1 { using Sku = std::string; }

constexpr int kMaxQty = 1'000;
constexpr double kPi = 3.141'592;
const unsigned long long kBig = 18446744073709551615ULL;
constexpr int kHex = 0xFF, kBin = 0b1010, kOct = 0755;
constexpr float kF = 1.5f;
constexpr long double kLD = 2.5e-3L;
constexpr bool kYes = true;
constexpr std::nullptr_t kNull = nullptr;
constexpr char kCh = 'x';
constexpr char16_t kU16 = u'x';
constexpr char32_t kU32 = U'x';

using ItemMap = std::map<Sku, int>;
typedef std::vector<int> IntVec;

// ── C++ types ──
enum class Zone : unsigned char { Cold, Dry = 5, Hazard };

struct LineItem {
    std::string sku;
    int quantity;
    double unitPrice;
    double total() const noexcept { return quantity * unitPrice; }
    bool operator==(const LineItem &o) const { return sku == o.sku; }
    auto operator<=>(const LineItem &) const = default;
};

template <typename T, std::size_t N = 8>
class Ring {
public:
    explicit Ring(T fill = T{}) : _items(N, fill) {}
    virtual ~Ring() = default;
    T &at(std::size_t i) { return _items[i % N]; }
    const T &at(std::size_t i) const { return _items[i % N]; }
    static constexpr std::size_t size() { return N; }
protected:
    std::vector<T> _items;
private:
    int _head = 0;
};

template <typename T>
requires std::is_arithmetic_v<T>
T clampTo(T v, T lo, T hi) { return v < lo ? lo : (v > hi ? hi : v); }

template <typename... Args>
auto sum(Args... args) { return (args + ...); }

class Shape { public: virtual double area() const = 0; virtual ~Shape() {} };
class Circle final : public Shape {
public:
    explicit Circle(double r) : r_(r) {}
    double area() const override { return kPi * r_ * r_; }
private:
    double r_;
};
}  // namespace warehouse

using namespace warehouse;

// ── Objective-C interface mixing C++ ──
@protocol Priced <NSObject>
- (double)total;
@end

@interface Basket : NSObject <Priced>
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, copy) NSString *label;
- (void)addSKU:(NSString *)sku quantity:(int)qty price:(double)price;
- (double)total;
- (std::vector<LineItem>)snapshot;
@end

@implementation Basket {
    std::vector<LineItem> _items;
    std::unique_ptr<Ring<int, 4>> _ring;
    std::map<std::string, int> _index;
}

- (instancetype)init {
    if ((self = [super init])) {
        _ring = std::make_unique<Ring<int, 4>>();
        _label = @"basket";
    }
    return self;
}

- (void)addSKU:(NSString *)sku quantity:(int)qty price:(double)price {
    _items.push_back({ sku.UTF8String, qty, price });
    _index[sku.UTF8String] = (int)_items.size() - 1;
}

- (double)total {
    return std::accumulate(_items.begin(), _items.end(), 0.0,
                           [](double acc, const LineItem& i) { return acc + i.total(); });
}

- (NSUInteger)count { return _items.size(); }
- (std::vector<LineItem>)snapshot { return _items; }

// ── Lambdas, auto, ranges, structured bindings ──
- (void)modern {
    auto square = [](int x) -> int { return x * x; };
    int base = 10;
    auto byRef = [&base](int x) mutable { base += x; return base; };
    auto byVal = [=](int x) { return x + base + (int)_items.size(); };
    auto generic = [](auto a, auto b) { return a + b; };
    std::function<int(int)> fn = square;
    std::vector<int> v{3, 1, 2};
    std::sort(v.begin(), v.end(), std::greater<>());
    for (const auto &x : v) { (void)x; }
    for (auto &&[k, val] : _index) { (void)k; (void)val; }
    if (auto it = _index.find("A-100"); it != _index.end()) { (void)it; }
    std::optional<int> opt = std::nullopt;
    std::variant<int, std::string> var = std::string("text");
    auto *raw = new int[4]{1, 2, 3, 4};
    delete[] raw;
    int *p = nullptr;
    int &ref = base;
    int &&rval = 5;
    int moved = std::move(rval);
    static_assert(sizeof(int) >= 4, "int too small");
    int cast1 = static_cast<int>(3.7);
    auto cast2 = reinterpret_cast<uintptr_t>(p);
    auto cast3 = const_cast<int *>(&base);
    (void)generic; (void)byRef; (void)byVal; (void)fn; (void)opt; (void)var; (void)ref; (void)moved;
    (void)cast1; (void)cast2; (void)cast3;
}

// ── Strings and literals ──
- (void)literals {
    std::string s1 = "narrow \"quoted\" \t tab \x41 \101 é";
    std::string s2 = R"(raw string with "quotes" and \n kept)";
    std::string s3 = R"delim(raw with )" inside)delim";
    std::wstring w = L"wide";
    std::u8string u8 = u8"utf8";
    NSString *ns = @"objc string";
    NSArray *arr = @[ @1, @2.5, @YES, @"s", @{ @"k": @[ @3 ] } ];
    NSNumber *boxed = @(MAX_ITEMS);
    SEL sel = @selector(addSKU:quantity:price:);
    (void)s1; (void)s2; (void)s3; (void)w; (void)u8; (void)ns; (void)arr; (void)boxed; (void)sel;
}

// ── Exceptions and control flow ──
- (void)errors {
    try {
        throw std::runtime_error("bad");
    } catch (const std::exception &e) {
        NSLog(@"c++ error %s", e.what());
    } catch (...) {
        NSLog(@"unknown");
    }
    @try {
        @throw [NSException exceptionWithName:@"Bad" reason:@"input" userInfo:nil];
    } @catch (NSException *e) {
        NSLog(@"objc error %@", e.reason);
    } @finally {
        NSLog(@"done");
    }
    switch (Zone::Dry) {
        case Zone::Cold: break;
        case Zone::Dry: [[fallthrough]];
        default: break;
    }
}
@end

// ── Free functions ──
[[nodiscard]] static inline int addInts(int a, int b) noexcept { return a + b; }
extern "C" int c_linkage(int x) { return x; }

int main() {
    @autoreleasepool {
        Basket *b = [Basket new];
        [b addSKU:@"A-100" quantity:2 price:4.5];
        [b addSKU:@"C-300" quantity:1 price:99.0];
        NSLog(@"%lu items, total %.2f", (unsigned long)b.count, b.total);   // 2 items, 108.00
        std::cout << "done " << STRINGIFY(abc) << std::endl;
    }
    return 0;
}

// ── More Objective-C++: templates, operators, concepts and C++ keywords ──
namespace alias_ns = warehouse::detail;
using warehouse::Sku;
using Callback = std::function<void(int)>;

template <typename T> struct Traits { static constexpr bool value = false; };
template <> struct Traits<int> { static constexpr bool value = true; };
template <typename T, typename U> struct Traits<std::pair<T, U>> { using type = T; };
template <typename T> inline constexpr bool is_int_v = Traits<T>::value;
template <template <typename...> class C, typename T> using Wrap = C<T>;
template <typename T> concept Numeric = std::is_arithmetic_v<T>;
template <Numeric T> T twice(T v) { return v * 2; }
template <class T, class = std::enable_if_t<std::is_integral_v<T>>> T only_int(T v) { return v; }
template <auto N> struct FixedN { static constexpr auto value = N; };
extern template struct Traits<long>;
template struct Traits<char>;

struct Vec {
    double x = 0, y = 0;
    Vec() = default;
    Vec(double a, double b) : x(a), y(b) {}
    Vec(const Vec &) = default;
    Vec(Vec &&) noexcept = default;
    Vec &operator=(const Vec &) = delete;
    Vec operator+(const Vec &o) const { return {x + o.x, y + o.y}; }
    Vec &operator+=(const Vec &o) { x += o.x; y += o.y; return *this; }
    bool operator==(const Vec &) const = default;
    double &operator[](int i) { return i ? y : x; }
    explicit operator bool() const { return x != 0 || y != 0; }
    friend std::ostream &operator<<(std::ostream &os, const Vec &v) { return os << v.x << "," << v.y; }
    friend class Friendly;
    static Vec zero() { return {}; }
    mutable int cache = 0;
    union { int i; float f; } u;
    struct Inner { int deep; } inner;
    enum Kind { A, B } kind = A;
    int bits : 3;
    int : 0;
    virtual void v() {}
    void *operator new(std::size_t n) { return ::operator new(n); }
    void operator delete(void *p) noexcept { ::operator delete(p); }
};

constexpr int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
consteval int ce() { return 1; }
constinit int ci = 5;
inline int in_line = 1;
thread_local int tl = 0;
volatile int vol = 0;
auto trailing(int a) -> decltype(a + 1) { return a + 1; }
decltype(auto) dec_auto(int &a) { return (a); }
void noexcept_fn() noexcept(false);
alignas(16) char buffer[16];
static_assert(alignof(buffer) == 16 || true);
extern "C" { int c_block(void); }
int Vec::* member_ptr = nullptr;
void (Vec::*method_ptr)() = &Vec::v;

@interface Mixed : NSObject
@property (nonatomic) std::shared_ptr<Vec> vec;
- (std::map<std::string, int>)counts;
- (void)takes:(const std::vector<int> &)v lambda:(void (^)(std::string))cb;
@end

@implementation Mixed
- (std::map<std::string, int>)counts { return {{"a", 1}}; }
- (void)takes:(const std::vector<int> &)v lambda:(void (^)(std::string))cb {
    for (int x : v) { cb(std::to_string(x)); }
    auto l = [self, v]() mutable { return [self counts].size() + v.size(); };
    auto gen = []<typename T>(T t) { return t; };
    int arr[] = {1, 2, 3};
    for (auto [i, j] = std::pair{0, 1}; i < 3; ++i) { (void)j; }
    if constexpr (is_int_v<int>) { (void)l; }
    switch (auto k = arr[0]; k) { case 1: break; default: break; }
    bool b = typeid(int) == typeid(long) && noexcept(1 + 1);
    const char *raw = R"x(raw)x";
    auto lit = 5ull + 10ull;
    (void)gen; (void)b; (void)raw; (void)lit;
    co_await_demo:;
}
@end

#if __has_include(<coroutine>)
#include <coroutine>
#endif

// ── C++20 / C++23 / C++26 features inside Objective-C++ ──
#include <expected>
#include <span>
#include <ranges>
#include <concepts>
#include <format>
#include <bit>
#include <compare>
#include <utility>
#include <tuple>
#include <string_view>

#ifdef NEVER_SET
#elifdef HAS_CPP17
#define CPP17_ELIFDEF 1
#elifndef HAS_CPP20
#define CPP17_ELIFNDEF 1
#endif

namespace modern {
// concepts, requires-expressions and constrained auto
template <typename T> concept Addable = requires(T a, T b) { { a + b } -> std::convertible_to<T>; };
template <typename T> concept HasSize = requires(const T &t) { t.size(); requires std::integral<decltype(t.size())>; typename T::value_type; };
void takes_addable(Addable auto a) { (void)a; }
template <std::integral T> constexpr T half(T v) requires (sizeof(T) >= 2) { return v / 2; }

// deducing this (C++23), static operator() and operator[] (C++23), multidimensional subscript
struct Widget {
    int value = 0;
    int get(this const Widget &self) { return self.value; }
    template <typename Self> auto &&data(this Self &&self) { return std::forward<Self>(self).value; }
    static int operator()(int x) { return x + 1; }
    static int operator[](int i) { return i; }
    int &operator[](int r, int c) { return value; }
};

// std::expected, if consteval, auto(x) decay copy, [[assume]]
std::expected<int, std::string> parse(std::string_view s) {
    if consteval { return 0; } else { if (s.empty()) return std::unexpected("empty"); }
    return static_cast<int>(s.size());
}
int decay_copy(const int &x) { return auto(x) + auto{x}; }
int assume_demo(int x) { [[assume(x > 0)]]; return x; }

// ranges, views, std::format, coroutines keywords, three-way comparison, designated initialisers
void ranges_demo() {
    std::vector<int> v{1, 2, 3, 4};
    auto evens = v | std::views::filter([](int x) { return x % 2 == 0; }) | std::views::transform([](int x) { return x * x; });
    for (int x : evens) { (void)x; }
    auto s = std::format("{} {:>5} {:08.3f} {:#x}", 1, "ab", 3.14159, 255);
    std::span<int> sp{v};
    auto ord = 1 <=> 2;
    struct P { int a; int b; } p{.a = 1, .b = 2};
    auto [a, b] = p;
    (void)s; (void)sp; (void)ord; (void)a; (void)b;
}

// C++26 (clang 21): pack indexing, deleted-with-reason, placeholder `_`, #embed
template <typename... Ts> auto first_of(Ts... ts) { return ts...[0]; }
void deleted_reason() = delete("do not call");
void placeholder() { int _ = 1; int _ = 2; }
}  // namespace modern

// ── Objective-C++ specifics: blocks vs lambdas, ARC with C++ members, bridging ──
@interface Bridge : NSObject
@property (nonatomic, copy) void (^onDone)(const std::string &);
- (void)run:(std::function<void(NSString *)>)callback;
- (std::optional<int>)maybe;
+ (instancetype)shared;
@end

@implementation Bridge {
    std::vector<__strong NSString *> _names;
    std::unordered_map<std::string, __weak id> _weak;
}
+ (instancetype)shared { static Bridge *b = [Bridge new]; return b; }
- (void)run:(std::function<void(NSString *)>)callback {
    __block int counter = 0;
    void (^block)(void) = ^{ counter++; callback(@"x"); };
    auto lambda = [block]() { block(); };
    lambda();
    dispatch_async(dispatch_get_main_queue(), ^{ NSLog(@"%d", counter); });
    if (@available(macOS 13.0, *)) { NSLog(@"available"); }
}
- (std::optional<int>)maybe { return std::nullopt; }
@end
