unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Spin, ComCtrls, Grids, ValEdit, IECSerial, Portsetup,
  IECItems ,simObj;

type

  { TSlave }

  TSlave = class(TForm)
    BStart: TButton;
    BStop: TButton;
    Badd: TButton;
    BPort: TButton;
    Bload: TButton;
    bClean: TButton;
    Bsave: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Lversion: TLabel;
    LTXData: TLabel;
    LRXFrames: TLabel;
    LRXData: TLabel;
    LTXFrames: TLabel;
    OpenDialog: TOpenDialog;
    Panel3: TPanel;
    Bufferusage: TProgressBar;
    RadioGroup1: TRadioGroup;
    SaveDialog: TSaveDialog;
    SimCheck: TCheckBox;
    IECTypeCombo: TComboBox;
    events: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Linkadr: TSpinEdit;
    Splitter1: TSplitter;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StatusBar: TStatusBar;
    ItemGrid: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    Timer1: TTimer;
    trc: TMemo;
 //   ComPort: TComPort;
    procedure BPortClick(Sender: TObject);
    procedure BStartClick(Sender: TObject);
    procedure BStopClick(Sender: TObject);
    procedure BaddClick(Sender: TObject);
    procedure BloadClick(Sender: TObject);
    procedure bCleanClick(Sender: TObject);
    procedure BsaveClick(Sender: TObject);
    procedure ItemGridButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure ItemGridClick(Sender: TObject);
    procedure ItemGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ItemGridSelection(Sender: TObject; aCol, aRow: Integer);
    procedure ItemGridValidateEntry(sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
    procedure LinkadrEditingDone(Sender: TObject);
    procedure SimCheckChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    Function save:Tstringlist;
    procedure load(l:Tstringlist);
    procedure loadcsv(l:Tstringlist);
    Function itemAdd(s:String;tk:TIECSType;asdu:integer;adr:integer):TIECTCItem;
    procedure simAdd(item:TIECTCItem;activ:boolean;tinc:integer;valinc:Double);
    procedure receive(item:TIECTCItem);
    procedure updateC(item:TIECTCItem);
    procedure update(Sender: TObject);
    procedure changeItem(item:TIECTCItem; sobj:TsimObj);
//    procedure RX(Sender: TObject; buffer: pointer; Count: Integer);
    procedure RX(Sender: TObject; Buffer: array of byte; Count: Integer);
//    procedure DataRX(Sender: TObject; buffer: pointer; Count: Integer);
    procedure DataRX(Sender: TObject; Buffer: array of byte; Count: Integer);
    procedure TX(Sender: TObject; Buffer: array of byte; Count: Integer);
    procedure DataTX(Sender: TObject; Buffer: array of byte; Count: Integer);
    procedure Event(const S: string);
    procedure log(const S: string);
    procedure start(sender:Tobject);
    procedure stop(sender:Tobject);
    procedure fchange(sender:Tobject;fn:byte);
  public
    { public declarations }
  end;

procedure trace(str:string);

var
  Slave: TSlave;

implementation

{$R *.lfm}

uses  TLoggerUnit, TLevelUnit, logappender,
    uvaldlg, uqudlg,  usimdlg;

var
    TXs,RXs:String;
    ser : TIEC101Serial;
    iob:cardinal;
    row,col:integer;

{$I version.inc}

procedure TSlave.BStartClick(Sender: TObject);
var conf:TPortconfig;
begin
  conf:=setup.getconfig;
  ser.config(conf.baudrate,conf.dbits,conf.parity,conf.Sbits, False, False);
  ser.Port:=conf.port;
  ser.linkadr:=conf.linkadr;
  ser.start;
end;

procedure TSlave.BPortClick(Sender: TObject);
var conf:TPortconfig;
begin
  setup.fLinkNo.Value:=linkadr.Value;
  setup.ShowModal;
  conf:=setup.getconfig;
  portsetup.savesettings(ExtractFilePath(ParamStr(0))+'iec.ini',conf);
  linkadr.Value:=conf.linkadr;
  bport.Caption:=setup.getconfigstr;
end;

procedure TSlave.BStopClick(Sender: TObject);
begin
 ser.stop;
end;

procedure TSlave.updateC(item: TIECTCItem);
begin

end;

procedure TSlave.update(Sender: TObject);
var  item:TIECTCItem; o:TIECTCObj; i:integer;
begin
  o:= TIECTCObj(sender);
  for i:=1 to itemGrid.RowCount-1 do
      begin
        item:= TIECTCItem(itemgrid.Objects[0,i]);
        if item=o.asdu then
           begin
          itemGrid.Cells[5,i]:=floattoStr(item.Value[0]);
          itemGrid.Cells[6,i]:=inttoStr(item.QU[0]);
          itemGrid.Cells[7,i]:=item.timeStr[0];
          ser.senddata(item.getStream);
          Event('SEND '+item.ToString);
          exit;
          end;
      end;
end;

function TSlave.itemAdd(s:String;tk:TIECSType;asdu:integer;adr:integer):TIECTCItem;
var  item:TIECTCItem;
begin
item:=TIECTCItem.create(tk,asdu,adr);
//item.name:='Item'+inttostr(iob-1);
item.name:=s;

if not (item.getType in c_type) then
  item.Obj[0].onChange:=@update;

itemGrid.RowCount:=itemGrid.RowCount+1;
itemGrid.Cells[0,iob]:=IECType[item.getType].name;
itemGrid.Objects[0,iob]:=item;
itemGrid.Cells[1,iob]:=item.Name;
itemGrid.Cells[2,iob]:=inttoStr(item.ASDU);
itemGrid.Cells[3,iob]:=inttoStr(item.COT);
itemGrid.Cells[4,iob]:=inttoStr(item.Adr[0]);
itemGrid.Cells[5,iob]:=floattoStr(item.Value[0]);
itemGrid.Cells[6,iob]:=inttoStr(item.QU[0]);
itemGrid.Cells[7,iob]:=item.timeStr[0];

itemGrid.Cells[8,iob] := 'Send';
itemGrid.Cells[9,iob] := '0';
itemGrid.Cells[10,iob] := 'Props.';
itemGrid.Objects[10,iob] := TsimObj.Create;;
//itemgrid.Col:=0;
//  itemgrid.SetFocus;
inc(iob);
result:=item;
end;

procedure TSlave.simAdd(item:TIECTCItem;activ:boolean;tinc:integer;valinc:Double);
var sobj:Tsimobj;
begin
sobj:= TsimObj.Create;
sobj.inctime:=tinc;
sobj.incval:=valinc;

if not (item.getType in c_type) then
  itemGrid.Cells[8,iob-1] := 'Send'
else itemGrid.Cells[8,iob-1] := '';

if activ then
  itemGrid.Cells[9,iob-1] := '1'
else
  itemGrid.Cells[9,iob-1] := '0';

if not (item.getType in c_type) then
  begin
  itemGrid.Cells[10,iob-1] := 'Props.';
  itemGrid.Objects[10,iob-1] := sobj;
  end
else  itemGrid.Cells[10,iob-1] := '';

sobj.updatenexttime;

end;

procedure TSlave.BaddClick(Sender: TObject);
var  item:TIECTCItem;
begin
item:=itemAdd('Item'+inttostr(iob-1),StringToIECType(IECTYPECombo.Items[IECTypeCombo.ItemIndex]),ser.LinkAdr,iob);
simAdd(item,false,2,1);
end;

Function TSlave.save:Tstringlist;
var
 item:TIECTCItem;
 sobj:Tsimobj;
 i :integer;
 txt,b,val:String;
begin
result:= TstringList.Create;
result.Add('FILE.VERSION=2');
result.Add('ITEMS.COUNT='+inttoStr(itemgrid.RowCount-1));
result.Add('ITEM.PROPERTIES=NAME;TYPE;ASDU;IOB;SIMULATE;SIM.PROPERTY;SIM.VAL_INC');
for i:= 1 to itemgrid.RowCount-1 do
  begin
  item :=TIECTCItem(itemgrid.Objects[0,i]);
  sobj := Tsimobj(itemgrid.Objects[10,i]);
  txt:=format('ITEM%d=%s;%d;%d;%d',[i,item.Name,IECtype[item.getType].TK,item.ASDU,item.Adr[0]]);
  b:='false';
  if itemgrid.Cells[9,i] ='1' then b:='true';
  val := stringreplace(floattostr(sobj.incval),DecimalSeparator,'.',[rfReplaceAll]);
  txt:=txt+format(';%s;%d;%s',[b,sobj.inctime,val]);
  result.Add(txt);
//  log(txt);
  end;
for i:= 0 to result.Count-1 do
  log(result[i]);
end;

procedure TSlave.load(l:Tstringlist);
var
 item:TIECTCItem;
 prop,it:TStringlist;
 ic,i :integer;
 nindex,tindex,aindex,iobindex :integer;
 saindex,stiindex,sviindex :integer;
 val:String;
begin
if l.values['FILE.VERSION']='2' then
  begin
  prop := TStringlist.Create;
  it := TStringlist.Create;

  ic:=strtoInt(l.Values['ITEMS.COUNT']);
  prop.Delimiter:=';';
  it.Delimiter:=';';
  prop.DelimitedText:= l.Values['ITEM.PROPERTIES'];
//for i:=0 to prop.Count-1 do  log('prop'+inttostr(i)+' :'+prop[i]);
//  it.DelimitedText:=l.Values['ITEM'+inttostr(1)];
  log('Seperator: '+DecimalSeparator);
 nindex := prop.IndexOf('NAME');
 tindex := prop.IndexOf('TYPE');
 aindex := prop.IndexOf('ASDU');
 iobindex := prop.IndexOf('IOB');
 saindex := prop.IndexOf('SIMULATE');
 stiindex := prop.IndexOf('SIM.PROPERTY');
 sviindex := prop.IndexOf('SIM.VAL_INC');
  for i:=1 to ic do
      begin
      it.DelimitedText:=l.Values['ITEM'+inttostr(i)];
      log('asdu'+inttostr(i)+' :'+it[aindex]);
      item:=itemAdd(it[nindex],getSType(strtoint(it[tindex])),strtoint(it[aindex]),strtoint(it[iobindex]));
      val:=stringreplace(it[sviindex],'.',DecimalSeparator,[rfReplaceAll]);
      simAdd(item,strtobool(it[saindex]),strtoint(it[stiindex]),strtoFloat(val));
      end;
  prop.Destroy;
  it.destroy;
  end
else
  log('ERROR File Version');
end;

procedure TSlave.loadcsv(l:Tstringlist);
var
 item:TIECTCItem;
 prop,it:TStringlist;
 i,x :integer;
 nindex,tindex,aindex,iobindex :integer;
 t:TIECSType;
 fn,val:String;
begin
  prop := TStringlist.Create;
  it := TStringlist.Create;
  prop.Delimiter:=',';
  it.Delimiter:=',';
  log('Seperator: '+DecimalSeparator);
  fn:= l[0];
  prop.DelimitedText:= stringreplace(l[1],' ','',[rfReplaceAll]);
  log('fn: '+fn);
  for i:=0 to prop.Count-1 do
    begin
//    log('prop'+inttostr(i)+' '+prop[i]);
    if pos('(name)',prop[i])<>0 then nindex := i;
//    if pos('.QuellTyp',prop[i])<>0 then tindex := i;
    if pos('(ASDUA)',prop[i])<>0 then aindex := i;
    if pos('(IPA)',prop[i])<>0 then iobindex := i;
    end;
  log(format('tindex:%d  nindex:%d aindex:%d iobindex:%d',[tindex,nindex,aindex,iobindex]));
  for i:=2 to l.Count-1  do
    begin
    it.DelimitedText:=stringreplace(l[i],' ','',[rfReplaceAll]);
    for x:=0 to it.Count-1 do
        begin
        if pos('NORM',it[x])<>0 then t:=TIECSTYPE.C_SE_NA;
        if pos('SCAL',it[x])<>0 then t:=TIECSTYPE.C_SE_NB;
        if pos('EBF',it[x])<>0 then t:=TIECSTYPE.C_SC_NA;
        if pos('DBF',it[x])<>0 then t:=TIECSTYPE.C_DC_NA;
        if pos('EML',it[x])<>0 then t:=TIECSTYPE.M_SP_TB;
        if pos('DML',it[x])<>0 then t:=TIECSTYPE.M_DP_TB;
        if pos('MWNORM',it[x])<>0 then t:=TIECSTYPE.M_ME_TB;
        if pos('MWSCAL',it[x])<>0 then t:=TIECSTYPE.M_ME_TD;
        if pos('ZW',it[x])<>0 then t:=TIECSTYPE.M_IT_TB;
        end;
    log(format('%d type%s name:%s asdu%s iob%s',[i,IECType[t].sname,it[nindex],it[aindex],it[iobindex]]));
    item:=itemAdd(it[nindex],t,strtoint(it[aindex]),strtoint(it[iobindex]));
    simAdd(item,false,4,1);
    end;
  prop.Destroy;
  it.destroy;
end;

procedure TSlave.BloadClick(Sender: TObject);
var
 File1: TextFile; s:String;
 Strl:TStringlist;

begin
 Strl := TStringlist.Create;

// prop.NameValueSeparator:=';';
  if opendialog.Execute then
     begin
     strl.LoadFromFile(opendialog.FileName);
       if opendialog.FilterIndex=1 then
          load(strl) ;
       if opendialog.FilterIndex=2 then
          begin
          strl.Insert(0,opendialog.FileName);
          loadcsv(strl) ;
          end;
  end;
  Strl.destroy;
end;

procedure TSlave.bCleanClick(Sender: TObject);
var i:integer;
  item:TIECTCItem; sim:TsimObj;
begin
//  log('ClicK Row:'+inttostr(aRow));
for i:=1 to itemgrid.RowCount-1 do
   begin
   item:= TIECTCItem(itemgrid.Objects[0,i]);
   sim :=TsimObj(itemgrid.Objects[10,i]);
   item.Destroy;
   sim.Destroy;
   end;
itemgrid.Clean;
itemgrid.RowCount:=1;
//row:=0;col:=0;
iob:=1;
end;

procedure TSlave.BsaveClick(Sender: TObject);
var
 l:Tstringlist;
begin
 if savedialog.Execute then
   begin
   l:=save;
   l.SaveToFile(savedialog.FileName);
   end;
end;

procedure TSlave.ItemGridButtonClick(Sender: TObject; aCol, aRow: Integer);
var  item:TIECTCItem; sim:TsimObj;
begin
//  log('ClicK Row:'+inttostr(aRow));
item:= TIECTCItem(itemgrid.Objects[0,aRow]);
if not (item.getType in c_type) then
  begin
  case aCol of
    8: begin ser.senddata(item.getStream);
       Event('SEND '+item.ToString);
       end;
   10: begin sim :=TsimObj(itemgrid.Objects[10,aRow]);
       UsimDlg.sobj:=sim;
       simdlg.showmodal;
       end;
   end;
  end;
end;

procedure TSlave.ItemGridClick(Sender: TObject);
begin
 item:= TIECTCItem(itemgrid.Objects[0,Row]);
 if item<>nil then
   if not (item.getType in c_type) then
   begin
    UvalDlg.item:=item;
    UQudlg.item:=item;
    case Col of
       5: valdlg.showmodal;
       6: qudlg.showmodal;
    end;
  end;
end;

procedure TSlave.ItemGridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
log('mousex:'+inttostr(x));
 valdlg.Left:=x-100;
 qudlg.Left:=x-100;
end;


procedure TSlave.ItemGridSelection(Sender: TObject; aCol, aRow: Integer);
begin
  row:=aRow;
  col:=acol;
end;

procedure TSlave.ItemGridValidateEntry(sender: TObject; aCol, aRow: Integer;
  const OldValue: string; var NewValue: String);
var item:TIECTCItem; i,code:integer;
begin
//  log('validate');
  item:= TIECTCItem(itemgrid.Objects[0,aRow]);
  case aCol of
    1: item.Name:=newValue;
    2:  begin  Val (newValue,I,Code);
             if code<>0 then
                NewValue:=oldValue
             else
               item.ASDU:=i;
        end;
    3:  begin  Val (newValue,I,Code);
             if code<>0 then
                NewValue:=oldValue
             else
               item.COT:=i;
        end;

    4: begin  Val (newValue,I,Code);
             if code<>0 then
                NewValue:=oldValue
             else
               item.Obj[0].setAdr(i);
       end;
    else
      newValue:=oldValue;
  end;
end;

procedure TSlave.LinkadrEditingDone(Sender: TObject);
begin
  ser.LinkAdr:=linkadr.Value;
end;

procedure TSlave.SimCheckChange(Sender: TObject);
begin
  if simcheck.Checked then timer1.Enabled:=true
  else timer1.Enabled:=false;
end;

procedure TSlave.RX(Sender: TObject; Buffer: array of byte; Count: Integer);
var data:array of byte;
begin
  Statusbar.panels[1].text:='RX '+RXs;
  if rxs='-' then rxs:='+' else rxs:='-';
  lRXFrames.Caption:=inttostr(ser.rxcount);
end;

procedure TSlave.DataRX(Sender: TObject; Buffer: array of byte; Count: Integer);
var  item:TIECTCItem;
begin
  item := TIECTCITem.create(buffer,count);
  events.Lines.Add('REC.  '+item.ToString);
  if item.getType<>TIECSType.IEC_NULL_TYPE then
     receive(item);
//  events.Lines.Add('RX:['+inttostr(count)+'] '+ hextoStr(buffer,count));
  lRXData.Caption:=inttostr(ser.rxDatacount);
end;

procedure TSlave.receive(item:TIECTCItem);
var i:integer; it:TIECTCItem;
begin
  for i:=1 to itemgrid.RowCount-1 do
      begin
      it:=TIECTCItem (itemgrid.Objects[0,i]);
      if (it.Equal(item)) then
        begin
        log('FOUND');
        it.qu[0]:=item.qu[0];
        it.Value[0]:=item.Value[0];
        itemGrid.Cells[5,i]:=floattoStr(it.Value[0]);
        itemGrid.Cells[6,i]:=inttoStr(it.QU[0]);
        itemGrid.Cells[7,i]:=it.timeStr[0];
        it.COT:=$07;
        ser.senddata(it.getStream);
        Event('SEND '+it.ToString);
        exit;
        end;
      end;
  log('NOT FOUND');
  item.COT:=$47;
  ser.senddata(item.getStream);
  Event('SEND '+item.ToString);
end;

procedure TSlave.DataTX(Sender: TObject; Buffer: array of byte; Count: Integer);
//procedure TSlave.RX(const S: string);
begin
  log('TX:['+inttostr(count)+'] '+ hextoStr(buffer,count));
  Bufferusage.Position:=round(ser.bufferusage*100);
  lTXData.Caption:=inttostr(ser.txDatacount);
end;

procedure TSlave.TX(Sender: TObject; Buffer: array of byte; Count: Integer);
//procedure TSlave.RX(const S: string);
begin
  Statusbar.panels[2].text:='TX '+TXs;
  Bufferusage.Position:=round(ser.bufferusage*100);
  if txs='-' then txs:='+' else txs:='-';
  trc.Lines.Add('sTX:['+inttostr(count)+'] '+ hextoStr(buffer,count))    ;
  IF trc.lines.Count>100 then trc.Lines.Clear;
  lTXFrames.Caption:=inttostr(ser.txcount);
end;

procedure TSlave.log(const S: string);
begin
  trc.Lines.Add(s)    ;
  IF trc.lines.Count>1000 then trc.Lines.Clear;
end;

procedure TSlave.Event(const S: string);
begin
  Events.Lines.Add(s);
  IF Events.lines.Count>1000 then Events.Lines.Clear;
end;

procedure TSlave.start(sender:Tobject);
begin
event('Port starts listen');
  setup.Panel1.Enabled:=false;
  setup.Panel2.Visible:=true;
  bStart.Enabled:=False;
  bStop.Enabled:=true;
end;

procedure TSlave.stop(sender:Tobject);
begin
event('Port closed');
setup.Panel1.Enabled:=true;
setup.Panel2.Visible:=false;
bStart.Enabled:=true;
 bStop.Enabled:=false;
end;

procedure TSlave.fchange(sender:Tobject;fn:byte);
begin
  Statusbar.panels[2].text:='Received Func: '+inttoStr(fn);
end;

procedure TSlave.FormCreate(Sender: TObject);
var i:integer; sType:TIECSType;
begin
  ser:=TIEC101Serial.Create;
  ser.Logger:=Tlogger.GetInstance('SERIAL');
  ser.Logger.SetLevel(info);
//  ser.Logger.SetLevel(debug);
  ser.Logger.AddAppender(Tlogappender.Create);
  ser.onRx:=@rx;
  ser.onDataRx:=@Datarx;
  ser.onDataTx:=@DataTx;
  ser.onTx:=@Tx;
  ser.onLog:=@log;
  ser.onStart:=@start;;
  ser.onStop:=@stop;
  ser.onFunctionChange:=@fchange;
//  ser.onmessagebuffer:=@messageBuffer;
  txs:='-';  rxs:='+';

  itemgrid.Cells[0,0]:='Type';
  iob:=1;
  for sType:=low(TIECSType) to high(TIECSType) do
      if sType<>TIECSType.IEC_NULL_TYPE then
         IECTypeCombo.items.add(IECType[sType].name);
  IECTypeCombo.ItemIndex:=0;
  caption:='IEC101 Slave  '+versionShortStr;
  lversion.Caption:=versionStr;
  portsetup.conf:= portsetup.loadsettings(ExtractFilePath(ParamStr(0))+'iec.ini');
  ser.LinkAdr:=conf.linkadr;
end;

procedure TSlave.changeItem(item:TIECTCItem; sobj:TsimObj);
begin
  if item<>nil then
     begin
     if item.Value[0]+sobj.incval > item.Obj[0].max then
        sobj.incval:=sobj.incval*-1;
     if item.Value[0]+sobj.incval < item.Obj[0].min then
        sobj.incval:=sobj.incval*-1;

     item.Value[0]:=item.Value[0]+sobj.incval;
     sobj.updatenexttime;
     end;
end;

procedure TSlave.Timer1Timer(Sender: TObject);
var  item:TIECTCItem; sobj:TsimObj;
    i:integer;
begin
  for i:=1 to itemGrid.RowCount-1 do
      if   itemGrid.Cells[9,i] = '1' then
         begin
           sobj:= Tsimobj (itemgrid.Objects[10,i]);
           item:= TIECTCItem(itemgrid.Objects[0,i]);
           if sobj.nexttime<= now then
             changeItem(item,sobj);
         end;
 end;


procedure trace(str:string);
begin
Slave.log(str)
end;


function hextoStr(b:array of byte;count:integer):String;
var i:integer;
begin
  for i:=0 to count do
    result:=result+inttohex(b[i],2)+' ';
end;


end.

