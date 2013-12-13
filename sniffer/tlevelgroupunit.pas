unit TLevelGroupUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, ExtCtrls,TLoggerUnit,TAppenderUnit, SysUtils;

{ TLogLevelGroup }
Type
TLevelGroup = Class(TCustomRadioGroup)
 protected
   Ftyp :integer;
   Flog: TLogger;
   FAppender :TAppender;

 private
   { private declarations }
     procedure CheckItemIndexChanged; override;
     procedure setlogLevel();
 public
   { public declarations }
  constructor Create(TheOwner: TComponent;log :Tlogger);
  constructor Create(TheOwner: TComponent;Appender :TAppender); overload;
  procedure setName(s:String);
  procedure setAppender(Appender :TAppender);
  procedure setlog(log :Tlogger);
end;

implementation

uses
  TLevelUnit;

procedure TLevelGroup.CheckItemIndexChanged;
begin
  inherited CheckItemIndexChanged;
   if (FAppender <> nil) then
       case itemindex of
     0 :FAppender.SetThreshold(DEBUG);
     1 :FAppender.SetThreshold(INFO);
     2 :FAppender.SetThreshold(WARN);
     3 :FAppender.SetThreshold(ERROR);
     4 :FAppender.SetThreshold(FATAL);
     end
 else
  case itemindex of
     0 :Flog.SetLevel(DEBUG);
     1 :Flog.SetLevel(INFO);
     2 :Flog.SetLevel(WARN);
     3 :Flog.SetLevel(ERROR);
     4 :Flog.SetLevel(FATAL);
  end;

end;

procedure TLevelGroup.setName(s: String);
begin
 Caption:=s;
end;

procedure TLevelGroup.setlog(log :Tlogger);
begin
  self.Flog := log;
 self.FAppender := nil;
 setLoglevel();
end;

procedure TLevelGroup.setAppender(Appender :TAppender);
begin
 self.Flog := nil;
 self.FAppender := Appender;
 setLoglevel();
end;

procedure TLevelGroup.setlogLevel();
var
  i :integer;
begin
 if (FAppender <> nil) then
   i:=FAppender.GetThreshold.IntValue()
 else
   i:=Flog.GetLevel.IntValue();
 case i of
   DEBUG_INT : itemindex:=0;
   INFO_INT : itemindex:=1;
   WARN_INT : itemindex:=2;
   ERROR_INT : itemindex:=3;
   FATAL_INT : itemindex:=4;
 else
     itemindex := -1;
  end;
end;

constructor TLevelGroup.Create(TheOwner: TComponent;log :Tlogger);
begin
  inherited create(TheOwner);
  Ftyp := 0;
  self.FAppender := nil;
  self.Flog := log;
  Caption:='Log_Level';
  columns:=2;
  items.AddStrings(['DEBUG','INFO','WARN','ERROR','FATAL']);
  itemindex:=-1;
  setLogLevel();
end;

constructor TLevelGroup.Create(TheOwner: TComponent;Appender :TAppender);
begin
  inherited create(TheOwner);
  Ftyp := 1;
  self.Flog := nil;
  self.FAppender := Appender;
  Caption:='Log_Level';
  columns:=2;
  items.AddStrings(['DEBUG','INFO','WARN','ERROR','FATAL']);
  itemindex:=-1;
  setLogLevel();
end;

end.

