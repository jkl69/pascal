unit IECGWEvent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  session, IECItems2,
  TLoggerUnit,TLevelUnit;

type
  TEventArray= array of String;

  TGWTimer = class(TObject)
     intervall :integer;
     nexttimer : double;
   public
     procedure reload;
  end;

  TIECGWEvent = class(TObject)
  protected
    FLog: TLogger;
    fsession :Tsession;
    FTimerlist:TStringlist;
    FTimerEvents:TStringlist;
    FonItemEvent:TStringlist;
    FonConnectevent:TStringlist;
    FonDisConnectevent:TStringlist;
  private
    procedure IRQ();
    procedure execute(s:string);
    procedure Timerevent(s:String);
  public
    terminated : Boolean;
    constructor Create;
    destructor destroy; override;
    procedure ItemEvent(item:TIECTCItem);
    procedure log(ALevel : TLevel; const AMsg : String);
    Function addTimer(s:string;intervall:integer):boolean;
    Function addTimer(s:string):boolean;
    procedure addTimerevent(timername,event:String);
    Function delTimerevent(timername:String):Boolean;
    Function delTimer(s:string):boolean;

    property Logger:TLogger read FLog write FLog;
    property TimerList:TStringlist read FTimerlist;
    property TimerEvents:TStringlist read FTimerEvents;
  end;

implementation

uses CLI;

var
   loop:integer;

function timer(p: Pointer): ptrint;
var
  ev: TIECGWEvent;
begin
  ev := TIECGWEvent(p);
  while (not ev.terminated) do
  begin
    ev.irq();
    sleep(100);
    inc(loop);
  end;
  ev.log(debug,'Timer Terminated');
end;

{ TGWTimer }

procedure TGWTimer.reload;
begin
  nexttimer := now + intervall * 0.0000013;
end;

{ TIECGWEvent }

Function TIECGWEvent.delTimer(s:string):boolean;
var
  i:integer; t: TGWTimer;
begin
 result:=false;
 i:=FTimerlist.IndexOf(s);
 if i = -1 then
     begin
     exit;
     end;
  t:= TGWTimer(FTimerlist.Objects[i]);
  t.Destroy;
  Ftimerlist.Delete(i);
  log(debug,'delTimer');
  result:=true;
end;

{*
 default intervall = 50 = 5sec(50* 0.1sec)
*}
Function TIECGWEvent.addTimer(s:string):boolean;
begin
  result:=addTimer(s,50);
end;

Function TIECGWEvent.addTimer(s:string;intervall:integer):boolean;
var
 t: TGWTimer;
begin
  result:=False;
  if FTimerlist.IndexOf(s)<> -1 then
    begin
    exit;
    end;
  t:= TGWTimer.Create;
  t.intervall:=intervall;
  t.reload;
  FTimerlist.AddObject(s,t);
  result:=true;
end;

procedure TIECGWEvent.execute(s:string);
begin
 if fsession<>nil then
    begin
    fsession.EcexuteCmd(s);
    fsession.onexec:=@CLI.ExecCli;
    fsession.path:='';
    end;
end;

procedure TIECGWEvent.addTimerevent(timername,event:String);
begin
 FTimerEvents.Add(timername+'='+event);
end;

Function TIECGWEvent.delTimerevent(timername:String):boolean;
var i:integer;
begin
result:=False;
i:=0;
while i< FTimerEvents.Count do
    begin
    if FTimerEvents.Names[i]=timername then
       begin
       FTimerEvents.Delete(i);
       result:=true;
       end
    else
      inc(i);
    end;
end;

procedure TIECGWEvent.Timerevent(s:String);
var i:integer;
begin
 log(Info,'TimerEvent: '+s);
 for i:=0 to FTimerEvents.Count-1 do
      begin
      if FTimerEvents.Names[i]=s then
         execute(FTimerEvents.ValueFromIndex[i]);
      end;
end;

procedure TIECGWEvent.ItemEvent(item:TIECTCItem);
begin
  log(info,'ItemEvent: '+item.Name);
end;

procedure TIECGWEvent.IRQ();
var
  i:integer;  date: Tdatetime;  t: TGWTimer;
begin
 date:=now;
 if (loop mod 50 = 0) then log(debug,'IRQ');
  for i:=0 to FTimerlist.Count-1 do
    begin
       t := TGWTimer(FTimerlist.Objects[i]);
       if (t.nexttimer <= date ) then
          begin
          timerevent(FTimerlist[i]);
          t.reload;
          end;
    end;
end;

Function getKey(S:String):String;
begin
  result:=copy(s,1,pos('=',s)-1);
end;

function getValue(S:String):String;
begin
  result:=copy(s,pos('=',s)+1,length(s));
end;

constructor TIECGWEvent.create;
begin
  inherited create;
  FTimerlist := TStringlist.Create;
  FtimerEvents := TStringlist.Create;
  FonConnectevent := TStringlist.Create;
  FonDisConnectevent := TStringlist.Create;
  FonItemEvent:=TStringlist.create;
  terminated := false;

  fsession:= Tsession.create;
  fsession.onexec:=@CLI.ExecCli;

  //  fth:=BeginThread(@run,Pointer(self));
  BeginThread(@timer,Pointer(self));
end;

destructor TIECGWEvent.destroy;
begin
  terminated := true;
  fsession.Destroy;
  freeandnil(FonItemEvent);
  freeandnil(FTimerlist);
  freeandnil(FtimerEvents);
  freeandnil(FonConnectevent);
  freeandnil(FonDisConnectevent);
  inherited destroy;
end;

procedure TIECGWEvent.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flog)) then
     begin
     s:='EVENT_'+AMsg;
     Flog.log(ALevel,s);
     end;
end;


end.

