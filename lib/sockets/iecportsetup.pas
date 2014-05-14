unit iecPortSetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComComboBox, IECSerial;

type

    // property types
 TComProperty = (cpNone, cpPort, cpBaudRate, cpDataBits, cpStopBits,
               cpParity, cpFlowControl);

 TComComboBox = class(TCustomComboBox)
   protected
     FIECcomPort: TIEC101Serial;
     fComProperty: TComProperty;
 private
//   FComSelect: TComSelect;
//   function GetAutoApply: Boolean;
//   function GetComPort: TCustomComPort;
   function GetComPort: TIEC101Serial;
   function GetComProperty: TComProperty;
//   function GetText: string;
   procedure SetAutoApply(const Value: Boolean);
   procedure SetComPort(const Value: TIEC101Serial);
   procedure SetComProperty(const Value: TComProperty);
   procedure SetText(const Value: string);
 protected
   procedure Notification(AComponent: TComponent; Operation: TOperation); override;
   procedure Change; override;
 public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure ApplySettings;
   procedure UpdateSettings;
 published
   property ComPort: TIEC101Serial read GetComPort write SetComPort;
   property ComProperty: TComProperty read GetComProperty write SetComProperty default cpNone;
//   property AutoApply: Boolean read GetAutoApply write SetAutoApply default False;
   property Text: string read GetText write SetText;
   property Style;
   property Color;
   property DragCursor;
   property DragMode;
   property DropDownCount;
   property Enabled;
   property Font;
   //property ImeMode;
   //property ImeName;
   property ItemHeight;
   property ItemIndex;
   property ParentColor;
   property ParentFont;
   property ParentShowHint;
   property PopupMenu;
   property ShowHint;
   property TabOrder;
   property TabStop;
   property Visible;
   property Anchors;
   //property BiDiMode;
   property CharCase;
   property Constraints;
   property DragKind;
   //property ParentBiDiMode;
   property OnChange;
   property OnClick;
   property OnDblClick;
   property OnDragDrop;
   property OnDragOver;
   property OnDrawItem;
   property OnDropDown;
   property OnEndDrag;
   property OnEnter;
   property OnExit;
   property OnKeyDown;
   property OnKeyPress;
   property OnKeyUp;
   property OnMeasureItem;
   property OnStartDrag;
   property OnEndDock;
   property OnStartDock;
   property OnContextPopup;
 end;

  { TForm3 }
  TIECPortSetup = class(TForm)
    ComboBox1: TComboBox;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FIECPortSetup: TIECPortSetup;

implementation

{$R *.lfm}

   // set ComPort property
procedure TComComboBox.SetComPort(const Value: TIEC101Serial);
begin
  if FIECcomPort <> Value then
  begin
    FIECcomPort := Value;
    if FIECcomPort <> nil then
    begin
//      FIECcomPort.FreeNotification(Self);
      // transfer settings from ComPort to this control
      UpdateSettings;
    end;
  end;
end;

function TComComboBox.GetComPort: TIEC101Serial;
begin
  Result := FIECcomPort;
end;

// change property for selecting
procedure TComComboBox.SetComProperty(const Value: TComProperty);
var
  Index: Integer;
begin
  fComProperty := Value;
  if Items.Count > 0 then
    if FIECcomPort <> nil then
    begin
      // transfer settings from ComPort to this control
 //     UpdateSettings(Index);
      ItemIndex := Index;
    end
    else
      ItemIndex := 0;
end;

function TComComboBox.GetComProperty: TComProperty;
begin
  Result := fComProperty;
end;

// update settings from TCustomComPort
//procedure TComComboBox.UpdateSettings(var ItemIndex: Integer);
procedure TComComboBox.UpdateSettings;
begin
{*  if FIECcomPort <> nil then
    with FComPort do
      case FComProperty of
        cpPort:
        begin
          ItemIndex := Items.IndexOf(Port);
          if ItemIndex > -1 then
            FPort := Items[ItemIndex];
        end;
        cpBaudRate:
        begin
          ItemIndex := Items.IndexOf(BaudRateToStr(BaudRate));
          if ItemIndex > -1 then
            FBaudRate := StrToBaudRate(Items[ItemIndex]);
        end;
        cpDataBits:
        begin
          ItemIndex := Items.IndexOf(DataBitsToStr(DataBits));
          if ItemIndex > -1 then
            FDataBits := StrToDataBits(Items[ItemIndex]);
        end;
        cpStopBits:
        begin
          ItemIndex := Items.IndexOf(StopBitsToStr(StopBits));
          if ItemIndex > -1 then
            FStopBits := StrToStopBits(Items[ItemIndex]);
        end;
        cpParity:
        begin
          ItemIndex := Items.IndexOf(ParityToStr(Parity.Bits));
          if ItemIndex > -1 then
            FParity := StrToParity(Items[ItemIndex]);
        end;
        cpFlowControl:
        begin
          ItemIndex := Items.IndexOf(FlowControlToStr(FlowControl.FlowControl));
          if ItemIndex > -1 then
            FFlowControl := StrToFlowControl(Items[ItemIndex]);
        end;
      end; *}
end;

end.

