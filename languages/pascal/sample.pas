program Sample;
{ Free Pascal 3.2 / Delphi 13 — syntax showcase: records, classes, generics, sets, pointers and exceptions. }
(* Old-style block comment
   over several lines *)
// A line comment
{ TODO: persist orders }
{ FIXME: rounding of Currency }
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$IFDEF DEBUG}
  {$DEFINE VERBOSE}
{$ELSE}
  {$UNDEF VERBOSE}
{$ENDIF}
{$IFNDEF FPC}{$APPTYPE CONSOLE}{$ENDIF}
{$R+}{$Q-}
{$I inventory.inc}
{$INCLUDE common.inc}
{$M+}
{$WARN 5024 OFF}
{$ifdef CPU64}{$define BIGINT}{$endif}

uses
  SysUtils, Classes, Math, StrUtils, Generics.Collections, Variants;

const
  ReorderPoint = 25;
  Greeting = 'Hello, "inventory" it''s ready';
  Pi2 = 6.283185307;
  HexMask = $FF;
  OctMask = &755;
  BinMask = %1010_1010;
  BigNum = 1_000_000;
  SciNum = 1.5E-3;
  CharConst = #65#66#67;
  Tab = #9;
  CtrlChar = ^A;
  Quote = '''';
  Names: array[0..2] of string = ('north', 'south', 'east');
  MaxItems = High(Byte);

type
  TStatus = (stPending, stPaid, stCancelled);
  TStatusSet = set of TStatus;
  TWeekday = 1..7;
  TLetter = 'a'..'z';
  PInteger = ^Integer;
  TIntArray = array of Integer;
  TMatrix = array[1..3, 1..3] of Double;
  TName = string[40];
  TCallback = procedure(Sender: TObject; Index: Integer) of object;
  TFunc = function(X: Integer): Integer;
  TRef = reference to function(X: Integer): Integer;

  TPoint = record
    X, Y: Double;
    function Length: Double;
    class operator Add(const A, B: TPoint): TPoint;
  end;

  TVariantRec = record
    case Kind: Integer of
      0: (AsInt: Integer);
      1: (AsFloat: Double);
      2: (AsChar: Char);
  end;

  IShippable = interface(IUnknown)
    ['{8F1E5C2A-3B4D-4E6F-9A0B-1C2D3E4F5A6B}']
    function TrackingNumber: string;
    procedure Ship(const Where: string);
  end;

  EOrderError = class(Exception);

  TOrder = class(TInterfacedObject, IShippable)
  private
    FNumber: Integer;
    FTotal: Currency;
    FTags: TStringList;
    function GetTotal: Currency;
  protected
    procedure Validate; virtual;
  public
    Status: TStatus;
    constructor Create(ANumber: Integer; ATotal: Currency);
    destructor Destroy; override;
    class function Count: Integer; static;
    property Number: Integer read FNumber;
    property Total: Currency read GetTotal write FTotal;
    property Tags: TStringList read FTags;
    property Items[Index: Integer]: string read GetItem write SetItem; default;
    function Describe: string; overload;
    function Describe(const Prefix: string): string; overload;
    function TrackingNumber: string;
    procedure Ship(const Where: string);
  published
    property Label_: string read FLabel write FLabel stored True;
  end;

  generic TStack<T> = class
  private
    FItems: array of T;
  public
    procedure Push(const Item: T);
    function Pop: T;
  end;

  TIntStack = specialize TStack<Integer>;

  TBase = class abstract
    procedure Run; virtual; abstract;
  end;

  TDerived = class sealed(TBase)
    procedure Run; override;
  end;

  TOrderHelper = class helper for TOrder
    procedure Touch;
  end;

var
  Orders: specialize TObjectList<TOrder>;
  O: TOrder;
  Revenue: Currency = 0;
  I, J: Integer;
  S: string;
  Ch: Char;
  P: PInteger;
  Flags: TStatusSet;
  Matrix: TMatrix;
  V: Variant;
  F: TextFile;
  Fn: TFunc;

threadvar
  Scratch: Integer;

label
  Done;

resourcestring
  SNotFound = 'Order %d not found';

function TPoint.Length: Double;
begin
  Result := Sqrt(Sqr(X) + Sqr(Y));
end;

class operator TPoint.Add(const A, B: TPoint): TPoint;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
end;

constructor TOrder.Create(ANumber: Integer; ATotal: Currency);
begin
  inherited Create;
  FNumber := ANumber; FTotal := ATotal; Status := stPending;
  FTags := TStringList.Create;
end;

destructor TOrder.Destroy;
begin
  FTags.Free;
  inherited;
end;

function TOrder.GetTotal: Currency;
begin
  Result := FTotal;
end;

procedure TOrder.Validate;
begin
  if FTotal < 0 then
    raise EOrderError.CreateFmt('Negative total for %d', [FNumber]);
end;

function TOrder.Describe: string;
begin
  case Status of
    stPaid: Result := Format('#%d paid %m', [FNumber, FTotal]);
    stCancelled: Result := Format('#%d cancelled', [FNumber]);
  else
    Result := Format('#%d pending', [FNumber]);
  end;
end;

function TOrder.Describe(const Prefix: string): string;
begin
  Result := Prefix + Describe;
end;

function Factorial(N: Integer): Int64;
begin
  if N <= 1 then Result := 1 else Result := N * Factorial(N - 1);
end;

procedure Swap(var A, B: Integer);
var
  Tmp: Integer;
begin
  Tmp := A; A := B; B := Tmp;
end;

procedure Defaults(A: Integer; const B: string = 'x'; out C: Integer);
begin
  C := A;
end;

function Sum(const Values: array of Integer): Integer;
var
  V: Integer;
begin
  Result := 0;
  for V in Values do Inc(Result, V);
end;

procedure Nested;
  procedure Inner;
  begin
    WriteLn('inner');
  end;
begin
  Inner;
end;

{ ── More Pascal: legacy objects, packed types, calling conventions, operators ── }
{$MACRO ON}
{$DEFINE SQUARE := 4}
{$IF DEFINED(FPC) AND (FPC_VERSION >= 3)}
  {$MESSAGE NOTE 'Free Pascal 3 or newer'}
{$ELSEIF DEFINED(DELPHI)}
  {$MESSAGE WARN 'Delphi'}
{$ELSE}
  {$MESSAGE ERROR 'unsupported'}
{$ENDIF}
{$IFOPT R+}{$DEFINE RANGE_CHECKS}{$ENDIF}
{$HINTS OFF}{$NOTES ON}{$WARNINGS ON}
{$ASMMODE INTEL}
{$PACKRECORDS 1}
{$ALIGN 8}
{$CALLING cdecl}
{$LINK helper.o}
{$LINKLIB m}
{$PUSH}{$OPTIMIZATION ON}{$POP}
{$H-}{$J+}{$X+}{$T-}
{$SCOPEDENUMS ON}
{$RTTI EXPLICIT METHODS([vcPublic])}

const
  Pi3 = 3.14159265358979;
  Neg = -42;
  HexLong = $DEADBEEF;
  CharRange = 'a'..'z';
  BoolConst = True;
  NilPtr = nil;
  StrOfChar = #$41#$42;
  ZeroPad = 0.0;
  Primes: array[1..5] of Integer = (2, 3, 5, 7, 11);
  Grid: array[0..1, 0..1] of Integer = ((1, 2), (3, 4));
  Origin: record X, Y: Integer end = (X: 0; Y: 0);

type
  TByteSet = set of Byte;
  TCharSet = set of Char;
  TPackedRec = packed record
    Flag: Boolean;
    Value: Word;
    Big: LongWord;
  end;
  TBitArr = packed array[0..7] of Boolean;
  TFileOfInt = file of Integer;
  TUntyped = file;
  TProcVar = procedure(var X: Integer; const S: string; out R: Boolean);
  TMethodVar = function(A, B: Integer): Integer of object;
  TStatic = array[0..9] of Char;
  PRec = ^TPackedRec;
  PPChar = ^PChar;
  TEnumRange = (erA = 1, erB = 5, erC = 10);
  TSubRange = Low(Integer)..High(Integer);
  TStrRange = string[255];
  TNested = record
    Inner: record A, B: Integer end;
    List: array of record N: Integer end;
  end;

  TLegacyObject = object
    Data: Integer;
    constructor Init(AData: Integer);
    destructor Done; virtual;
    procedure Show; virtual;
  end;

  TWithClassVar = class
  strict private
    FSecret: Integer;
  strict protected
    procedure Hook; virtual;
  public
    class var Counter: Integer;
    class constructor Create;
    class destructor Destroy;
    const Limit = 10;
    type TInner = (iOne, iTwo);
    var Plain: Integer;
    property Indexed[AIndex: Integer; const AKey: string]: Integer read GetIndexed write SetIndexed;
    property ByIndex: Integer index 3 read GetByIndex write SetByIndex;
    property Stored: Boolean read FStored write FStored stored False default True;
    property Named: string read FName write FName nodefault;
    procedure OneShot; message 42;
    procedure Reintroduced; reintroduce;
    function Cdecl: Integer; cdecl;
    function StdCall(X: Integer): Integer; stdcall;
    function RegisterCall: Integer; register;
    procedure Safe; safecall;
    procedure Inlined; inline;
    procedure Deprecated1; deprecated 'use New';
    procedure Platform1; platform;
    procedure Experimental1; experimental;
    procedure Library1; library;
    procedure Final1; virtual; final;
  end;

  TOperators = record
    V: Integer;
    class operator Add(A, B: TOperators): TOperators;
    class operator Subtract(A, B: TOperators): TOperators;
    class operator Multiply(A, B: TOperators): TOperators;
    class operator Divide(A, B: TOperators): TOperators;
    class operator Equal(A, B: TOperators): Boolean;
    class operator LessThan(A, B: TOperators): Boolean;
    class operator Implicit(A: Integer): TOperators;
    class operator Explicit(A: TOperators): Integer;
    class operator Negative(A: TOperators): TOperators;
    class operator Inc(A: TOperators): TOperators;
    class operator LogicalNot(A: TOperators): TOperators;
    class operator In(A: Integer; B: TOperators): Boolean;
  end;

  generic TPair<K, V> = record
    Key: K;
    Value: V;
  end;

  TStringIntPair = specialize TPair<string, Integer>;
  TGenericFn = specialize TFunc<Integer, string>;

  generic TBox<T: class, constructor> = class
    function Make: T;
  end;

var
  Absolute1: Integer;
  Absolute2: Integer absolute Absolute1;
  AtAddr: Integer absolute $0040;
  ExternalVar: Integer; external name 'ext_var';
  Initialised: Integer = 42;
  Arr2D: array[1..3, 1..3] of Integer;
  DynArr: array of array of Integer;
  CStr: PChar;
  PtrToPtr: ^^Integer;
  Cplx: record Re, Im: Double end;
  Callback2: procedure(X: Integer);
  OnEvent: TNotifyEvent;
  WideStr: WideString;
  UStr: UnicodeString;
  AStr: AnsiString;
  Sh: ShortString;
  Utf8: UTF8String;
  Chr2: WideChar;
  Big64: QWord;
  SmallI: ShortInt;
  Tiny: Byte;
  Single1: Single;
  Ext: Extended;
  Comp1: Comp;
  VarOf: array of const;
  PtrVar: Pointer;
  CurrVar: Currency;
  Rect: record Left, Top, Right, Bottom: Integer end;

procedure Forwarded(X: Integer); forward;
procedure ExternalProc(X: Integer); cdecl; external 'libc' name 'puts';
function ExternalFn: Integer; external 'lib.dll' index 5;
procedure Assembly; assembler;
asm
  mov eax, 1
  ret
end;

procedure VarArgs(const Args: array of const);
var
  I: Integer;
begin
  for I := 0 to High(Args) do
    case Args[I].VType of
      vtInteger: Write(Args[I].VInteger);
      vtBoolean: Write(Args[I].VBoolean);
      vtChar: Write(Args[I].VChar);
      vtExtended: Write(Args[I].VExtended^);
      vtString: Write(Args[I].VString^);
      vtPChar: Write(Args[I].VPChar);
      vtObject: Write(Args[I].VObject.ClassName);
    end;
end;

procedure Forwarded(X: Integer);
label
  Retry, Finish;
const
  LocalConst = 5;
type
  TLocal = record A: Integer end;
var
  L: TLocal;
  Tmp: Integer;
begin
  Tmp := X;
Retry:
  Dec(Tmp);
  if Tmp > 0 then goto Retry;
  L.A := LocalConst;
  with L do A := A + 1;
  Finish:
end;

operator + (A, B: TStringIntPair): TStringIntPair;
begin
  Result.Key := A.Key + B.Key;
  Result.Value := A.Value + B.Value;
end;

operator ** (Base, Exponent: Double): Double;
begin
  Result := Exp(Exponent * Ln(Base));
end;

function Overloaded(A: Integer): Integer; overload;
begin
  Result := A;
end;

function Overloaded(const A: string): Integer; overload;
begin
  Result := Length(A);
end;

function Inline1(X: Integer): Integer; inline;
begin
  Result := X * SQUARE;
end;

procedure Exceptions;
begin
  try
    raise Exception.Create('x') at get_caller_addr(get_frame), get_caller_frame(get_frame);
  except
    on E: EAccessViolation do WriteLn('av');
    on E: EDivByZero do WriteLn('div');
    on EConvertError do WriteLn('conv');
    on E: Exception do begin WriteLn(E.ClassName, ': ', E.Message); raise; end;
  else
    WriteLn('other');
  end;
  try
    Abort;
  finally
    WriteLn('done');
  end;
end;

procedure Strings;
var
  S: string;
  P: PChar;
  C: Char;
begin
  S := 'It''s a "test" with ''quotes''';
  S := S + #13#10 + #$1F + #1234 + ^M + ^[ ;
  S := 'Tab' + #9 + 'Bell' + #7;
  S := Format('%s %d %5.2f %x %e %p %m %n', ['a', 1, 2.5, 255, 1.0, nil, 5.0, 6.0]);
  P := PChar(S);
  C := S[1];
  S[1] := UpCase(C);
  Delete(S, 1, 1); Insert('x', S, 1); SetLength(S, 5);
  S := Copy(S, 2, 3) + IntToStr(5) + FloatToStr(1.5) + UpperCase(S) + Trim(S);
  Str(3.14:8:2, S);
