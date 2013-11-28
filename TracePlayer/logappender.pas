unit logappender;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  simplelog;

type
  Tlogappender = class(TInterfacedObject, Ilogappender)
    procedure dolog(sender:Tlog;s:string);
    procedure onLevelChange(sender:Tlog);
  end;

implementation

uses main;

procedure Tlogappender.dolog(sender:Tlog;s:string) ;
  begin
   MainForm.logging.append(s);
  end;

procedure Tlogappender.onLevelChange(sender:Tlog)   ;
  begin
  end;

end.

