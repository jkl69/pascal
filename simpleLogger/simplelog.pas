unit simplelog;

{$mode Delphi}{$H+}
//{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, ExtCtrls;

Type
  Tloglevel=  (lALL,lDEBUG,lINFO,lWARN,lERROR,lFATAL);

  TLogLevelSet =set of Tloglevel;
  Tlog = class;

  Ilogappender = interface
     procedure dolog(sender:Tlog;s:string);
     procedure onLevelChange(sender:Tlog);
  end;


  { Tlog }

  Tlog=class(Tobject)
    protected
     FName: String;
     Fcode:integer;
     FLoglevel:TLoglevel;
//     FLogappender: TLogappender;
     FLogappender: Ilogappender;
     FlevelS: TLoglevelSet;
//     procedure loglevel(level:TLoglevel);
   private
     function DefStr(S: string): string;
    { private declarations }
      procedure setloglevel(level:TLoglevel);
      function GetLogLevel:TLoglevel;
   public
      constructor Create;
      procedure debug(s:string);
      procedure info(s:string);
      procedure warn(s:string);
      procedure error(s:string);
      procedure fatal(s:string);
      function LevelIndex:integer;
      function GetLogLevelStr:string;
      property Name:String read FName write FName;
      property code:integer read Fcode write Fcode;
      property LogLevel:TLogLevel read getLoglevel write setLogLevel;//Floglevel;
      property Levels:TLoglevelSet read FlevelS write FlevelS;
//      property LogAppender:TLogAppender read FLogappender write FLogappender;
      property LogAppender:ILogAppender read FLogappender write FLogappender;
    { public declarations }
  end;

 { TLogLevelGroup }

 TLogLevelGroup = Class(TCustomRadioGroup)
  protected
   FLog: TLog;
  private
    { private declarations }
      procedure CheckItemIndexChanged; override;
  public
    { public declarations }
   procedure setlog(log: Tlog);
   constructor Create(TheOwner: TComponent);
   constructor Create(TheOwner: TComponent;log:Tlog);   overload;
//   property log:Tlog read Flog write setlog;
 end;

function GetLevelItems(levels:TLogLevelSet):TStrings;

//var
//  LogAppender:TLogappender;
// procedure SetOnLogEvent(Proc:TGetStrProc);

const
      DefaultLogleveSet = [lDEBUG..lFATAL];

implementation

uses typinfo;

function GetLevelItems(levels:TLogLevelSet):TStrings;
var
  l: Tloglevel;
  s:string;
begin
  result:= TStringlist.Create;
  for l in levels do
      begin
        s:=GetEnumName(TypeInfo(Tloglevel), ord(l));
        s:=RightStr(s,length(s)-1);
//        result.AddObject(s,Tobject(l));
        result.AddObject(s,Tobject(l));
      end;
//      result.Add(GetEnumName(TypeInfo(Tloglevel), ord(l)));
 end;

constructor Tlog.Create;
begin
  inherited Create;
  FLoglevel := lINFO;
  FlevelS := DefaultLogleveSet;
//  FlevelS := [lDEBUG..lFATAL];
  Flogappender := LogAppender;
  Fcode:=-1;
end;

procedure Tlog.Setloglevel(level:TLoglevel);
begin
   FLoglevel:=level;
   if assigned(FLogAppender) then
      FLogAppender.onLevelChange(self);
end;

function Tlog.GetLogLevelStr:string;
var
  s:String;
begin
  s := GetEnumName(TypeInfo(TLoglevel),
                        Ord(Getloglevel));
  GetLogLevelStr:=RightStr(s,length(s)-1);
end;

Function Tlog.Getloglevel:TLoglevel;
begin
   result := FLoglevel;
end;

function Tlog.DefStr(S:string):string;
begin
// result := name+' '+s;
 result := ' '+s;
end;

procedure Tlog.debug(s:string);
begin
  if FLoglevel<=lDEBUG then
    if assigned(FLogAppender) then
      FLogAppender.dolog(self,name+':DEBUG '+s);
//    FLogAppender.dolog(name+':DEBUG '+defstr(s));
end;

procedure Tlog.info(s:string);
begin
  if FLoglevel<=lINFO then
    if assigned(FLogAppender) then
        FLogAppender.dolog(self,name+':INFO '+s);
end;
procedure Tlog.warn(s:string);
begin
  if FLoglevel<=lWARN then
    if assigned(FLogAppender) then
      FLogAppender.dolog(self,name+':WARN '+s);
end;
procedure Tlog.error(s:string);
begin
 if FLoglevel<=lERROR then
   if assigned(FLogAppender) then
     FLogAppender.dolog(self,name+':ERROR '+s);
end;
procedure Tlog.fatal(s:string);
begin
 if FLoglevel<=lFATAL then
   if assigned(FLogAppender) then
     FLogAppender.dolog(self,name+':FATAL '+s);
end;

function Tlog.LevelIndex: integer;
var
  l: Tloglevel;
  x: Integer;
begin
 result:=-1;
 x:=0;
 for l in FlevelS do
     begin
       if l=Floglevel then
         result:= x;
       inc(x)
     end;
end;

{ TLogLevelGroup }

procedure TLogLevelGroup.CheckItemIndexChanged;
var
  lv: Tloglevel;
  idx: Integer;
begin
  inherited CheckItemIndexChanged;
  lv:= TlogLevel(items.Objects[itemindex]);
  if Flog.LogLevel <> lv then
      Flog.LogLevel := lv;
end;

procedure  TLogLevelGroup.setlog(log: Tlog);
begin
 items.Clear;
 Flog:= log;
 Caption:=flog.Name+'_Log_Level';
 items.AddStrings(GetLevelItems(Flog.FlevelS));
 itemindex:=flog.LevelIndex;
end;

constructor TLogLevelGroup.Create(TheOwner: TComponent);
begin
  inherited create(TheOwner);
  Caption:='Log_Level';
  columns:=2;
  items.AddStrings(GetLevelItems(DefaultLogleveSet));
  itemindex:=-1;
end;

constructor TLogLevelGroup.Create(TheOwner: TComponent;log: Tlog); overload;
begin
  Flog:= log;
  inherited create(TheOwner);
//  Caption:='Log_Level';
  Caption:=flog.Name+'_Log_Level';
  columns:=2;
  items.AddStrings(GetLevelItems(Flog.FlevelS));
  itemindex:=flog.LevelIndex;
end;


//initialization
//  LogAppender := TLogAppender.Create;

//finalization
//  LogAppender.Free;

end.