end;

procedure ControlFlow;
var
  I, J: Integer;
  Ch: Char;
begin
  for I := Low(Primes) to High(Primes) do
    for J := I downto 0 do
      if (I + J) mod 2 = 0 then Continue else Break;
  for Ch in ['a'..'c', 'x'] do Write(Ch);
  case I of
    Low(Integer)..-1: WriteLn('neg');
    0: WriteLn('zero');
    1, 3, 5, 7: WriteLn('odd');
    2..10: WriteLn('range');
    else WriteLn('big');
  end;
  repeat
    Inc(I);
    if I > 100 then Exit;
  until I mod 7 = 0;
  while True do begin Dec(I); if I < 0 then Break; end;
  if (I = 0) xor (J = 0) then Halt(1);
  I := Ord(Ch) + Succ(I) + Pred(J) + Abs(-5) + Round(2.5) + Trunc(2.9) + Sqr(3);
  J := I shl 2 or I shr 1 and 3 xor 255;
  Exit;
end;

begin
  Orders := specialize TObjectList<TOrder>.Create(True);
  try
    Orders.Add(TOrder.Create(1, 120.50));
    Orders[0].Status := stPaid;
    Orders.Add(TOrder.Create(2, 42));
    for O in Orders do
    begin
      WriteLn(O.Describe);
      if O.Status = stPaid then Revenue := Revenue + O.Total;
    end;
    WriteLn('revenue: ', Revenue:0:2);
  finally
    Orders.Free;
  end;

  { Operators and expressions }
  I := 7 div 2 + 7 mod 2 - 3 * 4;
  J := (I shl 2) or (I shr 1) and $0F xor 3;
  Revenue := 10 / 4;
  if (I > 0) and (J <> 0) or not (I = J) then WriteLn('logic');
  if (I >= 1) and (J <= 9) and (I < J) then WriteLn('cmp');
  S := 'abc' + Greeting + Tab + #13#10;
  Inc(I); Dec(J, 2); I += 1; J -= 1; I *= 2; J /= 2;
  Flags := [stPaid, stCancelled];
  Include(Flags, stPending);
  Exclude(Flags, stPaid);
  if stPaid in Flags then WriteLn('paid');
  if O is TOrder then WriteLn((O as TOrder).Describe);
  P := @I;
  P^ := 5;
  New(P); Dispose(P);
  Ch := 'x';
  Matrix[1, 1] := 1.0;
  V := Null;
  Fn := @Factorial;
  WriteLn(Fn(5), ' ', Sum([1, 2, 3]), ' ', SizeOf(Integer), ' ', High(Names));

  { Control flow }
  if I > 5 then
    WriteLn('big')
  else if I > 2 then
    WriteLn('medium')
  else
    WriteLn('small');
  for I := 1 to 10 do
  begin
    if I = 3 then Continue;
    if I = 8 then Break;
  end;
  for I := 10 downto 1 do Write(I, ' ');
  while I < 20 do Inc(I);
  repeat Dec(I) until I < 5;
  case Ch of
    'a'..'f': WriteLn('hex');
    'x', 'y': WriteLn('xy');
  else
    WriteLn('other');
  end;
  with Orders[0] do WriteLn(Number);
  goto Done;
  Done:
  try
    try
      raise EOrderError.Create('boom');
    except
      on E: EOrderError do WriteLn(E.Message);
      on E: Exception do raise;
    end;
  finally
    WriteLn('cleanup');
  end;
  Assign(F, 'out.txt'); Rewrite(F); WriteLn(F, 'hi'); CloseFile(F);
  asm
    nop
  end;
  Halt(0);
