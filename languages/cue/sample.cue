// ── Comments ──
// Line comment. TODO: split into packages. FIXME: tighten the regexes.
// CUE has only line comments; doc comments precede the field they describe.

// ── Package, imports ──
package deploy

import (
	"list"
	"math"
	"regexp"
	"strings"
	str "strconv"
)

// ── Literals ──
nullValue: null
yes:       true
no:        false
integer:   42
big:       1_000_000
hex:       0xFF_EC
octal:     0o755
binary:    0b1010
sized:     1K
sizedMi:   2.5Mi
decimal:   3.14159
exp:       6.02e23
negexp:    1.5E-10
duration:  "1h30m"
bytes:     '\x00\xffraw bytes'
string1:   "Warehouse \"north\"\t\n"
unicode:   "café \U0001F4E6"
interp:    "total: \(integer + 1) items of \(string1)"
raw:       #"raw "string" with \n kept and \#(integer) interpolation"#
rawMulti:  ##"""
	multi-line raw
	string with "quotes"
	"""##
multi: """
	Multi-line string
	second line \(integer)
	"""
bytesMulti: '''
	multi-line bytes
	'''

// ── Definitions and constraints ──
#Category: "tools" | "fasteners" | "safety" | "bulk"

#Port: int & >0 & <65536

#Sku: string & =~"^[A-Z]-[0-9]{3}$"

#Service: {
	name:     string & =~"^[a-z][a-z0-9-]*$"
	replicas: int & >=1 & <=20 | *2
	image:    string & !=""
	ports: [...#Port]
	env: [string]: string
	labels?: [string]: string
	owner!:  string
	resources: {
		cpu:    string | *"250m"
		memory: string | *"256Mi"
	}
	category: #Category
	healthy:  bool | *true
	...
}

#Item: {
	sku:      #Sku
	qty:      int & >=0
	price:    number & >=0.0
	total:    qty * price
	discount: *0 | number
	notes?:   string
}

// ── Disjunctions, defaults, embedding ──
mode: *"fast" | "slow" | "balanced"
size: int | string | null
base: {a: int, b: string}
extended: base & {c: bool}
embedded: {
	base
	extra: "field"
}
closed: close({only: int})

// ── Comprehensions and lists ──
squares: [for i in list.Range(0, 5, 1) {i * i}]
evens: [for i in squares if mod(i, 2) == 0 {i}]
lookup: {for k, v in {a: 1, b: 2} {"\(k)": v * 10}}
withLet: {
	let double = integer * 2
	result: double + 1
}
slice: squares[1:3]
index: squares[0]
count: len(squares)
joined: strings.Join(["a", "b", "c"], ", ")
upper:  strings.ToUpper("stock")
matches: regexp.Match("^A", "A-100")
parsed:  str.Atoi("42")
floor:   math.Floor(3.7)
optionalLabel: [string]: int

// ── Services and aliases ──
services: [Name=string]: #Service & {name: Name}

services: {
	api: {
		image:    "registry.example.com/api:1.4.0"
		replicas: 4
		ports: [8080, 9090]
		env: LOG_LEVEL: "info"
		category: "tools"
		owner:    "platform"
	}
	worker: {
		image: "registry.example.com/worker:1.4.0"
		ports: []
		resources: memory: "1Gi"
		category: "bulk"
		owner:    "platform"
	}
}

items: [...#Item]
items: [
	{sku: "A-100", qty: 12, price: 4.5},
	{sku: "B-200", qty: 0, price: 19.99, notes: "back-ordered"},
]

let X = services.api
aliased: X.image

// ── Attributes ──
@go(Deploy)
version: "1.0.0" @tag(release)
tagged: string | *"dev" @tag(env,short=prod|staging|dev)

// ── Operators ──
ops: {
	add:  1 + 2
	sub:  5 - 3
	mul:  4 * 2
	divide: 9 / 2
	idiv:   div(9, 2)
	modulo: mod(9, 2)
	remain: rem(9, 2)
	quot:   quo(9, 2)
	neg:  -integer
	not:  !true
	and:  true && false
	or:   true || false
	eq:   1 == 1
	ne:   1 != 2
	lt:   1 < 2
	le:   1 <= 2
	gt:   2 > 1
	ge:   2 >= 1
	rematch:  "abc" =~ "a.c"
	renomatch: "abc" !~ "x"
	cat:  "a" + "b"
	rep:  "ab" * 3
	unify: int & 5
	disj:  1 | 2
}

// ── Further constructs ──
// Hidden fields and definitions
_hidden:    "not exported"
_#hiddenDef: {x: int}
#Def:       {y: string}
bottom: _|_
top:    _
anyOf:  or([int, string])
allOf:  and([>=0, <=10])
isStr:  string | bytes
exact:  "a" & "a"
neq:    !=3
lessEq: <=100 & >=1
regexConstraint: =~"^[a-z]+$" & !~"^bad"

// Quoted and dynamic labels
"quoted label":    1
"with space":      2
"interp-\(integer)": 3
(string1 + "-dyn"): 4

// Conditional and field comprehensions
if integer > 40 {
	large: true
}
for k, v in {a: 1, b: 2} if v > 1 {
	"picked-\(k)": v
}
listOfStructs: [for i, v in ["x", "y"] {idx: i, val: v}]
nestedFor: [for a in [1, 2] for b in [3, 4] {a * b}]
guarded: [for x in [1, 2, 3] if x != 2 let y = x * 10 {y}]

// Packages, builtins, tools
import "tool/exec"
import "tool/cli"
import "tool/file"
import "tool/http"
import "text/template"
import "encoding/yaml"
import "encoding/base64"
import "crypto/sha256"
import "net"
import "path"
import "struct"
import "uuid"

command: build: {
	compile: exec.Run & {
		cmd:    ["go", "build", "./..."]
		stdout: string
	}
	report: cli.Print & {
		text: compile.stdout
	}
}

validated: {
	ip:      net.IPv4 & "192.0.2.1"
	cidr:    net.IPCIDR & "2001:db8::/32"
	max:     struct.MaxFields(3)
	fields:  struct.MinFields(1)
	b64:     base64.Encode(null, "stock")
	yamlOut: yaml.Marshal({a: 1})
	hash:    sha256.Sum256("stock")
	pathExt: path.Ext("file.txt", "unix")
	tmpl:    template.Execute("{{.sku}}", {sku: "A-100"})
	id:      uuid.Valid("00000000-0000-0000-0000-000000000000")
}

// Embeds and attributes
@extern(embed)
@embed(file="data/stock.json", type=json)
stockData: _
@embed(glob="data/*.yaml", type=yaml)
allStock: _
@go(,type=int)
typed: int @protobuf(1,name=typed)
withFlags: string @tag(a) @tag(b,short=x|y)

// Numbers, bytes and unusual literals
numbers: {
	a: 0
	d: 0o7_7
	e: 0xdead_BEEF
	f: 1e3
	g: .5
	i: 1M
	j: 1Gi
	k: 0.5Ki
	m: 'bytes\n\x00'
	n: "\a\b\f\n\r\t\v\\\/\"A\U0001F4E6"
	o: '''
		bytes
		block
		'''
}
