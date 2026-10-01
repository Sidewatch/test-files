"Smalltalk (Pharo 13) — syntax showcase"
"── Comments ──
 Smalltalk comments are double-quoted and can span several lines.
 TODO: persist stock movements.
 FIXME: reorder threshold should be per SKU."

"── Class definition (classic message syntax; superseded in Pharo 9+ by the << form below, deprecated style) ──"
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

"── Class definition, current Pharo form (Object << #Name) ──"
Object << #Shelf
    slots: { #label. #items };
    sharedVariables: { #Count };
    sharedPools: { };
    tag: 'Core';
    package: 'Warehouse-Core'.

Shelf subclass: #Pallet
    slots: { #weight };
    package: 'Warehouse-Core'.

Trait << #TStockable
    slots: { #stock };
    package: 'Warehouse-Core'.

Object << #Crate
    traits: { TStockable };
    slots: { #id };
    package: 'Warehouse-Core'.

"── More number forms ──"
nums := {
    1_000_000. -16rFF. 16r1F.8. 2r1e4. 1e-3. 1.5e-3. 100 factorial.
    1/2. (1/3) + (2/3). 3.14s2. 0.5s. 1.0e0. 36rSMALLTALK. -42. - 42 abs
}.
bindings := {#{Transcript}. #{Smalltalk}. #{StockItem}}.
literals := #(#(1 2) #($a $b) #(#a #b) #'with space' #+ #foo:bar: 1.5 -2 'str' (nested list) $ #[1 2 3] true false nil).
emptyArray := #().
emptyBrace := {}.
byteArray := #[0 255 16rFF].
cascadeOnLiteral := (OrderedCollection new) add: 1; add: 2; yourself.

"── Method syntax: pragmas, primitives, categories, nonlocal return ──"
StockItem >> pragmaDemo
    <category: 'demo'>
    <primitive: 60>
    <script>
    <inline: true>
    <compilerOptions: #(+ optionInlineIf)>
    ^ [:x | x > 0 ifTrue: [^ x]. 0] value: 1

StockItem >> temporaries: aNumber
    | a b |
    a := aNumber.
    b := [:n | | inner | inner := n + a. inner] value: 2.
    ^ a + b

StockItem >> unusual
    "Statements separated by periods; trailing period optional."
    self foo.
    self bar.
    ^ self; yourself

StockItem class >> new
    ^ super new init

"── Tonel file format ──"
Class {
    #name : 'Bin',
    #superclass : 'Object',
    #instVars : [
        'label',
        'capacity'
    ],
    #classVars : [
        'Default'
    ],
    #category : 'Warehouse-Core',
    #package : 'Warehouse-Core'
}

{ #category : 'accessing' }
Bin >> label [
    ^ label
]

{ #category : 'accessing' }
Bin class >> default [
    ^ Default ifNil: [ Default := self new ]
]

{ #category : 'testing' }
Bin >> isFull: anAmount [
    "Answer whether anAmount exceeds the capacity."
    ^ anAmount > capacity
]

"── GNU Smalltalk bracket syntax ──"
Object subclass: Drawer [
    | label contents |
    <comment: 'A drawer holding stock lines.'>
    Drawer class >> label: aLabel [
        <category: 'instance creation'>
        ^ self new setLabel: aLabel
    ]
    Total := 0.
    setLabel: aLabel [
        <category: 'private'>
        label := aLabel.
        contents := OrderedCollection new
    ]
    label [ ^ label ]
    add: anItem [ contents add: anItem. ^ anItem ]
    do: aBlock [ contents do: aBlock ]
    printOn: aStream [ aStream nextPutAll: 'Drawer ', label ]
]

Drawer extend [
    size [ ^ contents size ]
]

Drawer class extend [
    named: aName [ ^ self label: aName ]
]

Integer extend [
    double [ ^ self * 2 ]
]

Eval [
    | d |
    d := Drawer label: 'top'.
    d add: 3; add: 4.
    d size printNl.
    (d inject: 0 into: [:a :e | a + e]) displayNl
]

"── Chunk format (Squeak / classic file-in) ──"
!StockItem methodsFor: 'accessing'!
price
    ^ price!
price: aPrice
    price := aPrice! !

!StockItem class methodsFor: 'instance creation'!
named: aName
    ^ self new setName: aName! !

"── Special selectors, cascades and precedence ──"
(1 max: 2) printNl; displayNl.
1 + 2 * 3 - 4 / 5.
#(3 1 2) asSortedCollection asArray.
(1 to: 10) select: [:n | n even].
(1 to: 10 by: 2) asOrderedCollection.
1 -> (2 -> 3).
3 @ 4 + (1 @ 1).
(3 > 2) | (1 > 2) & true.
(1 = 1) and: [2 = 2] or: [false].
a := b := c := 0.
^ a.
thisContext sender.
Smalltalk version displayNl.
Character cr asString, Character tab asString, (Character value: 65) asString.
$a < $b.
'abc' < 'abd'.
#a == #a.
'it''s' size.
'multi
line' lines.
"Comment between statements" 1 + 1. "trailing comment"