end.

{ ── The sections below are separate compilation units (unit, library, package); they cannot share a file
     with `program`, and are appended only so every form is highlighted. ── }

unit Sample.Modern;

{$IFDEF FPC}{$mode delphi}{$ENDIF}
{$SCOPEDENUMS ON}
{$ZEROBASEDSTRINGS OFF}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading, System.SyncObjs,
  Vcl.Forms in 'Vcl.Forms.pas', Winapi.Windows;

type
  TColor = (Red, Green, Blue);

  { Attributes (Delphi) }
  TestFixtureAttribute = class(TCustomAttribute)
  public
    constructor Create(const AName: string; AValue: Integer = 0);
  end;

  [TestFixture('orders', 1)]
  TOrderTests = class
  private
    [Weak] FOwner: TObject;
    [Volatile] FFlag: Boolean;
    [Ref] FRef: Integer;
  public
    [Test]
    [TestCase('One', '1,2')]
    procedure Adds(A, B: Integer);
  end;

  { Generics with constraints }
  TCache<TKey; TValue: class, constructor> = class
  strict private
    FMap: TDictionary<TKey, TValue>;
  public
    constructor Create;
    destructor Destroy; override;
    function GetOrAdd(const AKey: TKey): TValue;
    procedure ForEach(const AAction: TProc<TKey, TValue>);
  end;

  TComparerFn<T> = reference to function(const A, B: T): Integer;
  TNumeric<T: record> = record
    Value: T;
    class operator Implicit(const A: T): TNumeric<T>;
  end;

  { Managed records (Delphi 10.4+) }
  TManaged = record
    Data: Integer;
    class operator Initialize(out Dest: TManaged);
    class operator Finalize(var Dest: TManaged);
    class operator Assign(var Dest: TManaged; const [ref] Src: TManaged);
  end;

  { Record and class helpers, class references }
  TStringHelperEx = record helper for string
    function Twice: string;
  end;
  TOrderClass = class of TOrderTests;

  { Interfaces with GUIDs and method resolution }
  IReader = interface
    ['{11111111-2222-3333-4444-555555555555}']
    function Read: string;
    property Text: string read Read;
  end;
  IWriter = interface(IReader)
    ['{11111111-2222-3333-4444-555555555556}']
    procedure Write(const S: string);
  end;
  TReaderWriter = class(TInterfacedObject, IReader, IWriter)
    function IReader.Read = ReadImpl;
    function ReadImpl: string;
    procedure Write(const S: string);
  private
    FImpl: IReader;
  public
    property Impl: IReader read FImpl implements IReader;
  end;

  TDispatch = dispinterface
    ['{22222222-3333-4444-5555-666666666666}']
    procedure Ping; dispid 1;
  end;

  TBits = bitpacked array[0..7] of Boolean;
  TProc2 = procedure(X: Integer) is nested;
  TMethodRef = function(X: Integer): Integer of object;
  TCaller = reference to procedure;

