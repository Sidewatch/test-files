// Objective-C 2.0 (clang 21, C23 / gnu23) — syntax showcase: classes, protocols, categories, blocks, literals and runtime calls.
/* A block comment
   over several lines. */
/// A documentation comment.
/*!
 * @brief A headerdoc block.
 * @param number The order number.
 * @return The formatted description.
 */
// TODO: persist orders to disk
// FIXME: the revenue sum ignores currency

#import <Foundation/Foundation.h>
#import "Inventory.h"
#include <stdlib.h>
#include <objc/runtime.h>
@import Foundation;

#define MAX_ORDERS 100
#define SQUARE(x) ((x) * (x))
#define LOG(fmt, ...) NSLog(@"[inventory] " fmt, ##__VA_ARGS__)
#ifdef DEBUG
#define DEBUG_ONLY 1
#else
#define DEBUG_ONLY 0
#endif
#if __has_feature(objc_arc) && !defined(NO_ARC)
#pragma mark - ARC enabled
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_BEGIN

// ── Types, constants, enums ──
typedef NS_ENUM(NSInteger, OrderStatus) { OrderStatusPending, OrderStatusPaid, OrderStatusCancelled };
typedef NS_OPTIONS(NSUInteger, OrderFlags) {
    OrderFlagGift = 1 << 0,
    OrderFlagRush = 1 << 1,
    OrderFlagFragile = 0x4,
};
typedef void (^OrderHandler)(NSString *message, BOOL success);
typedef struct { double lat; double lon; } Coordinate;
typedef union { int i; float f; } Number;
typedef enum { Cold, Dry } Zone;

static NSString *const kOrderDidChangeNotification = @"OrderDidChange";
extern NSString *const OrderErrorDomain;
static const NSInteger kReorderPoint = 25;
static int counter = 0;

// ── Protocol ──
@protocol Shippable <NSObject>
@required
- (NSString *)trackingNumber;
@optional
- (void)shipWithCompletion:(OrderHandler)completion;
@property (nonatomic, readonly) double weight;
@end

// ── Class interface ──
@class Warehouse;

@interface Order : NSObject <Shippable, NSCopying, NSSecureCoding>
@property (nonatomic, readonly) NSInteger number;
@property (nonatomic, readonly, strong) NSDecimalNumber *total;
@property (nonatomic, assign) OrderStatus status;
@property (nonatomic, copy, nullable) NSString *note;
@property (nonatomic, weak) Warehouse *warehouse;
@property (atomic, strong, getter=isPaid, setter=setPaid:) NSNumber *paid;
@property (class, nonatomic, readonly) NSInteger instanceCount;
- (instancetype)initWithNumber:(NSInteger)number total:(NSDecimalNumber *)total NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)orderWithNumber:(NSInteger)number;
- (void)applyDiscount:(double)percent reason:(nullable NSString *)reason, ... NS_REQUIRES_NIL_TERMINATION;
@end

// ── Class extension ──
@interface Order ()
@property (nonatomic, strong) NSString *internalNote;
@end

// ── Class implementation ──
@implementation Order {
    NSMutableArray<NSString *> *_history;
    NSInteger _revision;
}

@synthesize note = _note;
@dynamic weight;

static NSInteger _instanceCount = 0;

+ (NSInteger)instanceCount { return _instanceCount; }

+ (instancetype)orderWithNumber:(NSInteger)number {
    return [[self alloc] initWithNumber:number total:NSDecimalNumber.zero];
}

- (instancetype)initWithNumber:(NSInteger)number total:(NSDecimalNumber *)total {
    if ((self = [super init])) {
        _number = number;
        _total = total;
        _status = OrderStatusPending;
        _history = [NSMutableArray array];
        _instanceCount++;
    }
    return self;
}

- (void)dealloc { _instanceCount--; }

