#!/usr/bin/env dart
// ── Comments ──
// Line comment. TODO: persist bins. FIXME: handle negative stock.
/* Block comment /* with nested block */ still comment */
/// Doc comment for [Warehouse] with a [link] and `code`.
///
/// ```dart
/// final w = Warehouse('north');
/// ```
/** Old-style doc block comment. */

// ── Libraries and imports ──
library acme.warehouse;

import 'dart:async';
import 'dart:convert' as convert show jsonEncode, jsonDecode;
import 'dart:io' hide File;
import 'dart:isolate';
import 'dart:math' show pi;
import 'package:meta/meta.dart';
import 'dart:math' show Random, max, min;
import 'package:collection/collection.dart' deferred as collection;
export 'src/bins.dart';
part 'bins.g.dart';

// ── Constants ──
const int kMaxBins = 64;
const double kPi = 3.14159;
final DateTime startedAt = DateTime.now();
late final String region;
var dynamicValue = 42;
dynamic anything = 'text';
Object? maybe;
Never fail() => throw StateError('fail');

// ── Literals ──
void literals() {
  int decimal = 1000000;
  int hex = 0xFFEC;
  int hex2 = 0XAB;
  double d = 6.02e23;
  double d2 = 1.5E-10;
  double d3 = .5;
  double nan = double.nan;
  double inf = double.infinity;
  num n = 3;
  bool yes = true;
  bool no = false;
  Null nothing = null;

  String single = 'Warehouse \'north\'\t\n';
  String double_ = "Warehouse \"north\"";
  String unicode = '\u00e9 \u{1F4E6} \x41';
  String raw = r'raw \n $notInterpolated';
  String rawDouble = r"raw \t";
  String triple = '''
    triple single
    quoted multi-line
  ''';
  String tripleDouble = """
    triple double "quoted" lines
  """;
  String interp = 'Total: $decimal and ${decimal * 2} and ${d.toStringAsFixed(2)}';
  String escDollar = 'cost: \$5';
  String adjacent = 'a' 'b' "c";
  Symbol sym = #warehouse;
  Symbol opSym = #+;
  List<int> list = [1, 2, 3];
  Set<String> set = {'a', 'b'};
  Map<String, int> map = {'a': 1, 'b': 2};
  var record = (1, 'two', flag: true);
  var emptyMap = <String, int>{};
}

// ── Enums ──
enum Category {
  tools('Tools', 1),
  fasteners('Fasteners', 2),
  safety('Safety', 3);

  const Category(this.label, this.code);
  final String label;
  final int code;
  bool get isSafe => this == safety;
}

// ── Mixins, extensions, typedefs ──
mixin Auditable on Object {
  void audit() => print('audit $runtimeType');
}

mixin class Loggable {
  void log(String message) => stderr.writeln(message);
}

extension StringShout on String {
  String shout() => '${toUpperCase()}!';
}

extension type Sku(String value) implements Object {
  bool get isValid => value.startsWith('A-');
}

typedef Predicate<T> = bool Function(T value);
typedef Json = Map<String, dynamic>;

// ── Sealed classes and patterns ──
sealed class Shape {}

final class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}

final class Square extends Shape {
  final double side;
  Square(this.side);
}

double area(Shape s) => switch (s) {
      Circle(radius: var r) => kPi * r * r,
      Square(side: final side) when side > 0 => side * side,
      _ => 0,
    };

// ── Classes ──
abstract interface class Store<T extends Comparable<T>> {
  Future<T?> find(String id);
  Stream<T> all();
}

@immutable
class Item implements Comparable<Item> {
  final String sku;
  final int quantity;
  static int created = 0;
  int _hidden = 0;

  const Item(this.sku, [this.quantity = 0]);
  const Item.empty() : this('', 0);
  Item.named({required this.sku, this.quantity = 1}) {
    created++;
  }
  factory Item.fromJson(Json json) => Item(json['sku'] as String, json['qty'] as int? ?? 0);

  int get total => quantity * 2;
  set hidden(int v) => _hidden = v;

  @override
  int compareTo(Item other) => sku.compareTo(other.sku);

  @override
  bool operator ==(Object other) => other is Item && other.sku == sku;

  @override
  int get hashCode => Object.hash(sku, quantity);

  Item operator +(Item o) => Item(sku, quantity + o.quantity);
  int operator [](int i) => i;

  @override
  String toString() => 'Item($sku, $quantity)';
}

