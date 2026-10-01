(* Wolfram Language 14.3 — syntax showcase
   ── Comments ───────────────────────────────────────────────
   Wolfram Language: warehouse orders as associations, a query, and plots.
   TODO: cache the totals. FIXME: currency formatting.
   (* comments nest in Wolfram Language *)
*)

(* ::Package:: *)
(* ::Section:: *)

(* ── Contexts and packages ──────────────────────────────── *)
BeginPackage["Warehouse`", {"Developer`", "GeneralUtilities`"}];
Needs["Warehouse`Helpers`"];

describe::usage = "describe[order] gives a one-line description of an order.";
reorderPoint::usage = "reorderPoint is the minimum stock level.";
Warehouse::badInput = "Expected an association but received `1`.";

Begin["`Private`"];

(* ── Numbers ────────────────────────────────────────────── *)
integer = 42;
negative = -17;
big = 1`50;
real = 3.14159;
precise = 3.14159`20;
accuracy = 3.14159``20;
scientific = 1.5*^-3;
base2 = 2^^101010;
base16 = 16^^FF;
base36 = 36^^ZZ;
rational = 3/4;
complex = 2 + 3 I;
constants = {Pi, E, EulerGamma, GoldenRatio, Infinity, ComplexInfinity, Indeterminate, I, Degree};
reorderPoint = 25;
ratio = 0.75;

(* ── Strings ────────────────────────────────────────────── *)
plain = "double \"quoted\" with \t tab, \n newline, \\ backslash, \[Alpha], \:00e9, \.41";
multi = "line one
line two";
templ = StringTemplate["Item `sku` has `qty` units"];
interp = "``" <> ToString[integer];
sym = "x" <> "y" <> StringJoin["a", "b"];
named = "\[Degree]C \[Rule] \[Element] \[Infinity] \[Sum] \[Pi]";
regex = RegularExpression["^[A-Z]{3}-\\d+$"];
pattern = StringExpression["WGT-", DigitCharacter ..];
verbatimPat = StringMatchQ["WGT-100", "WGT-" ~~ DigitCharacter ..];

