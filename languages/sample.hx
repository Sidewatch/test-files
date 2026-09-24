// Haxe: a generic cache with an expiry, targeting any platform.
package sample;

import haxe.Timer;

typedef Entry<T> = { value:T, expires:Float };

class Cache<K, V> {
    final ttlMs:Float;
    final store = new Map<K, Entry<V>>();
    public var hits(default, null):Int = 0;

    public function new(ttlMs:Float = 5000) this.ttlMs = ttlMs;

    public function get(key:K, compute:() -> V):V {
        final now = Timer.stamp() * 1000;
        switch store.get(key) {
            case e if (e != null && e.expires > now):
                hits++;
                return e.value;
            case _:
                final value = compute();
                store.set(key, { value: value, expires: now + ttlMs });
                return value;
        }
    }
}

class Main {
    static function main() {
        final cache = new Cache<String, Int>(1000);
        for (i in 0...3) trace('answer: ${cache.get("answer", () -> 42)}');
        trace('hits: ${cache.hits}');   // 2
    }
}