- (NSString *)description {
    return [NSString stringWithFormat:@"#%ld %@ %5.2f %-8s %c %%", (long)self.number, self.total, 1.5, "name", 'x'];
}

- (NSString *)trackingNumber { return @"TRK-0001"; }

- (id)copyWithZone:(nullable NSZone *)zone { return self; }

+ (BOOL)supportsSecureCoding { return YES; }

- (void)applyDiscount:(double)percent reason:(nullable NSString *)reason, ... {
    va_list args;
    va_start(args, reason);
    NSString *extra = va_arg(args, NSString *);
    va_end(args);
    LOG(@"discount %.1f%% %@ %@", percent, reason, extra);
}

// ── Literals ──
- (void)literals {
    NSString *str = @"plain \"quoted\" \n tab:\t unicode:é \\ back";
    NSString *joined = @"concatenated " @"literals";
    NSNumber *i = @42;
    NSNumber *f = @3.14;
    NSNumber *d = @1.5e-3;
    NSNumber *hex = @0xFF;
    NSNumber *bin = @0b101;
    NSNumber *oct = @0755;
    NSNumber *u = @42u;
    NSNumber *l = @42L;
    NSNumber *ul = @42UL;
    NSNumber *ff = @1.5f;
    NSNumber *yes = @YES;
    NSNumber *no = @NO;
    NSNumber *ch = @'c';
    NSNumber *boxed = @(MAX_ORDERS + 1);
    NSArray *array = @[ @1, @"two", @[ @3 ], @{ @"k": @4 } ];
    NSDictionary *dict = @{ @"name": @"widget", @"qty": @12, @"nested": @{ @"deep": @YES } };
    NSMutableArray *mutableArray = [@[ @1 ] mutableCopy];
    id first = array[0];
    id value = dict[@"name"];
    mutableArray[0] = @2;
    SEL sel = @selector(applyDiscount:reason:);
    SEL sel2 = NSSelectorFromString(@"description");
    Protocol *proto = @protocol(Shippable);
    Class cls = [Order class];
    Class cls2 = NSClassFromString(@"Order");
    const char *enc = @encode(Coordinate);
    char c = 'a';
    char esc = '\n';
    wchar_t w = L'w';
    const char *cstr = "C string with \x41 and \101 and \0";
    unsigned long long big = 18446744073709551615ULL;
    long double ld = 1.5L;
    NSLog(@"%@ %@ %@", str, joined, boxed);
    (void)i; (void)f; (void)d; (void)hex; (void)bin; (void)oct; (void)u; (void)l; (void)ul; (void)ff;
    (void)yes; (void)no; (void)ch; (void)first; (void)value; (void)sel; (void)sel2; (void)proto;
    (void)cls; (void)cls2; (void)enc; (void)c; (void)esc; (void)w; (void)cstr; (void)big; (void)ld;
}

// ── Control flow, blocks, exceptions ──
- (void)flow {
    BOOL ready = YES;
    id nothing = nil;
    Class none = Nil;
    void *null = NULL;
    if (ready && !nothing) { counter++; } else if (!ready || null) { counter--; } else { counter += 2; }
    for (int i = 0; i < 3; i++) { if (i == 1) continue; if (i == 2) break; }
    for (NSString *item in @[ @"a", @"b" ]) { NSLog(@"%@", item); }
    int n = 0;
    while (n < 3) n++;
    do { n--; } while (n > 0);
    switch (self.status) {
        case OrderStatusPending: NSLog(@"pending"); break;
        case OrderStatusPaid:
        case OrderStatusCancelled: NSLog(@"done"); break;
        default: break;
    }
    int tern = ready ? 1 : 0;
    int elvis = tern ?: 5;
    int shifted = (tern << 2) | (elvis >> 1) & 0xF ^ ~0;
    BOOL cmp = tern == 1 && elvis != 2 || tern <= 3 && elvis >= 0;
    (void)none; (void)shifted; (void)cmp;
    goto done;
done:
    @autoreleasepool {
        __block NSInteger total = 0;
        __weak typeof(self) weakSelf = self;
        __strong typeof(self) strongSelf = weakSelf;
        void (^adder)(NSInteger) = ^(NSInteger x) { total += x; };
        adder(5);
        NSArray<NSNumber *> *nums = @[ @3, @1, @2 ];
        NSArray *sorted = [nums sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
            return [a compare:b];
        }];
        [sorted enumerateObjectsUsingBlock:^(NSNumber *o, NSUInteger idx, BOOL *stop) { *stop = idx > 1; }];
        dispatch_async(dispatch_get_main_queue(), ^{ [strongSelf description]; });
    }
    @try {
        @throw [NSException exceptionWithName:@"Bad" reason:@"input" userInfo:nil];
    } @catch (NSException *e) {
        NSLog(@"caught %@", e.reason);
    } @catch (id other) {
        @throw;
    } @finally {
        NSLog(@"cleanup");
    }
    @synchronized(self) { _revision++; }
}

