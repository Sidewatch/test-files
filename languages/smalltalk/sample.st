"── Comments ──
 Smalltalk comments are double-quoted and can span several lines.
 TODO: persist stock movements.
 FIXME: reorder threshold should be per SKU."

"── Class definition (Pharo message syntax) ──"
Object subclass: #StockItem
    instanceVariableNames: 'sku name quantity price tags'
    classVariableNames: 'ReorderPoint Registry'
    poolDictionaries: ''
    package: 'Warehouse-Core'.

StockItem subclass: #PerishableItem
    instanceVariableNames: 'expiry'
    classVariableNames: ''
    package: 'Warehouse-Core'.

Error subclass: #OutOfStock
    instanceVariableNames: 'sku'
    classVariableNames: ''
    package: 'Warehouse-Core'.

"── Class-side methods ──"
StockItem class >> sku: aSku name: aName quantity: aQuantity
    "Answer a new item. Class-side constructor."
    <category: 'instance creation'>
    ^ self new setSku: aSku name: aName quantity: aQuantity

StockItem class >> reorderPoint
    ^ ReorderPoint ifNil: [ReorderPoint := 25]

StockItem class >> initialize
    "Run once when the class is loaded."
    Registry := Dictionary new.
    ReorderPoint := 25

"── Instance methods ──"
StockItem >> setSku: aSku name: aName quantity: aQuantity
    sku := aSku.
    name := aName.
    quantity := aQuantity.
    price := 0.
    tags := Set new

StockItem >> sku
    ^ sku

StockItem >> quantity
    ^ quantity

StockItem >> isLow
    ^ quantity <= self class reorderPoint

StockItem >> remove: anAmount
    "Take anAmount from stock or signal OutOfStock."
    anAmount > quantity
        ifTrue: [^ OutOfStock new signal: 'only ', quantity printString, ' of ', sku].
    quantity := quantity - anAmount.
    ^ quantity

StockItem >> = other
    ^ (other isKindOf: StockItem) and: [sku = other sku]

StockItem >> hash
    ^ sku hash

StockItem >> printOn: aStream
    aStream
        nextPutAll: 'StockItem(';
        nextPutAll: sku;
        nextPutAll: ' x';
        print: quantity;
        nextPut: $)

StockItem >> + other
    "Binary selector: merge two stock lines."
    ^ self class sku: sku name: name quantity: quantity + other quantity

