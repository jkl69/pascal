unit Unit1;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Log: TMemo;
    OpenDialog: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
   key, windows;

{$R *.lfm}
const
  pw='sysuser';
//  masterpw='j';
  masterpw='jaen@IDS';

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
if openDialog.Execute then
 Edit1.text:=opendialog.FileName;
// ShowMessage(Application.ExeName);

end;

procedure TForm1.Button2Click(Sender: TObject);
var
 s:string;
 t:TDatetime;
 pos:integer;
begin
  s:= edit1.text;
  log.Append('Encode File '+s);
  t:= getcreatedate(s);
  log.Append('File create date '+datetimetostr(t)+' as float '+floattoStr(t));
  log.Append(createPW(s)+' HexTime('+CreatedateHexstr(s)+')');
  s:=EncodePW(s,pos);
  edit2.text:=s;
  log.Append(s+' timePos('+inttostr(pos)+')');
  log.Append('');
//edit2.text:=EncodePW(Edit1.text,pos);
end;

procedure TForm1.Button4Click(Sender: TObject);     //DECODE PW
var
 s,s2:string;
 t:TDatetime;
begin
 s:=edit2.text;
 log.Append('Decode PW: '+s);
 log.Append('Position of date in PW: '+inttostr(decodePos(s)));
 log.Append('Path: '+decodePW(s));
 s2:= getPWtime(s);
 t:=hex2double(s2);
 log.Append('File CreationTime as HEX: '+s2+' as float '+floattoStr(t)+'as Time '+Datetimetostr(t));

// s:=edit2.text;
  if checkPW(s,edit1.text) then
   log.Append('Path and Time of file identical ! OK !')
  else
  log.Append('PW not fits to File !! ERORR !!!');

    log.Append('');
end;

procedure TForm1.Edit3Change(Sender: TObject);
begin
  if Edit3.Text=pw then Button2.Enabled:=true;
  if Edit3.Text=masterpw then
     begin
       Button4.Visible:=true;
       Log.Visible:=true;
       Button2.Enabled:=true;
     end
//  else Button2.Enabled:=false;
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Edit1.Text:=Application.ExeName;
end;

end.

