program Sample;
{ Free Pascal / Delphi: a record, a class with a property, and a generic list. }
{$mode objfpc}{$H+}

uses
  SysUtils, Generics.Collections;

type
  TStatus = (stPending, stPaid, stCancelled);

  TOrder = class
  private
    FNumber: Integer;
    FTotal: Currency;
  public
    Status: TStatus;
    constructor Create(ANumber: Integer; ATotal: Currency);
    property Number: Integer read FNumber;
    property Total: Currency read FTotal;
    function Describe: string;
  end;

constructor TOrder.Create(ANumber: Integer; ATotal: Currency);
begin
  FNumber := ANumber; FTotal := ATotal; Status := stPending;
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

var
  Orders: specialize TObjectList<TOrder>;
  O: TOrder;
  Revenue: Currency = 0;
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
end.
