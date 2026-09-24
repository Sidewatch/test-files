// Objective-C: a small model with properties, a category and a block callback.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, OrderStatus) { OrderStatusPending, OrderStatusPaid, OrderStatusCancelled };

@interface Order : NSObject
@property (nonatomic, readonly) NSInteger number;
@property (nonatomic, readonly) NSDecimalNumber *total;
@property (nonatomic) OrderStatus status;
- (instancetype)initWithNumber:(NSInteger)number total:(NSDecimalNumber *)total NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@implementation Order
- (instancetype)initWithNumber:(NSInteger)number total:(NSDecimalNumber *)total {
    if ((self = [super init])) { _number = number; _total = total; _status = OrderStatusPending; }
    return self;
}
- (NSString *)description { return [NSString stringWithFormat:@"#%ld %@", (long)self.number, self.total]; }
@end

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

NS_ASSUME_NONNULL_END

int main(void) {
    @autoreleasepool {
        Order *a = [[Order alloc] initWithNumber:1 total:[NSDecimalNumber decimalNumberWithString:@"120.50"]];
        a.status = OrderStatusPaid;
        NSArray<Order *> *orders = @[a, [[Order alloc] initWithNumber:2 total:[NSDecimalNumber decimalNumberWithString:@"42"]]];
        [orders enumerateObjectsUsingBlock:^(Order *o, NSUInteger idx, BOOL *stop) { NSLog(@"%@", o); }];
        NSLog(@"revenue: %@", orders.revenue);
    }
    return 0;
}