// ── Messaging, KVC, runtime ──
- (void)messaging {
    NSString *s = [[NSString alloc] initWithFormat:@"%d", 5];
    NSUInteger len = [s length] + s.length;
    id r = [self performSelector:@selector(description)];
    [(id)self.warehouse setValue:@1 forKey:@"count"];
    id v = [self valueForKeyPath:@"total.doubleValue"];
    BOOL responds = [self respondsToSelector:@selector(trackingNumber)] && [self conformsToProtocol:@protocol(Shippable)];
    BOOL kind = [self isKindOfClass:[Order class]] || [self isMemberOfClass:[NSObject class]];
    objc_setAssociatedObject(self, "key", s, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id obj = objc_getAssociatedObject(self, "key");
    unsigned int count = 0;
    Method *methods = class_copyMethodList([self class], &count);
    free(methods);
    (void)len; (void)r; (void)v; (void)responds; (void)kind; (void)obj;
}
@end

// ── Category ──
@interface NSArray (Orders)
- (NSDecimalNumber *)revenue;
@end

@implementation NSArray (Orders)
- (NSDecimalNumber *)revenue {
    NSDecimalNumber *sum = NSDecimalNumber.zero;
    for (Order *o in self) if (o.status == OrderStatusPaid) sum = [sum decimalNumberByAdding:o.total];
    return sum;
}
@end

// ── Generics ──
@interface Box<__covariant ObjectType> : NSObject
@property (nonatomic, strong) ObjectType content;
- (nullable ObjectType)unwrap;
@end

NS_ASSUME_NONNULL_END

// ── Functions ──
static inline NSInteger clampInt(NSInteger v, NSInteger lo, NSInteger hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        Order *a = [[Order alloc] initWithNumber:1 total:[NSDecimalNumber decimalNumberWithString:@"120.50"]];
        a.status = OrderStatusPaid;
        NSArray<Order *> *orders = @[a, [[Order alloc] initWithNumber:2 total:[NSDecimalNumber decimalNumberWithString:@"42"]]];
        [orders enumerateObjectsUsingBlock:^(Order *o, NSUInteger idx, BOOL *stop) { NSLog(@"%@", o); }];
        NSLog(@"revenue: %@", orders.revenue);
        if (@available(macOS 13.0, *)) { NSLog(@"modern"); }
    }
    return 0;
}

// ── More Objective-C: ivars, visibility, bridging, nullability and attributes ──
#define NS_SWIFT_NAME_DEMO(x) NS_SWIFT_NAME(x)
#undef MAX_ORDERS
#line 500 "generated.m"
#warning "demo warning"
#pragma once
#pragma GCC diagnostic ignored "-Wunused"
#pragma pack(push, 1)
#pragma pack(pop)

@compatibility_alias LegacyOrder Order;