const
  Pipe = '|';
  MultiLine = '''
    A Delphi multi-line string literal.
      Indentation is relative to the closing quotes.
    ''';
  Unicode = '日本語 ünïcödé';
  Version: record Major, Minor: Word end = (Major: 1; Minor: 4);

var
  GlobalCounter: Integer;
  GlobalCache: TCache<string, TObject>;

function Fibonacci(N: Integer): Int64; inline;
procedure Greet(const Name: string; Times: Integer = 1); overload;
procedure Greet(const Names: array of string); overload;
function Divide(A, B: Integer): Double; platform; deprecated 'use SafeDivide';

implementation

uses
  System.Math;

{$R *.res}

constructor TestFixtureAttribute.Create(const AName: string; AValue: Integer);
begin
  inherited Create;
end;

procedure TOrderTests.Adds(A, B: Integer);
begin
  Assert(A + B = 3, 'sum');
end;

constructor TCache<TKey, TValue>.Create;
begin
  inherited;
  FMap := TDictionary<TKey, TValue>.Create;
end;

destructor TCache<TKey, TValue>.Destroy;
begin
  FMap.Free;
  inherited;
end;

function TCache<TKey, TValue>.GetOrAdd(const AKey: TKey): TValue;
begin
  if not FMap.TryGetValue(AKey, Result) then
  begin
    Result := TValue.Create;
    FMap.Add(AKey, Result);
  end;
