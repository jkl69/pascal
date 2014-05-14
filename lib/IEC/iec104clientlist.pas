unit IEC104Clientlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IEC104Client, IEC104Socket,
  cliexecute,
  TLoggerUnit, TLevelUnit;

type

TIEC104Clientlist=class
  private
//    FCLI:Tcli;
    FLogger: TLogger;
    FClients:TStringlist;
//    FClients:TList;
    FonClientcreate: TIECSocketEvent;
  protected
    function getClient(i:integer):TIEC104Client;
  public
    constructor Create;
    destructor destroy; override;
    procedure log(ALevel : TLevel; const AMsg : String);
//    procedure Cliexecute(s:string;result:TCLIResult);
//    function addclient:integer;
    function addclient(name:String):integer;
    function delete(n:string):boolean;
    function delete(i:integer):boolean;
//    procedure delete(i:integer);
    procedure clear;
    property Logger : Tlogger read Flogger write FLogger;
    property Clients:TStringList read FClients;
    function getClient(n:String):TIEC104Client;
    property Client[Index: Integer]: TIEC104Client read GetCLient;
    property onClientCreate:TIECSocketEvent read FonClientCreate write FonClientCreate;
end;


implementation

constructor TIEC104Clientlist.Create;
begin
 inherited create;
 Fclients:=TStringlist.create;
end;

destructor TIEC104Clientlist.destroy;
begin
  log(debug,'destroy');
  clear;
  Fclients.Destroy;
//  Fcli.destroy;
  log(debug,'destroy_');
  inherited destroy;
end;

procedure TIEC104Clientlist.log(ALevel : TLevel; const AMsg : String);
var
 s:String;
begin
   if (assigned(Flogger)) then
      begin
        s:='CLIST_'+AMsg;
        Flogger.log(ALevel,s);
      end;
end;

function TIEC104Clientlist.getClient(i:integer):TIEC104Client;
begin
 getClient:= nil ;
 if (i<Fclients.Count) then
    Result := TIEC104Client(Fclients.Objects[i]);
//      Result := TIEC104Client(FClients[I]);
end;

function TIEC104Clientlist.getClient(n:String):TIEC104Client;
var
 i:integer;
begin
 result:=nil;
 i:=Fclients.IndexOf(n);
 if i=-1 then exit;
 Result := TIEC104Client(Fclients.Objects[i]);
end;

function TIEC104Clientlist.delete(n:string):boolean;
var
 FClient :TIEC104Client;
begin
  FClient:= getClient(n);
  delete:=false;
  if (FClient<>nil) then
     begin
       Fclient.stop;
       Fclient.destroy;
       Fclients.Delete(Fclients.IndexOf(n));
       delete:=true;
     end;
end;

function TIEC104Clientlist.delete(i:integer):boolean;
var
 FClient :TIEC104Client;
begin
//  FClient:= TIEC104Client(Fclients.Objects[i]);
  FClient:= getClient(i);
  delete:=false;
  if (FClient<>nil) then
     begin
       Fclient.stop;
       Fclient.destroy;
       Fclients.Delete(i);
       delete:=true;
     end;
end;

procedure TIEC104Clientlist.clear;
var
 FClient :TIEC104Client;
begin
  log(debug,'clear:'+inttoStr(FClients.Count));
  while FClients.Count>0 do
     begin
       FClient:= TIEC104Client(Fclients.Objects[FClients.Count-1]);
//       FClient:= TIEC104Client(Fclients[0]);
       Fclient.destroy;
       Fclients.Delete(FClients.Count-1);
     end;
end;

function TIEC104Clientlist.addclient(name:string):integer;
var
  FClient :TIEC104Client;
  i:integer;
begin
    for i:=0 to Fclients.Count-1 do
        begin
//        FClient := TIEC104Client(Fclients.Objects[i]);
//        if Fclient.Name = name then
        if Fclients[i] = name then
           begin
           result:= -1; exit;
           end;
        end;
    FClient:= TIEC104Client.Create(nil);
    FClient.Name:=name;
    Fclient.Logger:=Flogger;
    Fclients.AddObject(name,Fclient);
//    FClient.Activ:=true;
   if Assigned(FonClientCreate) then
       FonClientCreate(Fclient, Fclient.iecSocket);
   log(debug,'clients:'+inttoStr(FClients.Count));
   result:=Fclients.count-1;
end;

{*
procedure TIEC104Clientlist.cliexecute(s:string;Result:TCLIResult);
begin
//  Fcli.ParseCMD(nil,s,result);
end; *}

end.