(* ── Lists, associations, rules ─────────────────────────── *)
orders = {
  <|"number" -> 1, "total" -> 120.5, "status" -> "paid"|>,
  <|"number" -> 2, "total" -> 42, "status" -> "pending"|>,
  <|"number" -> 3, "total" -> 0, "status" -> "cancelled"|>,
  <|"number" -> 4, "total" -> 88.25, "status" -> "paid"|>
};
matrix = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}};
nested = {1, {2, {3, {4}}}};
rules = {a -> 1, b :> RandomReal[], c -> {2, 3}};
delayed = x :> x^2;
span = matrix[[1 ;; 2, 2 ;; -1]];
part = matrix[[2, 3]];
parts = orders[[All, "total"]];
key = orders[[1]]["status"];
dataset = Dataset[orders];
query = dataset[Select[#status == "paid" &], {"number", "total"}];

(* ── Function definitions and patterns ──────────────────── *)
describe[o_Association] := StringForm["#`` `` ``", o["number"], o["status"], NumberForm[o["total"], {6, 2}]];
describe[x_] := (Message[Warehouse::badInput, x]; $Failed);

fib[0] = 0;
fib[1] = 1;
fib[n_Integer?Positive] := fib[n] = fib[n - 1] + fib[n - 2];

money[n_?NumericQ, cur_String : "GBP"] := Row[{NumberForm[n, {Infinity, 2}], " ", cur}];
add[a_, b_ : 0, OptionsPattern[]] := a + b + OptionValue["Extra"];
Options[add] = {"Extra" -> 0};
variadic[args__] := Length[{args}];
variadic0[args___] := Length[{args}];
conditional[x_ /; x > 0] := Sqrt[x];
alternatives[x : (1 | 2 | 3)] := x;
named[x : _Integer] := x;
typed[x_Integer, y_Real, z_List, w_String, v_Symbol] := {x, y, z, w, v};
repeated[x : {__Integer}] := Total[x];
except[x : Except[_String]] := x;
longest[x_] /; ListQ[x] := Max[Length /@ x];
patternTest[x_?(# > 0 &)] := x;
optional[x_, y_ : 1] := x + y;

SetAttributes[add, {Listable, NumericFunction}];
Attributes[add] = {Flat, OneIdentity};
SyntaxInformation[add] = {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};

(* ── Pure functions and operators ───────────────────────── *)
revenue = Total[#["total"] & /@ Select[orders, #["status"] == "paid" &]];
byStatus = GroupBy[orders, #["status"] &, Length];
squares = #^2 & /@ Range[10];
pairs = #1 + #2 & @@@ {{1, 2}, {3, 4}};
folded = Fold[Plus, 0, Range[5]];
composed = (f @* g @* h)[x];
rightComposed = (f /* g /* h)[x];
applied = f @@ {1, 2, 3};
mapped = f /@ {1, 2, 3};
mapAll = f //@ {1, {2}};
prefix = f @ x;
postfix = x // f;
infix = a ~ Join ~ b;
sequence = Sequence @@ {1, 2};
nestedSlot = #1 + #2 &[1, 2];
namedSlot = <|"a" -> 1|>[[Key["a"]]];
slotAssoc = #a + #b & [<|"a" -> 1, "b" -> 2|>];
function = Function[{x, y}, x + y];
function2 = Function[x, x^2, Listable];
select = Select[Range[20], PrimeQ];
cases = Cases[{1, "a", 2.5, x}, _Integer | _Real];
replaced = {1, 2, 3} /. x_Integer :> x^2;
replaceAll = expr //. {a -> b, b -> c};
replacePart = ReplacePart[{1, 2, 3}, 2 -> 99];
upset = f[x_] ^= x^2;
upsetDelayed = f[x_] ^:= x^3;
tagSet = g /: g[x_] + g[y_] := g[x + y];

(* ── Arithmetic, logic, comparison, string operators ───── *)
arith = 1 + 2 - 3 * 4 / 5 ^ 2 + (a b) + a . b + a \[Times] b + a \[Divide] b;
compare = a == b || a != b && a < b || a > b || a <= b || a >= b || a === b || a =!= b;
logic = !p && q || Xor[p, q] || Implies[p, q] || p \[And] q || p \[Or] q || \[Not] p;
incr = (i++; i--; ++i; --i; i += 1; i -= 1; i *= 2; i /= 2);
assign = (x = 1; y := 2; z =. ; w = v = 3);
string = "a" <> "b" <> "c";
join = {1, 2} ~Join~ {3};
span2 = Range[10][[2 ;; 8 ;; 2]];
cond = If[x > 0, "positive", If[x < 0, "negative", "zero"]];
which = Which[x < 0, -1, x == 0, 0, True, 1];
switch = Switch[x, 1, "one", 2, "two", _, "many"];
repeat = x /. {a_ :> a + 1} //. {b_ /; b < 10 :> b + 1};
alt = a | b | c;
repeated2 = a ..;
repeated3 = a ...;
blank = {_, __, ___, _h, x_h, _. };
optional2 = x_. + y_.;
verbatim = Verbatim[_];
longForm = x \[Equal] y;
ruleArrow = a \[Rule] b;
ruleDelayed = a \[RuleDelayed] b;
unicodeOps = a \[Element] Reals && b \[NotElement] Integers && c \[Subset] d;

(* ── More operators and syntax forms ──────────────────────── *)
information = ?Plot;
informationLong = ??Plot;
opPatternTest = f[x_?NumericQ] := x;
compound = (a; b; c);
compoundNull = (a; b;);
mapIndexed = MapIndexed[List, {a, b}];
partAssign = (list[[2]] = 5; list[[1 ;; 2]] = {0, 0});
timesEqual = (x *= 2; x /= 2; x ^= 2; x -= 1; x += 1);
unset = (x =.; f[1] =.);
mapThread = MapThread[Plus, {{1, 2}, {3, 4}}];
outer = Outer[Times, {1, 2}, {3, 4}];
inner = Inner[Times, {1, 2}, {3, 4}, Plus];
dotProduct = {1, 2, 3} . {4, 5, 6};
crossProduct = {1, 0, 0} \[Cross] {0, 1, 0};
power = x^y^z;
dividing = a/b/c;
unary = -a + +b - -c;
factorial = n! + n!! + (n - 1)!;
transposeOp = m\[Transpose];
conjugateOp = z\[Conjugate];
derivative = f'[x] + f''[x] + f'''[x];
derivativeOf = D[Sin[x], x] + D[Sin[x], {x, 2}] + Derivative[1][f][x];
integral = Integrate[x^2, x] + Integrate[x^2, {x, 0, 1}] + \[Integral] x^2 \[DifferentialD]x;
limit = Limit[Sin[x]/x, x -> 0];
solve = Solve[x^2 - 3 x + 2 == 0, x] + DSolve[y'[x] == y[x], y[x], x] + NSolve[x^3 == 2, x] + FindRoot[Cos[x] == x, {x, 1}];
minimize = Minimize[x^2 + 1, x] + NMinimize[{x^2, x >= 1}, x] + FindMinimum[x^2, {x, 1}];
rules2 = {x -> 1, y -> 2} /. {a_ -> b_} :> {b, a};
sorting = SortBy[orders, #["total"] &] ~Join~ Reverse[Sort[Range[5]]];
strings2 = StringSplit["a,b,c", ","] ~Join~ StringReplace["abc", "b" -> "X"] ~Join~ StringCases["a1b22", DigitCharacter ..] ~Join~ StringTake["abc", 2] ~Join~ StringDrop["abc", 1];
patterns = {x : _Integer, y : _String, z : {__}, h : Except[0], s : Longest[__], t : Shortest[__], r : OrderlessPatternSequence[__]};
repeatedPat = {a, b, c} /. {x__, y_} :> y;
pattern2 = a : (_Integer | _Real);
conditionalPat = x_ /; x > 0 && EvenQ[x];
optionalPat = {a_, b_ : 1, c_. };
patternTest2 = {x_?Positive, y_?(# > 1 &)};
blankSeq = {__Integer, ___String, _?NumericQ, __h};
stringPatterns = "a" ~~ __ ~~ "z" | StartOfString ~~ Whitespace ~~ EndOfString | WordBoundary | LetterCharacter | DigitCharacter | WhitespaceCharacter | PunctuationCharacter | NumberString | Except[WordCharacter];
regexPattern = StringCases["Ab12", RegularExpression["[A-Za-z]+(\\d+)"] :> "$1"];
nestedAssoc = <|"a" -> <|"b" -> {1, <|"c" -> 2|>}|>|>;
assocOps = Association[{"a" -> 1}] ~Join~ <|"b" -> 2|>;
assocPart = nestedAssoc["a", "b", 1];
missingKey = nestedAssoc[Missing["KeyAbsent", "x"]];
lookup = Lookup[<|"a" -> 1|>, "a", 0];
keyMap = KeyMap[ToUpperCase, <|"a" -> 1|>];
assocMap = Map[#^2 &, <|"a" -> 1, "b" -> 2|>];
queryOp = Query[Select[#a > 1 &], "b"][Dataset[{<|"a" -> 2, "b" -> 3|>}]];
associationMapping = AssociationMap[# -> #^2 &, Range[3]];
entityFunction = Entity["Country", "UnitedKingdom"]["Population"];
quantity = Quantity[5, "Meters"] + UnitConvert[Quantity[1, "Kilometers"], "Meters"];
dateObject = DateObject[{2026, 3, 1}] + Quantity[1, "Days"];
graphics2 = Graphics[{Circle[], Point[{0, 0}], Polygon[{{0, 0}, {1, 0}, {0, 1}}], Arrow[{{0, 0}, {1, 1}}], Inset["text", {0, 0}]}, PlotRange -> All, ImageSize -> Medium, Frame -> True];
boxes = RowBox[{"x", "+", "y"}];
boxes2 = FractionBox["a", "b"] ~Join~ SuperscriptBox["x", "2"] ~Join~ SqrtBox["x"] ~Join~ GridBox[{{"a", "b"}}];
boxInString = "\!\(\*SuperscriptBox[\(x\), \(2\)]\)";
specialChars = {\[Alpha], \[Beta], \[Gamma], \[Pi], \[Infinity], \[Degree], \[Sum], \[Product], \[Integral], \[PartialD], \[Del], \[Element], \[ForAll], \[Exists], \[Rule], \[RuleDelayed], \[Equal], \[NotEqual], \[LessEqual], \[GreaterEqual], \[And], \[Or], \[Not], \[Xor], \[Implies], \[Therefore], \[Because], \[LeftAngleBracket], \[RightAngleBracket], \[LeftDoubleBracket], \[RightDoubleBracket], \[LeftAssociation], \[RightAssociation], \[Placeholder], \[ConstantC], \[ExponentialE], \[ImaginaryI], \[ImaginaryJ], \[DoubleStruckCapitalR], \[ScriptCapitalL], \[Backslash], \[VerticalBar], \[Cross], \[CenterDot], \[Times], \[Divide], \[PlusMinus], \[MinusPlus], \[Sqrt], \[Transpose], \[Conjugate], \[Dagger], \[Wedge], \[Vee], \[Union], \[Intersection], \[Subset], \[Superset], \[EmptySet], \[Congruent], \[Tilde], \[TildeEqual], \[TildeTilde], \[Proportional], \[Perpendicular], \[Parallel], \[Angle], \[LongRightArrow], \[RightArrow], \[LeftArrow], \[UpArrow], \[DownArrow], \[LeftRightArrow], \[DoubleRightArrow], \[Function], \[Bullet], \[Ellipsis], \[Copyright], \[Trademark], \[Euro], \[Pound]};
hexChars = "\:2603 \.41 \101 \|01F4E6";
slots = {#, #1, #2, ##, ##2, #name, #0};
functions3 = {# &, #1 + #2 &, Function[x, x], Function[{x, y}, x + y, Listable], Function[Null, #, HoldAll]};
namedPattern = f[x_, OptionsPattern[]] := OptionValue[Method];
optionsPattern = Options[f] = {Method -> Automatic, "Extra" :> 0};
asyncTasks = {SessionSubmit[Pause[1]], ParallelMap[#^2 &, Range[10]], ParallelTable[i, {i, 4}], LaunchKernels[2], URLRead["https://example.com"], URLExecute["https://example.com", "RawJSON"]};
packages = {Needs["Warehouse`"], Get["file.m"], Install["link"], ExternalEvaluate["Python", "1+1"], RunProcess[{"ls"}], StartProcess[{"cat"}]};

(* ── Control flow ───────────────────────────────────────── *)
loops = (
  Do[Print[i], {i, 1, 5}];
  Do[Print[i, j], {i, 3}, {j, i}];
  For[i = 0, i < 3, i++, Print[i]];
  While[n > 0, n--];
  Table[i^2, {i, 10}];
  Table[i + j, {i, 3}, {j, 3}];
  Sum[1/k^2, {k, 1, Infinity}];
  Product[k, {k, 1, 10}];
  Nest[f, x, 3];
  NestWhile[# + 1 &, 1, # < 10 &];
  FixedPoint[Cos, 1.0];
  Do[If[i == 3, Break[]], {i, 10}];
  Do[If[i == 3, Continue[]], {i, 10}]
);

scoped = Module[{a = 1, b = 2, c}, c = a + b; c^2];
blockScope = Block[{$RecursionLimit = 100}, fib[10]];
withScope = With[{k = 3}, Table[i k, {i, 5}]];
manipulate = Manipulate[Plot[Sin[n x], {x, 0, 2 Pi}], {n, 1, 10, 1}];

safe = Check[1/0, "caught"];
caught = Catch[Do[If[i > 3, Throw[i]], {i, 10}]];
timed = TimeConstrained[Pause[5], 1, "timeout"];
failed = Quiet[Check[Message[Warehouse::badInput, 1]; $Failed, $Failed]];
asserted = Assert[revenue > 0];
confirm = Enclose[Confirm[ToExpression["1+"]], "failure" &];
messageDemo = Message[Warehouse::badInput, "x"];

(* ── Asynchronous, symbols, special syntax ──────────────── *)
$Context;
$ContextPath;
Global`global = 1;
System`Plus;
`local = 2;
symbolWithDollar$ = 5;
$RecursionLimit = 4096;
% ;
%% ;
%3 ;
out = Out[-1];
in = In[1];
slot0 = # &;
slotSeq = ## &;
get = << Warehouse`;
put = x >> "out.m";
putAppend = x >>> "out.m";
shell = !ls;
symbolic = HoldForm[1 + 1];
held = Hold[1 + 1];
unevaluated = Unevaluated[1 + 1];
releaseHold = ReleaseHold[Hold[1 + 1]];
evaluated = Evaluate[1 + 1];
holdAll = SetAttributes[hold, HoldAll];
tag = Tooltip[Style["Low", Red, Bold, 14], "Reorder now"];
$Failed;
Null;
True;
False;
None;
All;
Automatic;
Missing["NotAvailable"];

(* ── Graphics and plots ─────────────────────────────────── *)
Print /@ describe /@ orders;
Print["revenue: ", revenue];   (* 208.75 *)

ListLinePlot[#["total"] & /@ orders, PlotLabel -> "Order totals", PlotMarkers -> Automatic];
Plot[Sin[x] + Cos[2 x], {x, 0, 2 Pi}, PlotStyle -> {Thick, Blue}, Filling -> Axis];
Plot3D[Sin[x y], {x, 0, 3}, {y, 0, 3}, ColorFunction -> "Rainbow", Mesh -> None];
BarChart[Values[byStatus], ChartLabels -> Keys[byStatus], ChartStyle -> "Pastel"];
Graphics[{Red, Disk[{0, 0}, 1], Blue, Rectangle[{1, 1}, {2, 2}], Line[{{0, 0}, {2, 2}}], Text["warehouse", {1, 1}]}];
Graphics3D[{Opacity[0.5], Cube[], Sphere[{2, 0, 0}, 0.5]}, Axes -> True];
Grid[{{"SKU", "Qty"}, {"WGT-100", 12}}, Frame -> All, Alignment -> Left];
Row[{"revenue: ", revenue}];
Column[{"a", "b"}, Spacings -> 2];
Style["bold", FontWeight -> Bold, FontSize -> 14, FontColor -> RGBColor[0.2, 0.6, 0.4]];
ColorData["TemperatureMap"][0.5];
Dynamic[Clock[]];
Button["Reorder", Print["ordered"]];
Export["orders.csv", Dataset[orders]];
Import["https://example.com/stock.json", "RawJSON"];

(* ── Additions: newer constructs ────────────────────────── *)
(* ::Subsection:: *)
withDelayed = With[{k := RandomInteger[10]}, {k, k}];
echoed = 1 + 1 // Echo;
echoFn = Range[3] // EchoFunction[Total];
spliced = {1, Splice[{2, 3}], Nothing, 4};
inactive = Inactive[Plus][1, 2] // Activate;
labelled = Labeled[Plot[x, {x, 0, 1}], "line", Top];
fromTemplate = TemplateApply["Hello `1`", {"world"}];
templateSlots = TemplateObject[{"Item ", TemplateSlot["sku"]}];
trueFalse = {TrueQ[True], BooleanQ[False], MemberQ[{1, 2}, 1], FreeQ[{1}, 2]};
associationThread = AssociationThread[{"a", "b"} -> {1, 2}];
groupedBy = GroupBy[Range[10], EvenQ -> Total];
lookupFn = Lookup["a"][<|"a" -> 1|>];
strictOps = {a =!= b, a === b, a \[Equal] b};
arrayIdx = {{1, 2}, {3, 4}}[[All, 1]];
pureAssoc = <|"f" -> (#^2 &)|>["f"][3];
nestedFn = Function[{x}, Function[{y}, x + y]][1][2];
directed = Graph[{1 -> 2, 2 -> 3}, VertexLabels -> "Name"];

End[];
EndPackage[];
