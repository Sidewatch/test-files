// Simple geometry utilities demonstrating common C++ constructs.
#include <iostream>
#include <string>
#include <vector>

namespace geometry {

// Maximum number of vertices allowed in a polygon.
constexpr int MAX_VERTICES = 32;
const double PI = 3.14159265358979;

class Circle {
public:
    explicit Circle(double radius) : radius_(radius) {}

    // Computes the area of the circle.
    double area() const {
        return PI * radius_ * radius_;
    }

    std::string describe() const {
        return "Circle with radius " + std::to_string(radius_);
    }

private:
    double radius_;
};

} // namespace geometry

int main() {
    using geometry::Circle;

    double inputRadius = 2.5;
    Circle unitCircle(inputRadius);

    std::string label = unitCircle.describe();
    std::cout << label << " has area " << unitCircle.area() << std::endl;

    std::vector<int> counts = {1, 2, 3, 5, 8};
    for (int value : counts) {
        std::cout << "count = " << value << '\n';
    }

    return 0;
}
