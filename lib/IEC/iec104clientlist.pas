unit IEC104Clientlist;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  IEC104Client, IEC104Socket,
  cliexecute,
  TLoggerUnit, TLevelUnit;

type
Tcli=class ;

TIEC104Clientlist=class
  private
    FCLI:Tcli;
    FLogger: TLogger;
    //    FClients:TStringlist;
    FClients:TList;
    FonClientcreate: TIECSocketEvent;
  protected
   function getClient(i:integer):TIEC104Client;
  public
    constructor Create;
    destructor destroy; override;
    procedure log(ALevel : TLevel; const AMsg : String);
    procedure Cliexecute(s:string;result:TCLIResult);
    function addclient:integer;
    function delete(i:integer):boolean;
//    procedure delete(i:integer);
    procedure clear;
    property Logger : Tlogger read Flogger write FLogger;
    property Clients:TList read FClients;
    property Client[Index: Integer]: TIEC104Client read GetCLient;
    property onClientCreate:TIECSocketEvent read FonClientCreate write FonClientCreate;
end;

Tcli=class(Tcliexecute)
  private
  protected
    clients:TIEC104Clientlist;
   public
     procedure execute(ix:integer); override;
end;

implementation

Procedure tcli.execute(ix:integer);
var
  i,c,clix:integer;
  FClient :TIEC104Client;
  txt:String;
begin
//  (['add','delete','list','log']);
  if cmdix > 99 then
     begin
       clix:=cmdix-100;
       FClient:=clients.getClient(clix);
       if FClient<>nil then
          Fclient.Cliexecute(cmdchild,CLIresult)
       else
          begin
          CLIResult.cmdmsg :=  'Client:'+inttoStr(clix)+' NOT found';
          CLIResult.did:=false;
          exit;
          end;
     end;
  case (ix) of
    0: begin i:=clients.addclient;
             CLIResult.return :=inttostr(i);
             CLIResult.cmdmsg:='new ClientNo='+inttostr(i);
             exit;  end;
    1: begin
        val(Parameter,i,c);
        if c<>0 then   // Parameter is an number
           begin
          CLIResult.did:=false;
          CLIResult.cmdmsg:='Invalid ClientNo  usage e.g. delete=0';
          exit;
          end;
      if (clients.delete(strtoint(Parameter))) then
          begin
            CLIResult.did:=true;
            CLIResult.cmdmsg:='client deleted'; exit;
          end
        else
           begin
             CLIResult.did:=false;
             CLIResult.cmdmsg:='could not delete'; exit;
           end;
        end;
    2: begin
        txt:='';
        CLIResult.Arraysize:=clients.FClients.count;
        CLIResult.hasArray:=true;
        CLIResult.cmdmsg := 'Clients_count: '+inttostr(clients.FClients.count);
//        CLIResult.cmdmsg := 'Clients_count: '+inttostr(clients.FClients.count)+nl+ txt;
        for i:=0 to clients.FClients.count-1 do
          begin
           FClient:=clients.getClient(i);
//           txt:=txt+'client.'+inttostr(i)+' '+Fclient.host+':'+inttoStr(Fclient.port)+nl;
             CLIResult.msg[i]:='['+inttostr(i)+']client. '+Fclient.host+':'+inttoStr(Fclient.port);
//             CLIResult.msg[i]:='client.'+inttostr(i)+' '+Fclient.host+':'+inttoStr(Fclient.port);
          end;
          exit;
        end;
     3: begin if (TLevelUnit.tolevel(Parameter) <> nil) then
               begin
                 clients.Logger.setLevel(TLevelUnit.tolevel(Parameter));
                 CLIResult.cmdmsg:= 'change Clients LogLevel';
               end
            else begin
                CLIResult.cmdmsg:= 'Invalid LogLevel';
                CLIResult.did:=false;
               end;
        Exit; end;
  end;
end;

constructor TIEC104Clientlist.Create;
begin
 inherited create;
// Fclients:=TStringlist.create;
 Fclients:=Tlist.create;
 FCLI := Tcli.Create(self,['add','delete','list','log']);
 Fcli.clients:=self;
 Fcli.name:='CList';
end;

destructor TIEC104Clientlist.destroy;
begin
  log(debug,'destroy');
  clear;
  Fclients.Destroy;
  Fcli.destroy;
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
//    getClient := TIEC104Client(Fclients.Objects[i]);
      Result := TIEC104Client(FClients[I]);
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
//       FClient:= TIEC104Client(Fclients.Objects[FClients.Count-1]);
       FClient:= TIEC104Client(Fclients[FClients.Count-1]);
//       Fclient.Activ:=False; //detroy makes an active:= false;
       Fclient.destroy;
       Fclients.Delete(FClients.Count-1);
     end;
end;

function TIEC104Clientlist.addclient:integer;
var
  FClient :TIEC104Client;
begin
    FClient:= TIEC104Client.Create;
    Fclient.Logger:=Flogger;
    Fclients.Add(Fclient);
//    Fclients.AddObject(inttostr(Fclients.Count),Fclient);
//    FClient.Activ:=true;
   if Assigned(FonClientCreate) then
       FonClientCreate(Fclient, Fclient.iecSocket);
   log(debug,'clients:'+inttoStr(FClients.Count));
   result:=Fclients.count-1;
end;

procedure TIEC104Clientlist.cliexecute(s:string;Result:TCLIResult);
begin
  Fcli.ParseCMD(nil,s,result);
end;


end.
