unit session;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  Tsession = class ;

  TStrProc = procedure(session:Tsession;S: string);// execCLI(Fsession,s);

  Tsession = class
    Name: String;
    Prompt:String;
    path:String;
    lastPath:String;
    terminated : boolean;
    FonTerminate:TnotifyEvent;
    fonexec: TStrProc;
    fonexecResult: TGetStrProc;
    procedure terminate; virtual;
  public
    constructor create;
    procedure Promptadd(S:string);
    procedure EcexuteCmd(s:String);
    procedure writeResult(const txt:String); virtual;
    procedure writePrompt;
    property onTerminate:TnotifyEvent read FonTerminate write FonTerminate;
    property onexec:TStrProc read fonexec write fonexec;
    property onexecResult:TGetStrProc read fonexecResult write fonexecResult;
  end;

implementation

const
  CR = #13;  LF = #10;  CRLF = CR + LF;

constructor Tsession.create;
begin
 prompt:='>';
 terminated:=false;
end;

procedure Tsession.terminate;
begin
  terminated:=true;
  if assigned(FonTerminate) then
      FonTerminate(self);
end;

procedure Tsession.EcexuteCmd(s:String);
begin
if assigned(fonexec) then
  fonExec(self,s);
end;

procedure Tsession.Promptadd(S:string);
begin
  prompt:=prompt+s;
end;

procedure Tsession.WritePrompt;
begin
  if assigned(fonexecResult) then
       fonexecResult(prompt+path);
end;

procedure Tsession.writeResult(const txt:String);
begin
//  write(name+'_');
  if assigned(fonexecResult) then
       fonexecResult(txt+crlf);
end;

end.