@interface Ledger : NSObject <NSCopying> {
@public
    NSInteger publicCount;
@protected
    NSString *_protectedName;
@private
    NSMutableArray *_private;
@package
    int packageValue;
}
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, unsafe_unretained, nonnull) NSObject *owner;
@property (nonatomic, strong, null_resettable) NSString *title;
@property (nonatomic, readonly, class) Ledger *shared;
@property (nonatomic, copy) void (^onChange)(NSString * _Nullable value);
- (nullable instancetype)initWithName:(nonnull NSString *)name NS_SWIFT_NAME(init(name:));
- (void)deprecatedThing __attribute__((deprecated("use newThing")));
- (void)unavailableThing NS_UNAVAILABLE;
- (void)newThing API_AVAILABLE(macos(10.15), ios(13.0)) API_UNAVAILABLE(watchos);
- (NSArray<__kindof NSObject *> *)kinds;
- (void)handler:(void (^_Nullable)(NSError * _Nullable error))handler;
- (id<NSCopying, NSObject>)anyCopyable;
- (instancetype)initWith:(int)a and:(int)b NS_DESIGNATED_INITIALIZER;
+ (void)classMethod;
- (oneway void)fireAndForget;
- (bycopy id)copied:(inout NSError **)err out:(out NSString **)s in:(in NSString *)i;
@end

__attribute__((objc_subclassing_restricted))
@interface Sealed : NSObject @end

__attribute__((visibility("default"))) extern int exported_function(void);
static inline __attribute__((always_inline)) int fast(int x) { return x; }
void takes_cleanup(void) { __attribute__((cleanup(free))) char *p = NULL; (void)p; }
NS_INLINE int ns_inline(void) { return 0; }
FOUNDATION_EXPORT NSString *const LedgerNotification;
FOUNDATION_EXTERN const double LedgerVersionNumber;
NS_REFINED_FOR_SWIFT NS_ERROR_ENUM(OrderErrorDomain) { OrderErrorBad = 1 };
typedef NSString *LedgerKey NS_TYPED_EXTENSIBLE_ENUM;
typedef NS_CLOSED_ENUM(NSInteger, Direction) { DirectionUp, DirectionDown };
typedef struct __attribute__((aligned(8))) { int a; } Aligned;
typedef void (*FuncPtr)(int);
typedef int (^BlockType)(int, int);

@implementation Ledger {
    __weak id _weakRef;
    __unsafe_unretained id _unsafeRef;
    __strong id _strongRef;
}
@synthesize name = _name, title;
@dynamic owner;
+ (Ledger *)shared { static Ledger *s; static dispatch_once_t once; dispatch_once(&once, ^{ s = [Ledger new]; }); return s; }
- (nullable instancetype)initWithName:(nonnull NSString *)name { self = [super init]; if (self) _name = [name copy]; return self; }
- (id)copyWithZone:(NSZone *)zone { return [[[self class] allocWithZone:zone] initWithName:_name]; }
- (void)deprecatedThing {}
- (void)newThing {}
- (NSArray<__kindof NSObject *> *)kinds { return @[]; }
- (void)handler:(void (^)(NSError *))handler { handler(nil); }
- (id<NSCopying, NSObject>)anyCopyable { return @"x"; }
- (instancetype)initWith:(int)a and:(int)b { return [self init]; }
+ (void)classMethod {}
- (oneway void)fireAndForget {}
- (id)copied:(NSError **)err out:(NSString **)s in:(NSString *)i { return nil; }
- (void)bridging {
    CFStringRef cf = (__bridge CFStringRef)@"text";
    NSString *ns = (__bridge_transfer NSString *)CFStringCreateCopy(NULL, cf);
    CFTypeRef retained = (__bridge_retained CFTypeRef)ns;
    CFRelease(retained);
    NSString *fmt = [NSString stringWithFormat:@"%@ %d %ld %lu %lld %f %g %s %c %p %x %o %e %% %5.2f %-8@ %*d", ns, 1, 2L, 3UL, 4LL, 5.0, 6.0, "s", 'c', self, 255, 8, 1.5, 2.0, @"x", 3, 4];
    NSLog(@"%@", fmt);
    BlockType add = ^int(int a, int b) { return a + b; };
    int (^noArgs)(void) = ^{ return 5; };
    FuncPtr fp = NULL;
    NSString * __block blockVar = @"v";
    void (^recursive)(void) = nil;
    __block void (^weakRecursive)(void);
    weakRecursive = ^{ if (weakRecursive) weakRecursive(); };
    (void)add; (void)noArgs; (void)fp; (void)blockVar; (void)recursive;
    NSUInteger flags = OrderFlagGift | OrderFlagRush;
    if (flags & OrderFlagGift) flags &= ~OrderFlagGift;
    NSRange range = NSMakeRange(0, 5);
    CGFloat f = 1.0 / 3.0;
    NSInteger i = NSNotFound;
    NSTimeInterval t = 5.0;
    id<Shippable> shippable = nil;
    Class<NSObject> klass = Nil;
    char *buf = malloc(10);
    free(buf);
    (void)range; (void)f; (void)i; (void)t; (void)shippable; (void)klass;
}
@end

