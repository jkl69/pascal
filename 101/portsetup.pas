unit Portsetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Spin,
  StdCtrls, ExtCtrls;

type
 //config(600, 8, 'E', SB1, False, False);
  TPortconfig=record
     linkadr:word;
     port:string;
     baudrate:cardinal;
     dbits:byte;
     parity:Char;
     Sbits:byte;

  end;

  { TPortSetup }

  TPortSetup = class(TForm)
    Button1: TButton;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ComboBox4: TComboBox;
    ComboBox5: TComboBox;
    fLinkNo: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    LLink: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
    procedure update;
  public
    function getconfig:TPortconfig;
    function getconfigstr:String;
    { public declarations }
  end;

  function loadsettings(f:string):TPortconfig;
  procedure savesettings(f:string;conf:TPortconfig);

var
  setup: TPortSetup;
  conf : TPortconfig;

implementation

{$R *.lfm}

uses inifiles, Main, synaser;

const
  BaudRateStrings: array[0..14] of string = ('110', '300', '600',
    '1200', '2400', '4800', '9600', '14400', '19200', '38400', '56000', '57600',
    '115200', '128000', '256000');
  DataBits: array [0..2] of byte =(6,7,8);
  parity: array[0..4]of String= ('N','O','E','M','S');//(N - None, O - Odd, E - Even, M - Mark or S - Space).)
  StopBits: array[0..2] of byte =(SB1,SB1andHalf,SB2);

{ TPortSetup }

function TPortSetup.getconfigStr:String;
var s:String; conf:TPortconfig;
begin
  conf:=getconfig;
  case conf.Sbits of
    SB1: s:='1';
    SB1andHalf: s:='1.5';
    SB2: s:='2';
  end;
//  result:=format('settings: port:%s  baud:%d dBits:%d parity:%s sBits:%s',
    result:=format('%s   %d   %d%s%s',
    [conf.port,conf.baudrate,conf.dbits,conf.parity,s]);
//  result:=s;
end;

function TPortSetup.getconfig:TPortconfig;
begin
  result.linkadr:=fLinkNo.Value;
  result.port:=ComboBox1.Items[ComboBox1.ItemIndex];
  result.baudrate:=Strtoint(BaudRateStrings[ComboBox2.ItemIndex]);
  result.dbits:=DataBits[ComboBox3.ItemIndex];
  result.parity:=parity[ComboBox4.ItemIndex][1];
  result.Sbits:=StopBits[ComboBox5.ItemIndex];
end;

function loadsettings(f:string):TPortconfig;
var
 INI:TINIFile;
 i:integer;
const section='Config';
begin
//INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iecgw.ini');
 INI:= TIniFile.Create(f);
 result.linkadr:=ini.ReadInteger(section,'LinkAdr',1);
 result.port:=ini.ReadString(section,'Port','COM1');
 result.baudrate:=ini.ReadInteger(section,'BaudRate',9600);
 result.dbits:=ini.ReadInteger(section,'DataBits',8);
 result.parity:=ini.ReadString(section,'Parity','E')[1];
 result.Sbits:=ini.ReadInteger(section,'StopBits',0);
 ini.Destroy;
end;

procedure savesettings(f:string;conf:TPortconfig);
var
 INI:TINIFile;
 i:integer;
const section='Config';
begin
//INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iecgw.ini');
 INI:= TIniFile.Create(f);
 ini.WriteInteger(section,'LinkAdr',conf.linkadr);
 ini.WriteString(section,'Port',conf.port);
 ini.WriteInteger(section,'BaudRate',conf.baudrate);
 ini.WriteInteger(section,'DataBits',conf.dbits);
 ini.WriteString(section,'Parity',conf.parity);
 ini.WriteInteger(section,'StopBits',conf.Sbits);
 ini.Destroy;
end;

procedure TPortSetup.FormCreate(Sender: TObject);
var pl:TStringlist;
    i:integer;
begin
  pl:=Tstringlist.Create;
  pl.Delimiter := ',';
  pl.DelimitedText:= GetSerialPortNames;
  ComboBox1.Items:=pl;
  for i:=0 to high(BaudRateStrings) do
     ComboBox2.Items.Add(BaudRateStrings[i]);
  for i:=0 to high(DataBits) do
     ComboBox3.Items.Add(inttoStr(DataBits[i]));

  for i:=0 to high(parity) do
     ComboBox4.Items.Add(parity[i]);

  ComboBox5.Items.Add('SB1');
  ComboBox5.Items.Add('SB1.5');
  ComboBox5.Items.Add('SB2');

  ComboBox1.ItemIndex:=0;

  update;
  slave.Linkadr.Value:=conf.linkadr;
  slave.bport.Caption:=getconfigstr;
end;

procedure TPortSetup.update;
var index:integer;
begin
  flinkno.Value:=conf.linkadr;
  index := ComboBox1.Items.IndexOf(conf.port);
  if index<>-1 then ComboBox1.ItemIndex:=index;
  index := ComboBox2.Items.IndexOf(intToStr(conf.baudrate));
  if index<>-1 then ComboBox2.ItemIndex:=index;
  index := ComboBox3.Items.IndexOf(intToStr(conf.dbits));
  if index<>-1 then ComboBox3.ItemIndex:=index;
  index := ComboBox4.Items.IndexOf(conf.parity);
  if index<>-1 then ComboBox4.ItemIndex:=index;

//  ComboBox5.ItemIndex:=0;
  ComboBox5.ItemIndex:=conf.Sbits;
end;

procedure TPortSetup.Button1Click(Sender: TObject);
begin
  close;
end;

end.

