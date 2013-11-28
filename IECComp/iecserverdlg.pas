unit IECServerDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, RTTICtrls, Forms, Controls,
  Graphics, Dialogs, StdCtrls, Spin, ExtCtrls, IEC104Sockets,
  simplelog;

type

  { TSrvDlg }

  TSrvDlg = class(TForm)
    SockParam: TButton;
    ClientList: TListBox;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    PanelLog: TPanel;
    FServer:TIEC104Server;
    Port: TSpinEdit;
    procedure SockParamClick(Sender: TObject);
    procedure ClientListSelectionChange(Sender: TObject; User: boolean);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    log: Tlog;
    lg: TLogLevelGroup;

  public
    { public declarations }
      constructor Create(TheOwner: TComponent; var iecserver:TIEC104Server);
      destructor destroy; override;
  end;

var
  SrvDlg: TSrvDlg;

implementation

uses IECSockDlg;
{$R *.lfm}

{ TSrvDlg }

procedure TSrvDlg.SockParamClick(Sender: TObject);
var
  sock:TIEC104Socket;
begin
  if clientlist.ItemIndex>-1 then
     begin
       sock:=FServer.Client[clientlist.ItemIndex];
       SockDlg:= TSockDlg.Create(self,sock);
       SockDlg.ShowModal;
       SockDlg.destroy;
     end;
end;

procedure TSrvDlg.ClientListSelectionChange(Sender: TObject; User: boolean);
begin

end;

procedure TSrvDlg.FormCreate(Sender: TObject);
var
 x:integer;
begin
  lg.Parent:=PanelLog;
  lg.Align:=alClient;

  port.Value:= Fserver.Port ;
  if Fserver.Active then
      port.Enabled:=false
  else
     port.Enabled:=true;

  clientlist.Clear;
  for x:=1 to FServer.Count-1 do
    Clientlist.Items.Add(Fserver.Socks[x].PeerAddress);
end;

constructor TSrvDlg.Create(TheOwner: TComponent; var iecserver: TIEC104Server);
begin
  FServer:=iecserver;
  inherited Create(TheOwner);
  log:=iecserver.Log;
  lg:=TLogLevelGroup.create(self,log);
end;

destructor TSrvDlg.destroy;
begin
  lg.Destroy;
  inherited destroy;
end;


end.