"── Workspace: literals ──"
| ints floats scaled radix chars strings symbols arrays bytes bools specials |
ints := #(0 42 -7 16r1F 2r1010 8r777 36rZZ 1e3 1000000000000000000000).
floats := #(3.14 -0.5 1.5e10 2.5e-3 1.0d0 1.0q0).
scaled := #(3.14s2 100s).
chars := {$a. $Z. $ . $'. $". $#}.
strings := {'plain'. 'it''s quoted'. 'unicode: éèü ✓'. ''}.
symbols := #(#foo #bar:baz: #+ #with:with: foo bar:baz: #'quoted symbol' $a 'str' #(1 2) true false nil).
arrays := #(1 $a 'two' #three (4 5) #(6 7) foo nil true false).
bytes := #[1 2 255 16r0F].
bools := {true. false. nil}.
specials := {self. super. thisContext}.

"── Brace arrays, cascades, assignment ──"
items := OrderedCollection new.
items
    add: (StockItem sku: 'ABC-1' name: 'Hammer' quantity: 12);
    add: (StockItem sku: 'ABC-2' name: 'Nails' quantity: 400);
    add: (StockItem sku: 'ABC-3' name: 'Saw' quantity: 3);
    yourself.
total := 0.
x := y := 5.
a := {1. 2. 3. 1 + 2}.

"── Messages: unary, binary, keyword ──"
items size.
items first sku asUppercase.
3 + 4 * 2.
(3 + 4) * 2.
10 \\ 3.
10 // 3.
7 rem: 2.
2 ** 8.
5 @ 3.
1 -> 2.
3 > 2 & (4 < 5) | false.
3 ~= 4.
3 == 3.
'abc' , 'def'.
items at: 1 put: nil.
Transcript show: 'hello'; cr; tab; show: 'again'; cr.

"── Blocks ──"
square := [:n | n * n].
add := [:a :b | a + b].
noArgs := [Transcript show: 'run'; cr].
withTemps := [:n | | t u | t := n * 2. u := t + 1. u].
(square value: 5) printString displayNl.
(add value: 1 value: 2) displayNl.
noArgs value.
[:a :b :c :d | a + b + c + d] valueWithArguments: #(1 2 3 4).

"── Control flow is message sending ──"
(items first quantity > 10)
    ifTrue: [Transcript show: 'plenty'; cr]
    ifFalse: [Transcript show: 'low'; cr].
items isEmpty ifTrue: ['none'] ifFalse: ['some'].
nil ifNil: ['was nil'] ifNotNil: [:v | v].
(3 max: 4) between: 1 and: 10.
1 to: 5 do: [:i | Transcript show: i printString; space].
10 to: 1 by: -3 do: [:i | Transcript show: i printString; space].
5 timesRepeat: [total := total + 1].
[total < 100] whileTrue: [total := total * 2].
[total > 10] whileFalse: [total := total + 1].
[:k | k > 0] whileTrue.
items do: [:each | Transcript show: each sku; cr].
items do: [:each | Transcript show: each sku] separatedBy: [Transcript show: ', '].
items doWithIndex: [:each :i | Transcript show: i printString, ': ', each sku; cr].
items keysAndValuesDo: [:i :each | each isLow ifTrue: [Transcript show: 'LOW ', each sku; cr]].
items reverseDo: [:each | each].
(items collect: [:each | each quantity]) inject: 0 into: [:acc :q | acc + q].
(items select: [:each | each isLow]) size.
(items reject: [:each | each isLow]) size.
(items detect: [:each | each sku = 'ABC-2'] ifNone: [nil]) printString.
(items anySatisfy: [:each | each isLow]) printString.
(items asSortedCollection: [:a :b | a quantity >= b quantity]) first.

"── Exceptions ──"
[items first remove: 1000]
    on: OutOfStock
    do: [:ex | Transcript show: 'caught: ', ex messageText; cr. ex return: 0].

[items first remove: 1]
    on: ZeroDivide, Error
    do: [:ex | ex retry].

[1 / 0] on: ZeroDivide do: [:ex | ex resume: 0].
[Error signal: 'boom'] ensure: [Transcript show: 'cleanup'; cr].
[Error new signal] ifCurtailed: [Transcript show: 'curtailed'; cr].
[^ 3] on: Error do: [:e | e pass].
[self error: 'custom'] on: Error do: [:e | e signal].
Error new signal: 'plain'.
self assert: (items size = 3).
self halt.

"── Reflection and pragmas ──"
StockItem selectors.
StockItem respondsTo: #isLow.
StockItem class category.
items first perform: #sku.
items first perform: #remove: with: 1.
Smalltalk at: #Global put: 42.
(Smalltalk at: #Global) printString.
thisContext printString.

"── Dictionaries, sets, streams ──"
dict := Dictionary new.
dict at: #apple put: 3; at: #pear put: 5.
dict keysAndValuesDo: [:k :v | Transcript show: k; show: ' -> '; show: v printString; cr].
(dict associations collect: [:assoc | assoc key]) asArray.
stream := WriteStream on: String new.
stream nextPutAll: 'Stock: '; print: 42; nl; tab; nextPut: $!.
stream contents displayNl.
(ReadStream on: #(1 2 3)) next.
('hello world' substrings: ' ') first.
('hello' at: 1) isVowel.
'hello' reversed.
'hello' asSymbol.
#sym asString.
Date today.
Time now.
Random new next.
