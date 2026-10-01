/*
 * C23 — syntax showcase (ISO/IEC 9899:2024)
 * sample.c - warehouse stock management, exercising C99 through C23 syntax.
 *
 * Doxygen-style comments are used throughout.
 * TODO: replace the linear search with a hash table.
 * FIXME: restock() does not check for overflow.
 */

// ── Preprocessor ────────────────────────────────────────────────────
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stddef.h>
#include <limits.h>
#include <float.h>
#include <math.h>
#include <ctype.h>
#include <errno.h>
#include <assert.h>
#include <setjmp.h>
#include <time.h>

#define MAX_BUFFER   256
#define GREETING     "Hello, warehouse"
#define SQUARE(x)    ((x) * (x))
#define MAX(a, b)    ((a) > (b) ? (a) : (b))
#define STRINGIFY(x) #x
#define CONCAT(a, b) a##b
#define LOG(fmt, ...) fprintf(stderr, "[%s:%d] " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__)
#define MULTILINE(x) \
    do {             \
        (void)(x);   \
    } while (0)

#ifndef VERSION
#  define VERSION "1.0.0"
#endif

#if defined(__linux__)
#  define PLATFORM "linux"
#elif defined(__APPLE__) && !defined(FORCE_GENERIC)
#  define PLATFORM "apple"
#else
#  define PLATFORM "other"
#endif

#ifdef DEBUG
#  undef DEBUG
#endif
#pragma once
#pragma pack(push, 1)
#pragma pack(pop)
#if 0
#  error "disabled"
#endif
#line 100 "renamed.c"

// ── Types ───────────────────────────────────────────────────────────
typedef unsigned char byte;
typedef uint32_t sku_t;
typedef int (*comparator_t)(const void *, const void *);

enum Status { STATUS_OK = 0, STATUS_FAIL = 1, STATUS_PENDING = 1 << 4 };
typedef enum { LOW, MEDIUM, HIGH } Level;

struct Item {
    sku_t sku;
    char name[MAX_BUFFER];
    double price;
    unsigned int quantity : 12;   /* bit-field */
    unsigned int flags    : 4;
    struct Item *next;
};

typedef struct {
    int id;
    char name[MAX_BUFFER];
    double balance;
    struct Item *items;
} Account;

union Value {
    int32_t i;
    float f;
    uint8_t bytes[4];
};

typedef struct Node Node;
struct Node {
    Node *left, *right;
    int key;
};

// ── Globals and qualifiers ──────────────────────────────────────────
static const int REORDER_POINT = 25;
static volatile sig_atomic_t g_interrupted = 0;
extern int errno_copy;
_Thread_local int tls_counter;
static _Atomic int atomic_counter = 0;
const char *const names[] = {"alpha", "beta", "gamma", NULL};
int matrix[3][3] = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
_Static_assert(sizeof(int) >= 4, "int must be at least 32 bits");

// ── Literals ────────────────────────────────────────────────────────
int integers[] = {42, -7, 0755, 0xFF, 0XdeadBEEF, 0b1010, 100u, 100UL, 100ull, 1234567890123LL};
double reals[] = {3.14, 1e10, 1.5e-3, .5, 5., 0x1.8p1, 1.0f, 2.5L, INFINITY, NAN};
char chars[] = {'a', '\n', '\t', '\\', '\'', '\0', '\x41', '\101', L'é'};
const char *strings[] = {
    "plain", "escapes: \t \n \" \\ \x41 \101 é \U0001F600",
    "concatenated " "adjacent " "literals",
    L"wide string", u8"utf-8 string", u"utf-16", U"utf-32",
};

// ── Function prototypes ─────────────────────────────────────────────
static double compute_interest(double principal, double rate);
int sum_values(int count, ...);
void process(const int *restrict in, int *restrict out, size_t n);
static inline int clamp(int v, int lo, int hi);
_Noreturn void die(const char *msg); // _Noreturn: deprecated in C23, use [[noreturn]]

// ── Functions ───────────────────────────────────────────────────────
/**
 * Computes compound interest.
 * @param principal starting balance
 * @param rate      rate per period
 * @return the new balance
 */
static double compute_interest(double principal, double rate) {
    double result = principal * (1.0 + rate);
    return result;
}

