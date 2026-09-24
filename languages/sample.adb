--  Ada 2012: a bounded stack of integers with a contract on Push.
with Ada.Text_IO; use Ada.Text_IO;

procedure Sample is
   Capacity : constant := 8;
   type Index is range 0 .. Capacity;
   type Buffer is array (Index range 1 .. Capacity) of Integer;

   Items : Buffer;
   Top   : Index := 0;

   procedure Push (Value : Integer) with Pre => Top < Capacity is
   begin
      Top := Top + 1;
      Items (Top) := Value;
   end Push;

   function Sum return Integer is
      Total : Integer := 0;
   begin
      for I in 1 .. Top loop
         Total := Total + Items (I);
      end loop;
      return Total;
   end Sum;
begin
   Push (10); Push (20); Push (12);
   Put_Line ("Sum of" & Index'Image (Top) & " items:" & Integer'Image (Sum));
end Sample;