@interface Ledger (Private)
- (void)privateHelper;
@end
@implementation Ledger (Private)
- (void)privateHelper {}
@end

@protocol Observing <NSObject>
- (void)observe:(NSString *)keyPath change:(NSDictionary<NSKeyValueChangeKey, id> *)change;
@end

@interface Sealed () <Observing>
@end
@implementation Sealed
- (void)observe:(NSString *)keyPath change:(NSDictionary<NSKeyValueChangeKey, id> *)change {}
@end

union IntOrFloat { int i; float f; };
struct Pair { int a, b; };
enum Color { Red = 1, Green, Blue };
static const struct Pair kPair = { .a = 1, .b = 2 };
static int table[3][2] = { {1, 2}, {3, 4}, [2] = {5, 6} };
static char *names[] = { "a", "b", NULL };
_Static_assert(sizeof(int) >= 4, "int size");
_Atomic int atomicCounter;
_Thread_local int tls;
typeof(1) typed_var = 2;
__auto_type inferred = 3;
long long ll = 1LL << 40;
unsigned char uc = 0xFFu;
double dbl = 1.0e10 + 0x1p4;
float flt = 1.5f;
const char *kStr = "a" "b" "\n";
wchar_t wide_str[] = L"wide";

// ── Modern clang Objective-C: generics, ARC attributes, availability, C23 ──
#if __has_include(<Foundation/Foundation.h>) && __has_feature(objc_generics)
#define HAVE_GENERICS 1
#elifdef HAVE_GENERICS
#define C23_ELIFDEF 1
#elifndef NEVER_DEFINED
#define C23_ELIFNDEF 1
#else
#define NO_GENERICS 1
#endif
#ifdef __has_attribute
#endif

@class Forward1, Forward2;
@protocol ForwardProto;

@interface Cache<KeyType : id<NSCopying>, ObjectType : NSObject *> : NSObject
@property (nonatomic, strong, readonly) NSDictionary<KeyType, ObjectType> *storage;
- (nullable ObjectType)objectForKey:(KeyType)key;
- (void)setObject:(ObjectType)object forKey:(KeyType)key NS_REQUIRES_SUPER;
- (void)enumerate:(void (NS_NOESCAPE ^)(KeyType key, ObjectType object))block;
- (void)resultOrError:(void (^)(id _Nullable_result result, NSError * _Nullable error))completion;
@end

