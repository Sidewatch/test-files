// Vala: a GObject class with a property, a signal and a GLib main loop.
public class Order : Object {
    public int number { get; construct; }
    public double total { get; set; default = 0.0; }
    public bool paid { get; private set; default = false; }

    public signal void paid_changed (bool now_paid);

    public Order (int number, double total) {
        Object (number: number, total: total);
    }

    public void mark_paid () {
        if (!paid) {
            paid = true;
            paid_changed (true);
        }
    }

    public string describe () {
        return "#%d %s %.2f".printf (number, paid ? "paid" : "pending", total);
    }
}

int main (string[] args) {
    var orders = new Gee.ArrayList<Order> ();
    orders.add (new Order (1, 120.5));
    orders.add (new Order (2, 42.0));
    orders[0].paid_changed.connect ((now) => stdout.printf ("order 1 paid: %s\n", now.to_string ()));
    orders[0].mark_paid ();

    double revenue = 0;
    foreach (var o in orders) {
        stdout.printf ("%s\n", o.describe ());
        if (o.paid) revenue += o.total;
    }
    stdout.printf ("revenue: %.2f\n", revenue);
    return 0;
}