static inline int clamp(int v, int lo, int hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

int sum_values(int count, ...) {
    va_list args;
    va_start(args, count);
    int total = 0;
    for (int i = 0; i < count; i++) {
        total += va_arg(args, int);
    }
    va_end(args);
    return total;
}

void process(const int *restrict in, int *restrict out, size_t n) {
    for (size_t i = 0; i < n; ++i) out[i] = in[i] << 1;
}

_Noreturn void die(const char *msg) {
    fprintf(stderr, "fatal: %s (%s)\n", msg, strerror(errno));
    exit(EXIT_FAILURE);
}

static int compare_items(const void *a, const void *b) {
    const struct Item *x = a, *y = b;
    return (x->price > y->price) - (x->price < y->price);
}

struct Item *find_item(struct Item *head, sku_t sku) {
    for (struct Item *it = head; it != NULL; it = it->next) {
        if (it->sku == sku) return it;
    }
    return NULL;
}

// ── Main ────────────────────────────────────────────────────────────
int main(int argc, char **argv) {
    Account acct = {.id = 42, .balance = 1000.50, .items = NULL};
    strncpy(acct.name, GREETING, MAX_BUFFER - 1);
    acct.name[MAX_BUFFER - 1] = '\0';

    double updated = compute_interest(acct.balance, 0.05);
    printf("Account %d (%s): %.2f %zu %5ld %-8s|%c|%x|%%\n", acct.id, acct.name, updated, sizeof acct, 123L, "left", 'c', 255u);

    // Operators
    int a = 5, b = 3, c;
    c = a + b - a * b / 2 % 3;
    c += 1; c -= 1; c *= 2; c /= 2; c %= 5;
    c <<= 1; c >>= 1; c &= 0xF; c |= 0x1; c ^= 0x3;
    c = (a & b) | (a ^ b) | ~a;
    c = a << 2 | b >> 1;
    c = (a > b) && (b < 10) || !(a == b) && (a != b) && (a >= b || a <= b);
    c = a > b ? a : b;
    c = (c++, c--, ++c, --c);
    int *p = &c;
    *p = 7;
    struct Item item = {.sku = 100, .price = 9.99, .quantity = 3};
    struct Item *ip = &item;
    ip->quantity += 1;
    (*ip).price *= 1.1;
    size_t sz = sizeof(struct Item) + sizeof(int[10]) + _Alignof(double);
    void *raw = malloc(sz);
    int *arr = (int *)raw;
    arr[0] = *(arr + 1);
    bool flag = true && !false;
    union Value v = {.f = 1.5f};
    int compound = ((struct Item){.sku = 1}).sku;
    _Generic(c, int: "int", double: "double", default: "other");
    free(raw);

    // Control flow
    if (c > 0) {
        puts("positive");
    } else if (c < 0) {
        puts("negative");
    } else {
        puts("zero");
    }

    switch (item.flags) {
        case 0:
        case 1:
            puts("low");
            break;
        case STATUS_PENDING:
            puts("pending");
            /* fall through */
        default:
            puts("other");
    }

    for (int i = 0; i < 10; i++) {
        if (i == 3) continue;
        if (i == 8) break;
    }

    int n = 0;
    while (n < 5) n++;
    do { n--; } while (n > 0);

retry:
    if (++n < 3) goto retry;

    qsort(arr, 0, sizeof *arr, (comparator_t)compare_items);

    Level level = (Level)(c % 3);
    enum Status status = STATUS_OK;
    if (status != STATUS_OK) {
        fprintf(stderr, "failure\n");
        return EXIT_FAILURE;
    }

    LOG("done %d %s", c, PLATFORM);
    return 0;
}

// ── Further constructs ──────────────────────────────────────────────
#if __has_include("local_header.h")
#  include "local_header.h"
#endif
#include_next <stdlib.h>
#if __has_include("objc_style.h")
#  import "objc_style.h"
#endif
#define STR(x) #x
#define XSTR(x) STR(x)
#define PASTE3(a, b, c) a##b##c
#define VARIADIC(...) printf(__VA_ARGS__)
#define OPT_VARIADIC(fmt, ...) printf(fmt __VA_OPT__(,) __VA_ARGS__)
#define UNUSED(x) ((void)(x))
#define ARRAY_LEN(a) (sizeof(a) / sizeof((a)[0]))
#define CONTAINER_OF(ptr, type, member) ((type *)((char *)(ptr) - offsetof(type, member)))
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define UNLIKELY(x) __builtin_expect(!!(x), 0)
#define ATTR_PACKED __attribute__((packed))
#define ATTR_PRINTF(a, b) __attribute__((format(printf, a, b)))
#if defined(__GNUC__) || defined(__clang__)
#  define NOINLINE __attribute__((noinline))
#elif defined _MSC_VER
#  define NOINLINE __declspec(noinline)
#endif
#if __STDC_VERSION__ >= 201112L && !defined(__STDC_NO_ATOMICS__)
#  define HAVE_ATOMICS 1
#endif
#if __has_include(<threads.h>) && __has_attribute(unused) && __has_builtin(__builtin_expect)
#  define HAVE_THREADS 1
#endif
#ifdef __cplusplus
extern "C" {
int cpp_visible(void);
}
#endif
#warning "diagnostic via #warning"
#ident "warehouse build"
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic pop
#pragma clang diagnostic ignored "-Wformat"
#pragma omp parallel for
#pragma mark - Section marker
#pragma region Folded
#pragma endregion
#pragma weak optional_symbol
#pragma message("note")
#pragma STDC FP_CONTRACT ON
#undef STR

// Type-system oddities
typedef struct ATTR_PACKED { uint8_t tag; uint16_t len; } Header;
typedef int (*op_fn)(int, int);
typedef int (*table_t[4])(void);
typedef void (*signal_handler_t)(int);
typedef unsigned long long ull_t;
typedef long double ld_t;
typedef _Bool boolean_t;
typedef float _Complex complex_f;
typedef __int128 i128;
typedef _Float16 half_t;
typedef uint_least16_t utf16_t;
typedef uint_least32_t utf32_t;
typedef struct Opaque Opaque;
typedef enum : uint8_t { SMALL_A = 1, SMALL_B } SmallEnum;
struct Flexible { size_t n; int data[]; };
struct Aligned { _Alignas(16) char buf[16]; alignas(8) int x; };
struct Anonymous { union { int i; float f; }; struct { short a, b; }; };
union Tagged { struct { int type; } header; struct { int type; double d; } real; };
enum { ANON_ONE = 1, ANON_TWO, ANON_BIG = 1L << 20 };

// Declarators
int (*fn_ptr)(const char *, ...) = NULL;
int (*array_of_fn[3])(void);
int (*(*complex_decl)(int))[5];
char *(*(*ptr_to_fn_returning_ptr)(void))[8];
const volatile unsigned long int *restrict cvp;
static int arr2d[2][3] = {[0] = {1, 2, 3}, [1][2] = 6};
int designated[10] = {[0] = 1, [5] = 6, [9] = 10};
char s[] = "tentative";
extern const char *const g_names[];
inline int always(void) { return 1; }
static _Thread_local int tl = 0;
thread_local int tl2 = 0;
constexpr int CE = 42;
static_assert(sizeof(long) >= 4, "long width");
typeof(int) typeof_var = 3;
typeof_unqual(const int) typeof_var2 = 4;
__typeof__(typeof_var) gnu_typeof;
__auto_type inferred = 3.0;
nullptr_t np;
bool true_false = true;
_BitInt(24) bits24;
unsigned _BitInt(8) ubits8;

// Statement forms
void statements(int n, char *s) {
    int x = 0, y = 1;
    int *p = &x, **pp = &p;
    int v[5] = {0};
    char c = 'x';
    wchar_t w = L'w';
    uint_least16_t c16 = u'x';
    uint_least32_t c32 = U'x';
    char utf8c = u8'x';
    const char *str = "str" "cat";
    const wchar_t *wstr = L"wide";
    double d = 0x1.fp3 + 1e-9 + 1.f + 0.5L + 07 + 0b11 + 1'000;
    float h = 1.0f;
    long long ll = 9223372036854775807LL;
    unsigned long ul = 0xFFFFFFFFUL;
    size_t sz = sizeof(int) * 8 + sizeof v;
    ptrdiff_t diff = &v[3] - &v[0];
    x = (int)d + (long)h;
    x = (x > 0) ? x : -x;
    x = y++ + ++y - y-- - --y;
    x = ~x ^ (x & y) | (x << 1) >> 2;
    x = !x && (y || x);
    x = *p + **pp + *(p + 1) + p[0] + (*p)++;
    x = n ? n : 0;
    x = (1, 2, 3);
    x = _Alignof(max_align_t) + alignof(int);
    x = offsetof(struct Flexible, data);
    x = __builtin_popcount(0xFF) + __builtin_clz(1);
    asm volatile("nop" ::: "memory");
    __asm__("" : "=r"(x) : "r"(y) : "cc");
    for (;;) { break; }
    for (int i = 0, j = 10; i < j; i++, j--) { if (i == 2) continue; }
    switch (n) {
        case 1 ... 3: x = 1; break;
        case 4: { x = 2; } break;
        default: ;
    }
    goto end;
    {
        int shadowed = 1;
        (void)shadowed;
    }
    if (x) ; else { }
    register int fast_counter = 0;
    auto int legacy_auto = 1;
    do x--; while (x > 0);
    while (0) ;
    lbl:
    x = __LINE__ + sizeof(__FILE__) + __STDC_VERSION__ + __COUNTER__;
    puts(__func__);
    puts(__DATE__ " " __TIME__);
    end:
    return;
}

// Function forms
void noreturn_fn(void) __attribute__((noreturn));
// K&R-style definitions (int f(a, b) int a; ...) were REMOVED in C23, so none appear here.
static inline __attribute__((always_inline)) int gnu_attr(int v) { return v; }
[[nodiscard]] int cpp_attr(void);
[[deprecated("use gnu_attr")]] int old_api(void);
[[maybe_unused]] static int unused_helper(void) { return 0; }
int vla_param(int n, int a[static n]);
void vla_demo(int n) { int vla[n]; (void)vla; }
int (*get_handler(int sel))(int, int) { return sel ? NULL : NULL; }
int variadic_demo(const char *fmt, ...) ATTR_PRINTF(1, 2);
int main2(void) { return EXIT_SUCCESS; }
// TODO: add _Generic dispatch for numeric kinds.

// ── C23 additions ───────────────────────────────────────────────────
#ifdef ALPHA
#  define BRANCH 1
#elifdef BETA
#  define BRANCH 2
#elifndef GAMMA
#  define BRANCH 3
#else
#  define BRANCH 4
#endif

// Attributes with the standard [[ ]] syntax, plain and vendor-prefixed
[[noreturn]] void fatal_exit(void);
[[gnu::unused, gnu::cold]] static int vendor_attr(void) { return 0; }
[[clang::always_inline]] static inline int clang_attr(int v) { return v; }
[[__maybe_unused__]] static int dunder_attr;
[[reproducible]] int pure_fn(const char *s);
[[unsequenced]] int pure_fn2(int v);
int attributed_decl [[maybe_unused]] = 1;
int *[[gnu::unused]] attributed_ptr;
signed int explicit_signed = -1;
signed char explicit_signed_char = -1;
nullptr_t null_object = nullptr;
int *null_ptr = nullptr;

// Enumerations with fixed underlying type; empty initialiser
enum Colour : unsigned char { RED, GREEN = 5, BLUE };
enum Wide : long long { HUGE_VALUE_ENUM = 1LL << 40 };
struct EmptyInit { int a; int b; };
struct EmptyInit empty_init = {};
int empty_array[3] = {};

// Binary literals, digit separators, bit-precise integers, #embed
int c23_literals[] = {0b1010'1010, 1'000'000, 0x7FFF'FFFF, 0B11};
unsigned _BitInt(128) wide_bits = 0xFFFFuwb;
_BitInt(8) narrow_bits = 3wb;
#if __has_embed("logo.bin") == 1
static const unsigned char logo[] = {
#embed "logo.bin"
};
#endif

// Keywords promoted in C23
static_assert(true, "true and false are keywords now");
alignas(16) static char aligned_buf[32];
thread_local static int thread_counter;
constexpr double PI_APPROX = 3.14159;
bool c23_bool = false;
typeof(PI_APPROX) another = 2.0;

// Unnamed parameters and abstract declarators
int unnamed_param(int, double);
int unnamed_def(int, double) { return 0; }
int (*abstract_fn)(int (*)(int), char (*)[4]);
size_t abstract_sizes = sizeof(int (*)(void)) + sizeof(int (*)[3]) + sizeof(int (*));
void takes_fn(void (*)(void), int (*)[5], int *(*)(void));
int variably_modified(int n, int (*arr)[n]);

// Compiler extensions (GNU, Clang, MSVC) — grammar-known, not standard C
int gnu_range_init[10] = {[0 ... 4] = 1, [5 ... 9] = 2};
int ext_value(void) { return __extension__ ({ int tmp = 3; tmp * 2; }); }
void gnu_asm_goto(int v) {
    asm goto("jmp %l0" : : : : target_label);
target_label:
    return;
}
int gnu_statement_expr(void) {
    int r = ({ int a = 1; int b = 2; a + b; });
    switch (r) { case 1: [[fallthrough]]; default: break; }
    return r;
}

__declspec(dllexport) int ms_exported(void);
__declspec(align(16)) struct MsAligned { int x; };
int __cdecl ms_cdecl(void);
int __stdcall ms_stdcall(void);
int __fastcall ms_fastcall(void);
char *__ptr32 ms_ptr32;
char *__ptr64 ms_ptr64;
char *__restrict ms_restrict;
char *__sptr ms_sptr;
char *__uptr ms_uptr;
char *__unaligned ms_unaligned;
int __based(base_segment) *ms_based;
void ms_seh(void) {
    __try {
        ms_exported();
        __leave;
    } __except (1) {
        puts("exception");
    }
    __try {
        ms_exported();
    } __finally {
        puts("cleanup");
    }
}

// <stdnoreturn.h> macro spelling: obsolescent since C23 (deprecated), still accepted
#include <stdnoreturn.h>
noreturn void legacy_noreturn(void);
