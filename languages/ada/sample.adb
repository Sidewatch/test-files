--  Warehouse inventory in Ada 2012: bounded stock tables, contracts, tasking,
--  generics, exceptions and a text report.
--  TODO: move the report formatting into its own child package.
--  FIXME: Restock does not saturate at Capacity.

pragma Ada_2012;
pragma Warnings (Off, "unused");
pragma Style_Checks (Off);

with Ada.Text_IO;            use Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Float_Text_IO;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.Containers.Vectors;
with Ada.Calendar;
with Interfaces;
with System;

procedure Sample is

   --  ── Numbers ───────────────────────────────────────────────────
   Decimal      : constant Integer := 1_000_000;
   Based_Hex    : constant Integer := 16#FF#;
   Based_Bin    : constant Integer := 2#1010_1010#;
   Based_Oct    : constant Integer := 8#755#;
   Real         : constant Float   := 3.141_592;
   Scientific   : constant Float   := 1.5E-3;
   Based_Real   : constant Float   := 16#F.FF#E+2;
   Named_Number : constant := 42;
   Named_Real   : constant := 2.0 ** 10;

   --  ── Characters and strings ────────────────────────────────────
   Letter  : constant Character := 'A';
   Quote   : constant Character := ''';
   Space   : constant Character := ' ';
   Banner  : constant String    := "Warehouse ""Alpha"" report";
   Newline : constant String    := "line one" & ASCII.LF & "line two";
   Wide    : constant Wide_String := "wide é";
   WWide   : constant Wide_Wide_String := "wider 世界";

   --  ── Types ─────────────────────────────────────────────────────
   Capacity : constant := 8;

   type Index is range 0 .. Capacity;
   subtype Valid_Index is Index range 1 .. Capacity;
   type Quantity is new Natural range 0 .. 10_000;
   type Price is delta 0.01 digits 9;
   type Fixed_Weight is delta 0.001 range 0.0 .. 1_000.0;
   type Modular_Id is mod 2 ** 16;
   type Real_Value is digits 10 range -1.0E6 .. 1.0E6;

   type Category is (Tools, Parts, Fasteners, Chemicals);
   for Category use (Tools => 1, Parts => 2, Fasteners => 4, Chemicals => 8);

   type Buffer is array (Valid_Index) of Integer;
   type Matrix is array (1 .. 3, 1 .. 3) of Float;
   type Names is array (Positive range <>) of Unbounded_String;

   type Item is record
      SKU      : String (1 .. 5) := "A-100";
      Qty      : Quantity := 0;
      Unit     : Price    := 0.0;
      Kind     : Category := Tools;
      Weight   : Fixed_Weight := 0.0;
   end record;

   type Item_Access is access all Item;
   type Callback is access procedure (Value : Integer);

   type Shape is tagged record
      Id : Natural;
   end record;
   type Box is new Shape with record
      Width, Height : Natural;
   end record;

   type Animal is interface;
   procedure Speak (A : Animal) is abstract;

   type Variant (Kind : Category := Tools) is record
      case Kind is
         when Tools | Parts => Count : Natural;
         when Fasteners     => Size  : Float;
         when others        => null;
      end case;
   end record;

   --  ── Variables ─────────────────────────────────────────────────
   Items   : Buffer := (others => 0);
   Grid    : Matrix := ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0));
   Top     : Index := 0;
   Stock   : Item;
   Pointer : Item_Access := new Item'(SKU => "B-200", Qty => 5, others => <>);
   Counter : aliased Integer := 0;
   Port    : Integer with Volatile, Address => System'To_Address (16#4000#);

   --  ── Exceptions ────────────────────────────────────────────────
   Stack_Full  : exception;
   Out_Of_Stock : exception;

   --  ── Generic ───────────────────────────────────────────────────
   generic
      type Element is private;
      with function "<" (L, R : Element) return Boolean is <>;
   function Maximum (A, B : Element) return Element;

   function Maximum (A, B : Element) return Element is
   begin
      if A < B then
         return B;
      else
         return A;
      end if;
   end Maximum;

   function Max_Int is new Maximum (Integer);

   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Item);

   --  ── Subprograms with contracts ────────────────────────────────
   procedure Push (Value : Integer)
     with Pre  => Top < Capacity,
          Post => Top = Top'Old + 1;

   procedure Push (Value : Integer) is
   begin
      Top := Top + 1;
      Items (Top) := Value;
   end Push;

   function Sum return Integer
     with Global => (Input => (Items, Top));

   function Sum return Integer is
      Total : Integer := 0;
   begin
      for I in 1 .. Top loop
         Total := Total + Items (I);
      end loop;
      return Total;
   end Sum;

   function Is_Low (Q : Quantity) return Boolean is (Q < 25);

   procedure Swap (A, B : in out Integer) is
      Tmp : constant Integer := A;
   begin
      A := B;
      B := Tmp;
   end Swap;

   procedure Report (Label : in String := "stock"; Value : out Integer; Extra : access Integer := null) is
   begin
      Value := Sum;
   end Report;

   function "+" (L, R : Item) return Item is
     (SKU => L.SKU, Qty => L.Qty + R.Qty, Unit => L.Unit, Kind => L.Kind, Weight => L.Weight);

   --  ── Tasking ───────────────────────────────────────────────────
   protected type Counter_Type is
      procedure Increment;
      function Value return Natural;
   private
      Count : Natural := 0;
   end Counter_Type;

   protected body Counter_Type is
      procedure Increment is
      begin
         Count := Count + 1;
      end Increment;

      function Value return Natural is
      begin
         return Count;
      end Value;
   end Counter_Type;

   task type Worker is
      entry Start (Id : in Natural);
      entry Stop;
   end Worker;

   task body Worker is
      My_Id : Natural := 0;
   begin
      accept Start (Id : in Natural) do
         My_Id := Id;
      end Start;
      loop
         select
            accept Stop;
            exit;
         or
            delay 0.5;
         or
            terminate;
         end select;
      end loop;
   end Worker;

   W : Worker;
   C : Counter_Type;

   --  ── Declare-block variable ────────────────────────────────────
   Result : Integer;
   Found  : Boolean := False;

begin
   --  ── Statements ────────────────────────────────────────────────
   Push (10); Push (20); Push (12);
   Swap (Items (1), Items (2));
   Report (Value => Result);
   Result := Max_Int (3, 9);

   --  Conditionals
   if Result > 10 and then Top /= 0 then
      Put_Line ("big");
   elsif Result = 5 or else not Found then
      Put_Line ("five");
   elsif (Result >= 1 and Result <= 3) xor Found then
      Put_Line ("small");
   else
      Put_Line ("other");
   end if;

   --  Case
   case Stock.Kind is
      when Tools .. Parts => Put_Line ("hardware");
      when Fasteners      => Put_Line ("small parts");
      when others         => Put_Line ("hazard");
   end case;

   --  Loops
   for I in reverse 1 .. 3 loop
      Put (Integer'Image (I));
   end loop;
   for Cat in Category loop
      exit when Cat = Chemicals;
   end loop;
   for Item of Items loop
      null;
   end loop;

   while Top > 0 loop
      Top := Top - 1;
   end loop;

   Outer :
   loop
      loop
         exit Outer when Result = 0;
      end loop;
   end loop Outer;

   --  Operators and attributes
   Result := (Result + 1) * 2 - 3 / 1 mod 4 rem 5;
   Result := abs (-5) ** 2;
   Result := Integer'Max (1, 2) + Items'Length + Items'First + Items'Last;
   Put_Line (Index'Image (Top) & " " & Integer'Image (Integer'Succ (Result)));
   Put_Line (Boolean'Image (Items'Valid) & Float'Image (Float'Last));

   --  Qualified expressions, aggregates, ranges
   Stock := Item'(SKU => "C-300", Qty => 3, Unit => 9.99, Kind => Parts, Weight => 0.25);
   Items := (1 => 1, 2 .. 4 => 0, others => 9);
   Put_Line (Boolean'Image (Items (1)'Valid));

   --  Quantified, conditional and case expressions
   Found := (for all I in Items'Range => Items (I) >= 0);
   Found := (for some I in Items'Range => Items (I) = 9);
   Result := (if Found then 1 else 0);
   Result := (case Stock.Kind is when Tools => 1, when others => 0);

   --  Declare block and exceptions
   declare
      Local : constant String := "scoped";
   begin
      Put_Line (Local);
      if Top = Capacity then
         raise Stack_Full with "full at " & Index'Image (Top);
      end if;
   exception
      when Stack_Full =>
         Put_Line ("recovered");
      when E : others =>
         Put_Line (Ada.Exceptions.Exception_Message (E));
         raise;
   end;

   --  Tasks and entry calls
   W.Start (1);
   C.Increment;
   Put_Line (Natural'Image (C.Value));
   W.Stop;

   --  Delay, abort, goto
   delay 0.1;
   delay until Ada.Calendar.Clock;
   <<Retry>>
   if Result < 0 then
      goto Retry;
   end if;

   --  Select with timed entry
   select
      W.Stop;
   or
      delay 1.0;
   end select;

   pragma Assert (Result >= 0, "result must be non-negative");
exception
   when Constraint_Error | Program_Error =>
      Put_Line (Standard_Error, "constraint problem");
   when Out_Of_Stock =>
      null;
end Sample;

--  ── Further constructs: separate units, representation, pragmas ────

--  Package specification and body shown as compilation units in a
--  single file for demonstration of the syntax.
package Warehouse.Types is
   pragma Pure;
   pragma Preelaborate (Warehouse.Types);
   pragma Elaborate_Body;
   pragma Inline (Max_Int_Wrapper);
   pragma Import (C, C_Strlen, "strlen");
   pragma Export (C, Exported_Name, "exported");
   pragma Convention (C, Item_Rec);
   pragma Unreferenced (Debug_Flag);
   pragma Suppress (Range_Check);
   pragma Restrictions (No_Floating_Point);
   pragma Assertion_Policy (Check);
   pragma Pack (Packed_Rec);
   pragma Atomic (Shared_Flag);
   pragma Pure_Function (Square);

   Debug_Flag : constant Boolean := False;

   type Packed_Rec is record
      A : Boolean;
      B : Integer range 0 .. 7;
      C : Character;
   end record
     with Pack, Size => 16;

   for Packed_Rec use record
      A at 0 range 0 .. 0;
      B at 0 range 1 .. 3;
      C at 1 range 0 .. 7;
   end record;
   for Packed_Rec'Alignment use 1;

   type Color is (Red, Green, Blue);
   for Color'Size use 8;
   type Color_Array is array (Color) of Natural;
   type Unconstrained is array (Positive range <>) of Character;
   type Handle is limited private;
   type Discr_Rec (N : Natural := 0) is record
      Data : String (1 .. N);
   end record;
   type Callback_Access is access function (X : Integer) return Integer;
   type Ptr is access constant Integer;
   type General_Access is access all Integer;
   type Tagged_Root is abstract tagged null record;
   type Child is new Tagged_Root with null record;
   type Mix is new Child and Animal with record
      Extra : Integer;
   end record;
   type Counter is range 0 .. 2 ** 31 - 1 with Default_Value => 0;
   type Bounded is range 1 .. 10 with Static_Predicate => Bounded /= 5;
   subtype Even is Integer with Dynamic_Predicate => Even mod 2 = 0;
   type Stack is private;

   function Square (X : Integer) return Integer is (X * X);
   function Image (V : Color) return String is (Color'Image (V));
   procedure Do_Nothing is null;
   procedure Overriding_Example (X : in out Child) with Inline;
   function C_Strlen (S : System.Address) return Integer;
   function Make return Handle;
   Exported_Name : Integer := 0;
   Shared_Flag : Boolean := False with Atomic;

   Ghost_Value : constant Integer := 1 with Ghost;
private
   type Handle is limited record
      Id : Natural := 0;
   end record;
   type Stack is record
      Top : Natural := 0;
   end record;
end Warehouse.Types;

with Warehouse.Types; use type Warehouse.Types.Color;
limited with Warehouse.Parent;
private with Ada.Finalization;

package body Warehouse.Types is
   use all type Color;

   Max_Int_Wrapper : Integer renames Integer'Last;
   package Colors renames Warehouse.Types;
   function "&" (L, R : Color) return Integer is (Color'Pos (L) + Color'Pos (R));

   procedure Overriding_Example (X : in out Child) is
   begin
      null;
   end Overriding_Example;

   overriding
   procedure Finalize (Object : in out Handle) is
   begin
      null;
   end Finalize;

   not overriding
   function Make return Handle is
   begin
      return (Id => 1);
   end Make;

   function Fact (N : Natural) return Natural is
   begin
      return (if N <= 1 then 1 else N * Fact (N - 1));
   end Fact;

   procedure Raise_Demo is
   begin
      raise Constraint_Error with "message";
   exception
      when Constraint_Error =>
         raise Program_Error;
   end Raise_Demo;

   procedure Separate_Unit is separate;

   task Single_Task;
   task body Single_Task is
   begin
      select
         delay 1.0;
      then abort
         null;
      end select;
      abort Single_Task;
   end Single_Task;

   function Extended_Return return Integer is
   begin
      return Result : Integer := 3 do
         Result := Result + 1;
      end return;
   end Extended_Return;

   generic
      type T is private;
      with procedure Visit (X : T);
      with package P is new Ada.Containers.Vectors (<>);
      Count : Positive := 1;
   package Visitors is
   end Visitors;

   procedure Asm_Demo is
      pragma Warnings (Off);
   begin
      for I in Integer range 1 .. 3 loop
         null;
      end loop;
      for I in reverse Positive range 1 .. 3 loop
         null;
      end loop;
      Ada.Text_IO.Put_Line ("x" & Character'Val (10) & Wide_Character'Val (233)'Img);
   end Asm_Demo;
begin
   null;
end Warehouse.Types;
