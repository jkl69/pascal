unit IECSockDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin, IEC104Sockets, simplelog;

type

  { TSockDlg }

  TSockDlg = class(TForm)
    GroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    LabelT1: TLabel;
    LabelT2: TLabel;
    LabelT3: TLabel;
    LabelT0: TLabel;
    Labelk: TLabel;
    Labelw: TLabel;
    PanelLog: TPanel;
    T1: TSpinEdit;
    T2: TSpinEdit;
    T3: TSpinEdit;
    T0: TSpinEdit;
    k: TSpinEdit;
    w: TSpinEdit;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
      { private declarations }
      Fsock: TIEC104Socket;
      log: Tlog;
      lg: TLogLevelGroup;
  public
    { public declarations }
      constructor Create(TheOwner: TComponent; var iecsocket:TIEC104Socket);
      destructor destroy; override;

      property Socket: TIEC104Socket read FSock write FSock;
  end;

var
  SockDlg: TSockDlg;

implementation

{$R *.lfm}

{ TSockDlg }

procedure TSockDlg.FormCreate(Sender: TObject);
begin
  lg.Parent:=PanelLog;
    lg.Align:=alClient;

  if (socket.SocketType=TIECServer) or (socket.SocketType=TIECMonitor) then
     begin
       if socket.SocketType=TIECServer then
          groupBox.Caption:= 'Server to '+socket.Name;
       if  socket.SocketType=TIECMonitor then
          groupBox.Caption:= 'Monitor '+socket.Name;
       t0.Visible:= false;
       label1.Visible:=false;
       labelt0.Visible:=false;
     end
  else
    begin

    end;

   t0.Value :=  Socket.TimerSet.T0/1000;
   t1.Value :=  FSock.TimerSet.T1/1000;
   t2.Value :=  FSock.TimerSet.T2/1000;
   t3.Value :=  FSock.TimerSet.T3/1000;
   k.Value :=  FSock.TimerSet.k;
   w.Value :=  FSock.TimerSet.w;
end;

procedure TSockDlg.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  tset: TIEC104TimerSet;
begin
  tset.T0:=t0.Value*1000;
  tset.T1:=t1.Value*1000;
  tset.T2:=t2.Value*1000;
  tset.T3:=t3.Value*1000;
  tset.k:= k.Value;
  tset.w:= w.Value;

  Socket.TimerSet := tset;
end;


constructor TSockDlg.Create(TheOwner: TComponent; var iecsocket: TIEC104Socket);
begin
  FSock:=iecsocket;
  inherited Create(TheOwner);
  log:=iecsocket.Log;
  lg:=TLogLevelGroup.create(self,log);
end;

destructor TSockDlg.destroy;
begin
  lg.Destroy;
  inherited destroy;
end;

end.

