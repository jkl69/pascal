unit uSimDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin,
  simobj;

type

  { TSimDlg }

  TSimDlg = class(TForm)
    F_value: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    S_Time: TSpinEdit;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure F_valueChange(Sender: TObject);
    procedure S_TimeChange(Sender: TObject);
  private
    look:boolean;
    { private declarations }
  public
    { public declarations }
  end;

var
  SimDlg: TSimDlg;
  sobj: TsimObj;

implementation

uses LCLType;

{$R *.lfm}

{ TSimDlg }

procedure TSimDlg.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
   if KEY = VK_ESCAPE  then
   close;
end;

procedure TSimDlg.FormShow(Sender: TObject);
begin
  look:=true;
  s_time.Value:=sobj.inctime;
  f_value.Value:=sobj.incval;
  look:=false;
end;

procedure TSimDlg.F_valueChange(Sender: TObject);
begin
   if not look then
     begin
     sobj.incval:=f_value.Value;
     close;
     end;
end;

procedure TSimDlg.S_TimeChange(Sender: TObject);
begin
  if not look then
    begin
    sobj.inctime:=s_time.value;
    sobj.updatenexttime;
    close;
    end;
end;


end.

