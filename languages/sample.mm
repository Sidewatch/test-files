// Objective-C++: a C++ vector behind an Objective-C interface.
#import <Foundation/Foundation.h>
#include <vector>
#include <numeric>
#include <string>

struct LineItem {
    std::string sku;
    int quantity;
    double unitPrice;
    double total() const { return quantity * unitPrice; }
};

@interface Basket : NSObject
- (void)addSKU:(NSString *)sku quantity:(int)qty price:(double)price;
- (double)total;
@property (nonatomic, readonly) NSUInteger count;
@end

@implementation Basket {
    std::vector<LineItem> _items;
}

- (void)addSKU:(NSString *)sku quantity:(int)qty price:(double)price {
    _items.push_back({ sku.UTF8String, qty, price });
}

- (double)total {
    return std::accumulate(_items.begin(), _items.end(), 0.0,
                           [](double acc, const LineItem& i) { return acc + i.total(); });
}

- (NSUInteger)count { return _items.size(); }
@end

int main() {
    @autoreleasepool {
        Basket *b = [Basket new];
        [b addSKU:@"A-100" quantity:2 price:4.5];
        [b addSKU:@"C-300" quantity:1 price:99.0];
        NSLog(@"%lu items, total %.2f", (unsigned long)b.count, b.total);   // 2 items, 108.00
    }
}