end;

procedure TCache<TKey, TValue>.ForEach(const AAction: TProc<TKey, TValue>);
var
  Pair: TPair<TKey, TValue>;
begin
  for Pair in FMap do AAction(Pair.Key, Pair.Value);
end;

class operator TManaged.Initialize(out Dest: TManaged);
begin
  Dest.Data := 0;
end;

class operator TManaged.Finalize(var Dest: TManaged);
begin
  Dest.Data := -1;
end;

class operator TManaged.Assign(var Dest: TManaged; const [ref] Src: TManaged);
begin
  Dest.Data := Src.Data;
end;

class operator TNumeric<T>.Implicit(const A: T): TNumeric<T>;
begin
  Result.Value := A;
end;

function TStringHelperEx.Twice: string;
begin
  Result := Self + Self;
end;

function TReaderWriter.ReadImpl: string; begin Result := 'x'; end;
procedure TReaderWriter.Write(const S: string); begin end;

function Fibonacci(N: Integer): Int64;
begin
  if N < 2 then Exit(N);
  Result := Fibonacci(N - 1) + Fibonacci(N - 2);
end;

procedure Greet(const Name: string; Times: Integer);
begin
  for var I := 1 to Times do
    WriteLn('Hello, ', Name);
end;

procedure Greet(const Names: array of string);
begin
  for var N in Names do Greet(N);
