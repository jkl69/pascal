unit Uvaldlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil,  Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, StdCtrls, Spin,
  IECItems;

type

  { TValDlg }

  TValDlg = class(TForm)
    F_MW: TFloatSpinEdit;
    LMin: TLabel;
    LMax: TLabel;
    PageZW: TPage;
    PageMWIEEE: TPage;
    PageDML: TPage;
    R_11: TRadioButton;
    R_10: TRadioButton;
    R_01: TRadioButton;
    R_00: TRadioButton;
    Notebook: TNotebook;
    PageMW: TPage;
    PageML: TPage;
    Panel1: TPanel;
    R_OFF: TRadioButton;
    R_ON: TRadioButton;
    S_zw: TSpinEdit;
    S_MW: TSpinEdit;
    T_MW: TTrackBar;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MLClick(Sender: TObject);
    procedure DMLClick(Sender: TObject);
    procedure MWClick(Sender: TObject);
    procedure S_zwEditingDone(Sender: TObject);
    procedure T_MWChange(Sender: TObject);
    procedure T_MWMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { private declarations }
    look: Boolean;
    procedure setML;
    procedure setDML;
    procedure setMW;
    procedure setZW;
    procedure setMWIEEE;
  public
    { public declarations }
  end;

var
  ValDlg: TValDlg;
  item:TIECTCItem;

implementation

{$R *.lfm}

uses LCLType, main;

{ TValDlg }


procedure TValDlg.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
 if KEY = VK_ESCAPE  then
   close;
end;

procedure TValDlg.setML();
begin
 Notebook.pageindex:=0;
 if item.Value[0]=0 then R_off.Checked:=true
 else R_on.Checked:=true;
end;

procedure TValDlg.setDML();
begin
 Notebook.pageindex:=2;
 case round(item.Value[0]) of
    0: R_00.Checked:=True;
    1: R_01.Checked:=True;
    2: R_10.Checked:=True;
    3: R_11.Checked:=True;
 end;
end;

procedure TValDlg.setMWIEEE();
begin
 Notebook.pageindex:=3;
 f_mw.MinValue:=item.Obj[0].min;
 f_mw.MaxValue:=item.Obj[0].max;
 f_mw.Value:=item.value[0];
end;

procedure TValDlg.setZW;
begin
 Notebook.pageindex:=4;
 s_zw.Value:=item.value[0];
end;

procedure TValDlg.setMW();
begin
 Notebook.pageindex:=1;
 t_mw.Min:=round(item.Obj[0].min);
 t_mw.Max:=round(item.Obj[0].max);
 t_mw.Position:=round(item.Value[0]);
 lMin.Caption:=floattoStr(item.Obj[0].min);
 lMax.Caption:=floattoStr(item.Obj[0].max);
 s_mw.MinValue:=item.Obj[0].min;
 s_mw.MaxValue:=item.Obj[0].max;
 s_mw.Value:=item.value[0];
end;

procedure TValDlg.FormShow(Sender: TObject);
begin
  look:=true;
  case item.getType of
     M_SP_NA,M_SP_TB : setML;
     M_DP_NA,M_DP_TB : setDML;
     M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD: setMW;
     M_ME_NC,M_ME_TF: setMWIeee;
     M_IT_NA,M_IT_TB : setZW;
  end;
  look:=false;
end;

procedure TValDlg.MLClick(Sender: TObject);
begin
 if not look then
   begin
   if R_on.Checked then item.Value[0]:=1
   else item.Value[0]:=0;
   close;
   end;
end;

procedure TValDlg.DMLClick(Sender: TObject);
begin
 if not look then
   begin
   if R_00.Checked then item.Value[0]:=0;
   if R_01.Checked then item.Value[0]:=1;
   if R_10.Checked then item.Value[0]:=2;
   if R_11.Checked then item.Value[0]:=3;
   close;
   end;
end;

procedure TValDlg.MWClick(Sender: TObject);
begin
 if not look then
   begin
   if sender.ClassType=TTrackbar then item.Value[0]:=t_mw.Position;
   if sender.ClassType=TSpinEdit then item.Value[0]:=s_mw.value;
   if sender.ClassType=TFloatSpinEdit then item.Value[0]:=F_mw.value;
   close;
   end;
end;

procedure TValDlg.S_zwEditingDone(Sender: TObject);
begin
 if not look then
   begin
   item.Value[0]:=s_zw.value;
   close;
   end;
end;


procedure TValDlg.T_MWChange(Sender: TObject);
begin
 if not look then
   s_mw.Value:=t_mw.Position;
end;


procedure TValDlg.T_MWMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  mwclick(sender);
end;


end.

