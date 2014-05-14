unit uqudlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls,
  IECItems;

type

  { TQUdlg }

  TQUdlg = class(TForm)
    CBL: TCheckBox;
    CCIV: TCheckBox;
    CCA: TCheckBox;
    CCY: TCheckBox;
    CIV: TCheckBox;
    CNT: TCheckBox;
    COV: TCheckBox;
    CSB: TCheckBox;
    Notebook: TNotebook;
    Page1: TPage;
    Page2: TPage;
    Panel1: TPanel;
    procedure CChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);

  private
    { private declarations }
    look : boolean;
  public
    { public declarations }
  end;

var
  QUdlg: TQUdlg;
  item:TIECTCItem;

implementation

uses LCLType;

const mW = [TIECSType.M_ME_NA, TIECSType.M_ME_NB, TIECSType.M_ME_NC,
            TIECSType.M_ME_TB, TIECSType.M_ME_TD, TIECSType.M_ME_TF ];


procedure TQUdlg.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
 if KEY = VK_ESCAPE  then
   close;
end;

procedure TQUdlg.CChange(Sender: TObject);
 var b:byte;
 begin
  if not look then
    begin
      b:=0;
      if item.getType in mw then
         if COV.Checked then b:=b or $01;
      if (item.getType=M_IT_NA) or (item.getType=M_IT_TB) then
        begin
          if CCIV.Checked then b:=b or $80;
          if CCA.Checked then b:=b or $40;
          if CCY.Checked then b:=b or $20;
        end
      else
        begin
          if CIV.Checked then b:=b or $80;
          if CNT.Checked then b:=b or $40;
          if CSB.Checked then b:=b or $20;
          if CBL.Checked then b:=b or $10;
        end;
     item.qu[0]:=b;
     close;
    end;
end;

procedure TQUdlg.FormShow(Sender: TObject);
var b:byte;
begin
 // stops CCHnge execution
 look:=true;
CIV.Checked:=false;CNT.Checked:=false;CSB.Checked:=false;CBL.Checked:=false;
CCIV.Checked:=false;CCA.Checked:=false;CCY.Checked:=false;
Cov.Visible:=False;

b:=item.Qu[0];
 if item.getType in mw then
    begin
    if (b and $01) =$01 then
       COV.Checked:=true;
    Cov.Visible:=true;
    end;
 if (item.getType=M_IT_NA) or (item.getType=M_IT_TB) then
   begin
     if (b and $80) =$80 then CCIV.Checked:=true;
     if (b and $40) =$40 then CCA.Checked:=true;
     if (b and $20) =$20 then CCY.Checked:=true;
     Notebook.PageIndex:=1;
   end
 else
   begin
     if (b and $80) =$80 then CIV.Checked:=true;
     if (b and $40) =$40 then CNT.Checked:=true;
     if (b and $20) =$20 then CSB.Checked:=true;
     if (b and $10) =$10 then CBL.Checked:=true;
     Notebook.PageIndex:=0;
   end;
   look:=false;
end;

{$R *.lfm}

{ TQUdlg }



end.