end;

function Divide(A, B: Integer): Double;
begin
  Result := A / B;
end;

procedure Modern;
var
  Total: Integer;
begin
  // Inline variable declarations, type inference, anonymous methods
  var X := 10;
  var Y: Integer := 20;
  var Fn: TFunc<Integer, Integer> := function(V: Integer): Integer begin Result := V * 2 end;
  var Proc: TProc := procedure begin Inc(Total) end;
  Proc();
  Total := Fn(X) + Y;
  for var I := 0 to 9 do Inc(Total, I);
  for var Item in [1, 2, 3] do Inc(Total, Item);
  for var Ch in 'abc' do Write(Ch);
  // Tasks and parallel loops
  var Tasks: TArray<ITask>;
  SetLength(Tasks, 2);
  Tasks[0] := TTask.Run(procedure begin Sleep(10) end);
  TParallel.For(0, 9, procedure(I: Integer) begin Write(I) end);
  TTask.WaitForAll(Tasks);
  // Case on strings
  case 'abc' of
    'abc', 'def': WriteLn('hit');
  else
    WriteLn('miss');
  end;
  // Try/except/finally with typed handlers
  try
    try
      raise EArgumentException.Create('bad');
    except
      on E: EArgumentException do WriteLn(E.Message);
      on E: Exception do raise;
    end;
  finally
    WriteLn('done');
  end;
  // Pointers and typecasts
  var P: PInteger := @X;
  P^ := PInteger(PByte(P) + 0)^;
  var O: TObject := TObject.Create;
  if O is TObject then (O as TObject).Free;
  // Strings, sets and literals
  var S := 'It''s ' + #13#10 + #$263A + ^G + 'end';
  S := Format('%s|%d|%8.3f|%x|%e|%p|%m', ['a', 1, 2.5, 255, 1.0, nil, 5.0]);
  var Digits: set of Byte := [0..9, 20, 30..39];
  var H := $FF + %1010 + &17 + 1_000;
  var F := 1.5e3 + 2E-2;
  Assert(H > 0);
  Include(Digits, 5);
end;

initialization
  GlobalCounter := 0;
  GlobalCache := TCache<string, TObject>.Create;

finalization
  GlobalCache.Free;

end.

library SampleLib;

uses
  System.SysUtils;

function Add(A, B: Integer): Integer; stdcall;
begin
  Result := A + B;
end;

procedure Hello; cdecl;
begin
  WriteLn('hello');
end;

exports
  Add,
  Hello name 'sample_hello',
  Add index 1 name 'SampleAdd';

begin
end.

package SamplePackage;

{$R *.res}
{$DESCRIPTION 'Sample package'}
{$LIBSUFFIX AUTO}
{$RUNONLY}

requires
  rtl,
  vcl;

contains
  Sample.Modern in 'Sample.Modern.pas';

end.
