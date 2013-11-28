unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, Arrow, IEC104Sockets, simplelog, logappender,
  lNetComponents;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Logging: TMemo;
    text3: TMemo;
    text2: TMemo;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet6: TTabSheet;
    text1: TMemo;
    procedure Arrow1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  MainForm: TForm1;
  Server: TIEC104Server;
  lappender : Tlogappender ;
  Log: TLog;

implementation

{$R *.lfm}

uses Tracefile,timetest, Crt;

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  Server.Active:=true;
end;

procedure TForm1.Arrow1Click(Sender: TObject);
begin
  log.info('click');
end;

procedure TForm1.Button2Click(Sender: TObject);
Var
  sl2:Tstringlist;

begin
   text1.Lines := tracefile.openfile();
//   sl2:= text1.Lines;
  text2.Lines := getPlainhex(text1.Lines);
  text3.Lines := getfinal(text2.Lines);

end;

procedure TForm1.Button3Click(Sender: TObject);
var
  timestr,hexstr:string;
  count,x,timerint: integer;

begin
//  hexstr :='01 01 03 00 01 00 01 10 00 01' ;
    count:=  text3.Lines.Count;
    x:=0;
     repeat
        timerint:=0;
        if (x > 0) then
             begin
             timestr := text3.Lines[x];
             hexstr := text3.Lines[x+1];
             timerint := strtoint(timestr);
             inc(x,2);
            end
        else
            begin
             hexstr := text3.Lines[x];
             inc(x);
           end;
        if (timerint > 0) then
             begin
             log.info('wait time(msec) '+inttostr(timerint));
             delay(timerint);
             end;
        server.Client[0].sendHexStr(hexstr);
     until x >= count-1;

//   Log.warn('timediff '+inttostr(timediff('12:32:53,985','12:32:54,685')));
//   Log.warn('timediff '+inttostr(timediff('23:59:58,985','00:00:04,685')));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   Server:= TIEC104Server.Create(MainForm);
   Server.Log.LogAppender := lappender;
end;

Initialization
  Log:= TLog.create;
  lappender:= Tlogappender.create();
  Log.LogAppender:= lappender;

  log.LogLevel:=lDEBUG;

Finalization
//  lappender.Destroy;
  Log.Free;

end.