@implementation Cache
- (nullable id)objectForKey:(id)key { return self.storage[key]; }
- (void)setObject:(id)object forKey:(id)key {}
- (void)enumerate:(void (NS_NOESCAPE ^)(id, id))block { block(@"k", @"v"); }
- (void)resultOrError:(void (^)(id _Nullable_result, NSError * _Nullable))completion { completion(nil, nil); }
- (void)autoreleasing:(NSError * __autoreleasing *)error {
    if (error) { *error = [NSError errorWithDomain:@"d" code:1 userInfo:nil]; }
}
- (void)availability {
    if (@available(macOS 14.0, iOS 17.0, *)) { NSLog(@"new"); }
    else if (@available(macOS 12.0, *)) { NSLog(@"older"); }
    if (__builtin_available(macOS 13.0, *)) { NSLog(@"builtin"); }
    if (@available(*)) {}
}
@end

NS_HEADER_AUDIT_BEGIN(nullability, sendability)
NS_SWIFT_SENDABLE
@interface SendableThing : NSObject
@property (nonatomic, readonly, copy) NSString *label NS_SWIFT_NAME(label);
@end
NS_SWIFT_UI_ACTOR
@interface MainThing : NSObject @end
NS_HEADER_AUDIT_END(nullability, sendability)

typedef NS_ENUM(uint8_t, Small) { SmallA, SmallB };
typedef NS_OPTIONS(uint32_t, SmallFlags) { SmallFlagA = 1u << 0, SmallFlagB = 1u << 1 };
typedef NS_CLOSED_ENUM(NSInteger, Closed) { ClosedA, ClosedB };
typedef NS_ERROR_ENUM(OrderErrorDomain, OrderError) { OrderErrorNone = 0 };
typedef NSString *Mode NS_TYPED_ENUM;
NS_SWIFT_NAME(Mode.fast) extern Mode const ModeFast;

// C23 additions available in Objective-C with -std=gnu23
constexpr int kLimit = 10;
static constexpr double kPi = 3.14159;
bool c23_bool = true;
bool c23_false = false;
void *c23_null = nullptr;
int c23_digits = 1'000'000;
int c23_bin = 0b1010'1010;
unsigned char c23_u8 = u8'a';
const char *c23_u8s = u8"utf8";
[[nodiscard]] int c23_nodiscard(void);
[[maybe_unused]] static int c23_unused;
[[deprecated("old")]] int c23_deprecated(void);
[[noreturn]] void c23_noreturn(void);
typeof_unqual(c23_digits) c23_unq = 0;
unsigned _BitInt(12) c23_bitint = 5uwb;
auto c23_auto = 5;
enum Wide : unsigned long { WideA = 1ul << 40 };
static_assert(sizeof(int) >= 4, "int is at least 4 bytes");
#if __has_embed("data.bin")
static const char c23_embed[] = {
#embed "data.bin" limit(4)
};
#endif
_Alignas(16) static char aligned_buf[16];
_Noreturn void legacy_noreturn(void);
_Complex double cplx;
_Bool legacy_bool;
static void c11_exprs(void) {
    size_t al = _Alignof(max_align_t);
    const char *g = _Generic(1, int: "int", default: "other");
    long e = __builtin_expect(1, 1);
    asm volatile("nop");
    __asm__ __volatile__("" ::: "memory");
    (void)al; (void)g; (void)e;
}

// ── Compound literals, designated initialisers, VLAs, statement expressions ──
static void c_forms(int n) {
    int vla[n];
    struct Pair p = (struct Pair){ .a = 1, .b = 2 };
    int *arr = (int[]){ 1, 2, 3 };
    int v = ({ int t = 5; t * 2; });
    union IntOrFloat u = { .f = 1.0f };
    int idx[5] = { [0] = 1, [4] = 5 };
    char *s = "a" "b";
    long r = n ?: 7;
    void *lbl = &&target;
    goto *lbl;
target:
    (void)vla; (void)p; (void)arr; (void)v; (void)u; (void)idx; (void)s; (void)r;
    for (int i = 0, j = 10; i < j; i++, j--) {}
    switch (n) { case 1 ... 5: break; default: break; }
}