class Bin extends Item with Auditable, Loggable {
  Bin(super.sku, super.quantity);
  external void native();
  covariant dynamic field;
}

// ── Functions and closures ──
int add(int a, int b) => a + b;
void greet(String name, {String greeting = 'Hello', required int times}) {
  for (var i = 0; i < times; i++) print('$greeting, $name');
}
void optional(int a, [int? b, int c = 3]) {}
T pick<T extends num>(T a, T b) => a > b ? a : b;
final square = (int x) => x * x;
final compose = (int Function(int) f, int Function(int) g) => (int x) => f(g(x));

// ── Async ──
Future<String> fetch(Uri uri) async {
  await Future.delayed(const Duration(milliseconds: 10));
  return 'ok';
}

Stream<int> counter(int max) async* {
  for (var i = 0; i < max; i++) {
    yield i;
  }
  yield* Stream.fromIterable([100, 200]);
}

Iterable<int> naturals(int n) sync* {
  for (var i = 0; i < n; i++) yield i;
}

// ── Control flow and operators ──
Future<void> main(List<String> args) async {
  var a = 10, b = 3;
  a += 1; a -= 1; a *= 2; a ~/= 3; a %= 5; a <<= 1; a >>= 1; a &= 7; a |= 1; a ^= 3;
  int? maybeNull;
  maybeNull ??= 5;
  var len = args.length > 0 ? args[0].length : maybeNull ?? 0;
  var cascade = StringBuffer()..write('a')..write('b');
  var nullAware = maybeNull?.abs() ?? -1;
  var bang = maybeNull!;
  var spread = [...[1, 2], ...?null, if (a > 3) 99 else 0, for (var i in [1]) i];
  var intDiv = a ~/ b;
  var mod = a % b;
  var bits = ~a & b | a ^ b << 1 >> 1 >>> 1;
  var cmp = a < b && a >= b || a != b && a == b || !(a <= b);
  var typeTest = a is int && a is! String;
  var cast = a as num;

  if (a > b) {
    print('greater');
  } else if (a == b) {
    print('equal');
  } else {
    print('less');
  }

  switch (a) {
    case 1:
    case 2:
      print('small');
      break;
    case int big when big > 100:
      print('large');
    default:
      print('other');
  }

  outer:
  for (var i = 0; i < 3; i++) {
    for (final j in [1, 2, 3]) {
      if (j == 2) continue outer;
      if (i == 2) break outer;
    }
  }

  var k = 0;
  while (k < 3) k++;
  do { k--; } while (k > 0);

  try {
    throw FormatException('bad bin');
  } on FormatException catch (e, stack) {
    print('$e $stack');
  } on Exception {
    rethrow;
  } catch (e) {
    print(e);
  } finally {
    print('cleanup');
  }

  assert(a > 0, 'must be positive');

  // Pattern matching and destructuring
  var (x, y) = (1, 2);
  var [first, ...rest] = [1, 2, 3];
  var {'sku': sku} = {'sku': 'A-1'};
  if (case [int p, int q] = [1, 2]) print(p + q);
  switch ((x, y)) {
    case (1, _) || (_, 1):
      break;
  }

  final item = const Item('A-1', 5);
  final bin = new Bin('B-1', 2);
  print(item.runtimeType);
  print(identical(item, item));
  await Future.wait([fetch(Uri.parse('https://example.com/stock')), Future.value('x')]);
  await for (final n in counter(3)) print(n);
  Isolate.run(() => 1);
}

// ── Further constructs ──
// ignore_for_file: unused_element, unused_local_variable
// ignore: deprecated_member_use
// @dart=2.19
// ignore_for_file: avoid_print

abstract mixin class Walker {
  void walk() {}
}

interface class Marker {}

class Gen<T extends Object?, U extends List<T>> {
  T? value;
  Gen.empty();
  Gen(this.value);
  late final int lazyField = expensive();
  static const List<int> constList = [1, 2, 3];
  static final Map<String, int> cache = {};
  int expensive() => 42;
  void Function(int)? callback;
  T Function<S>(S) generic = <S>(S s) => throw UnimplementedError();
}

typedef IntOp = int Function(int a, int b);
typedef void VoidCb();
typedef Compare<T> = int Function(T a, T b);

extension NumberExt<T extends num> on List<T> {
  T get total => reduce((a, b) => (a + b) as T);
  static const label = 'numbers';
  operator -() => this;
}

