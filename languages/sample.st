"Smalltalk (Pharo): an Order class, a class-side constructor, and a collection query."
Object subclass: #Order
    instanceVariableNames: 'number total status'
    classVariableNames: ''
    package: 'Sample'.

Order class >> number: aNumber total: aTotal
    ^ self new setNumber: aNumber total: aTotal

Order >> setNumber: aNumber total: aTotal
    number := aNumber.
    total := aTotal.
    status := #pending

Order >> markPaid
    status := #paid

Order >> isPaid
    ^ status = #paid

Order >> describe
    ^ '#', number printString, ' ', status, ' ', (total printShowingDecimalPlaces: 2)

"A workspace snippet"
| orders revenue |
orders := OrderedCollection new.
orders add: ((Order number: 1 total: 120.5) markPaid; yourself).
orders add: (Order number: 2 total: 42).
revenue := (orders select: [:o | o isPaid]) inject: 0 into: [:acc :o | acc + o total].
orders do: [:o | Transcript show: o describe; cr].
Transcript show: 'revenue: ', revenue printString; cr.