extension type const Meters(double value) {
  Meters.zero() : this(0);
  Meters operator +(Meters other) => Meters(value + other.value);
}

enum Planet<T> with Walker implements Comparable<Planet> {
  mercury<int>(1),
  venus<int>(2);
  const Planet(this.n);
  final T n;
  @override
  int compareTo(Planet other) => 0;
}

void records() {
  (int, String) pair = (1, 'one');
  ({int x, int y}) named = (x: 1, y: 2);
  (int, {String label}) mixed = (1, label: 'a');
  var (a, b) = pair;
  var (x: px, y: py) = named;
  print(pair.$1 + named.x + mixed.$1);
  switch (pair) {
    case (int n, String s) when n > 0:
      print(s);
    case (_, 'one'):
      break;
  }
  final result = switch (a) {
    1 || 2 => 'low',
    > 2 && < 10 => 'mid',
    int() => 'int',
    [1, 2, ...] => 'list',
    {'k': var v} => 'map $v',
    Meters(value: > 0) => 'positive',
    var other? => 'nonnull',
    _ => 'other',
  };
  if (pair case (int first, String second) when first > 0) print(second);
  final list = [1, 2, 3];
  if (list case [var head, ...var tail]) print('$head $tail');
  var obj = Object();
  if (obj is! String && obj case Object o) print(o);
}

Future<void> asyncExtras() async {
  final controller = StreamController<int>.broadcast(onListen: () {}, sync: true);
  final sub = controller.stream.where((e) => e.isEven).listen((e) => print(e), onError: (Object e, StackTrace s) {}, onDone: () {});
  await sub.cancel();
  await Future.wait([Future.value(1), Future.error('x')], eagerError: true);
  unawaited(Future.delayed(Duration.zero));
  final c = Completer<int>()..complete(1);
  await c.future.timeout(const Duration(seconds: 1), onTimeout: () => 0);
  runZonedGuarded(() {}, (error, stack) {});
  Timer.periodic(const Duration(seconds: 1), (t) => t.cancel());
  Future<int>.microtask(() => 1).then((v) => v, onError: (e) => 0).catchError((e) => 0).whenComplete(() {});
}

void misc() {
  var s = StringBuffer();
  s..write('a')..writeln('b')..writeAll(['c', 'd'], ',');
  int? n;
  print(n?.isEven ?? false);
  print(n ?? 0);
  n ??= 3;
  print(n!);
  var m = <String, List<int>>{'a': [1]};
  m['b'] ??= [];
  m['b']?.add(1);
  print(m['a']?[0]);
  var f = (int x) => x * 2;
  var g = f.call;
  var tearOff = print;
  var constructorTearOff = Item.new;
  var namedTearOff = Item.named;
  print(1 is num ? 'num' : 'other');
  print(0x7fffffffffffffff + 0xFF);
  print(1e-3);
  print(.5e2);
  print('${1 + 1}${"nested ${'deep'}"}');
  print('\$ \\ \' \" \b \f \v \r \0');
  const bigList = [for (var i = 0; i < 3; i++) i * 2];
  const bigSet = {...bigList, 100};
  const bigMap = {'a': 1, ...{'b': 2}};
  assert(bigList.isNotEmpty);
  label:
  while (true) {
    break label;
  }
  late int lateVar;
  lateVar = 5;
  final String? maybeStr = null;
  print(maybeStr?.length);
  print(identityHashCode(maybeStr));
  var v = int.parse('42') + int.tryParse('x')!.abs();
  v++; v--; ++v; --v;
  print(v >>> 1);
  print(~v);
  print(-v);
  print(!true);
  print(v.toString().padLeft(5, '0'));
  print(DateTime.utc(2026, 3, 1).toIso8601String());
  print(RegExp(r'^A-\d+$').hasMatch('A-100'));
  print(Uri.parse('https://example.com/a?b=c').queryParameters);
  print(#symbol.toString());
  print(const Symbol('x'));
  print(Random().nextInt(10));
  print(pi);
}

@pragma('vm:prefer-inline')
@Deprecated('use newFunction')
void oldFunction() {}

@override
@visibleForTesting
@protected
@required
void annotated() {}

@JsonSerializable(explicitToJson: true)
class Annotated {
  @JsonKey(name: 'sku', defaultValue: '')
  final String sku;
  Annotated(this.sku);
}

int get getter => 1;
set setter(int v) {}
