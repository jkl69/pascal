unit cliexecute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  sockets, blcksock,
  fpjson, jsonparser;
const
  nl = {$IFDEF LINUX} AnsiChar(#10) {$ENDIF}
       {$IFDEF MSWINDOWS} AnsiString(#13#10) {$ENDIF};

type

  Tsession = class
     public
 //     sock: TSocket;
      sock :TTCPBlockSocket;
      exit: boolean;
      Json: boolean;
  end;

  TCLIResult = class
    did:boolean;
    CMDMsg:String;
    return:String;
    hasArray:boolean;
    Arraysize:integer;
    msg :array[0..10] of String;
    awnser: TJSONObject;
  public
    constructor Create;
    destructor destroy; override;
    function read():String;
  end;

  TcliExecute=class
   private
     FCmds:TStringlist;
     procedure JSONToCMD;
     Procedure doCMD;
     procedure doJSONparse(parser:TJSONParser);
     procedure JSONResult;
  protected
    Fobj:TObject;
    Fsession:Tsession;
    txtIN:string;
    JSONType:String;
    cmd:String;
    Parameter:String;
    cmdix:Integer;
    cmdChild:String;
    cliResult :TCLIResult;
  public
    name: String;
    constructor Create(sender:Tobject;const cmds:array of String);
    destructor destroy; override;
//    Procedure ParseCMD(session:TSession;s:String);
    Procedure ParseCMD(session:TSession;s:String;Result:TCLIResult);
    Procedure execute(ix:integer); virtual;
    procedure executeX; virtual;
  end;


  TClientCLI=class(Tcliexecute)
    private
    protected
     public
       Procedure execute(ix:integer); override;
  end;

  TTimesetCLI=class(Tcliexecute)
    private
    protected
    public
       Procedure execute(ix:integer); override;
  end;

var
   TimerCLI:TTimesetCLI;

implementation

uses
   IEC104Client, IEC104Socket;
var
  FTimerSet: TIEC104Timerset;

constructor TCLIResult.Create;
begin
inherited create;
awnser:= TJSONObject.Create;
end;

destructor TCLIResult.destroy;
begin
awnser.Destroy;
inherited destroy;
end;

function TCLIResult.read():String;
var
  i:integer;
begin
  if did then
      read:='[TRUE] '+cmdmsg
  else
     read:='[FALSE] '+cmdmsg;

//  if arraysize>0 then
//     read:=read+'_ARRAY_' ;
  if  hasArray then
      begin
      read := read+nl;
      for i:=0 to Arraysize-1 do
          read := read+msg[i]+nl; ;
      end;
end;

//###########################
  {Tcliexecute}
//###########################

constructor Tcliexecute.Create(sender:Tobject;const cmds:array of String);
begin
 inherited create;
 Fobj:=sender;
 Fcmds:=TStringlist.create;
// awnser:= TJSONObject.Create;
 Fcmds.AddStrings(cmds);
end;

destructor Tcliexecute.destroy;
begin
  Fcmds.Destroy;
//  awnser.Destroy;
  inherited destroy;
end;

Procedure Tcliexecute.execute(ix:integer);
begin
  if (CLIResult<>nil) then
      Cliresult.cmdmsg:= name+'EXECUTE CMDNo.'+inttostr(ix);
end;

procedure Tcliexecute.executeX;
begin
 if (CLIResult<>nil) then
     CLIResult.cmdmsg:= name+'EXECUTE X';
end;

procedure Tcliexecute.doJSONparse(parser:TJSONParser);
var
  jdata : TJSONData;
  jo : TJSONObject;
  js : TJSONString;
  ja: TJSONArray;
  JSONCMD:String;
  txt:String;
  i:integer;
begin
Try
   jdata:=parser.Parse;
   If Assigned(jdata) then
     begin
     Jo :=TJSONObject(jdata);
     JSONCMD:= jo.Strings['cmd'];
     txt:=('JSON_CMD_' +JSONCMD);
     JSONType:= jo.Strings['type'];
     txt:=txt+('  JSON_TYPE_' +JSONTYPE);
     if JSONType='set' then
         begin
         Ja:=jo.Arrays['array'];
         txt:=txt+('  JSON_ARRAY_SIZE_' +inttoStr(ja.Count));
         writeln(txt);
         for i:=0 to ja.Count-1 do
             begin
             txtin:=JSONCMD+'.'+ja.Strings[i];
             writeln('DOCMD '+txtin);
             doCmd; JSONResult;
             end;
         end
     else
        begin
        txtin:=JSONCMD;
        writeln(txt);
        doCMD;JSONResult;
        end
     end
   else
     begin
       CLIResult.cmdmsg:='NO JSON TO PARSE';
       CLIResult.did:=false;
       JSONResult; exit;
     end;
 except
      On E : Exception do
        begin
          CLIResult.cmdmsg:=('ERROR on JSON Parse'+e.Message);
          CLIResult.did:=false;
          JSONResult; exit;
        end;
    end;

// If Assigned(js) then
//     jdata.Destroy;
end;

procedure Tcliexecute.JSONResult;
var
  parser:TJSONParser;
  ja: TJSONArray;
  i: integer;
begin
CLIResult.awnser.Clear;
CLIResult.awnser.Add('cmd', TJSONString.Create(txtin));
CLIResult.awnser.Add('executed', TJSONBoolean.Create(CLIResult.did));
CLIResult.awnser.Add('result', TJSONString.Create(CLIResult.return));
CLIResult.awnser.Add('message', TJSONString.Create(CLIResult.cmdmsg));
CLIResult.awnser.Add('isArray', TJSONBoolean.Create(CLIResult.hasArray));
if CLIResult.hasArray then
     begin
     ja := TJSONArray.Create;
     for i:=0 to CLIResult.Arraysize-1 do
         ja.Add(CLIResult.msg[i]);

     CLIResult.awnser.Add('array',ja);
     end;
Fsession.sock.sendString(CliResult.awnser.AsJSON);
end;

procedure Tcliexecute.JSONTocmd;
var
  parser:TJSONParser;
begin
parser:=TJSONParser.Create(txtIn);

DoJSONParse(parser);
//JSONResult;

//Fsession.exit:=true;
freeandnil(parser);
end;

Procedure Tcliexecute.ParseCMD(session:TSession;s:string;Result:TCLIResult);
begin
    Fsession:=session;
    CLIResult:=Result;
    CLIResult.return:='';
    CLIResult.hasArray:=false;
    txtIn:=S;
    if Fsession<>nil then
       begin
       if (Fsession.Json) then
          begin
          JSONtocmd;
          exit;
          end;
       end;

    doCMD;
    if (Fsession<>nil) then Fsession.sock.SendString(CLIResult.read()+nl);
end;

Procedure TcliExecute.doCMD;
var
  clix:integer;
  c,po,i:integer;
begin
    txtIn:=LowerCase(TXTIN);
    Parameter:='';
    cmd:=txtin;
    po:=pos('=',cmd);
    if po>0 then
       begin
       Parameter:=copy(txtin,po+1,length(txtin));
       cmd:= copy(txtin,1,po-1);
       end;

    po:=pos('.',cmd);
    if po>0 then
       begin  cmd:=copy(cmd,1,po-1); cmdChild:=copy(txtin,po+1,length(txtin));  end
    else cmdChild:='';

    cmdix:=FCmds.IndexOf(cmd);
    val(cmd,clix,c);
    if c=0 then   // CMD is an number
      begin
      cmdix:=100+clix;
//      writeln('Client:'+inttoStr(cmdix));
      end;

    if (cmd='?') then
        begin
          CLIResult.CMDMSG:=name+' Available commands are:'+nl;
          for i:=0 to FCmds.Count-1 do
             CLIResult.CMDMSG := CLIResult.CMDMSG + FCmds[i]+nl;
         CLIResult.did:=true;
         Exit;
         end;
    if (cmd='x') then
        begin   executeX;  Exit; end;

    if (cmdix=-1) then
        begin
        CLIResult.CMDMSG:= name+' command "'+cmd+'" not found';
        CLIResult.did:=false;
        end
    else
       begin
       CLIResult.did:=true;
       CLIResult.CMDMsg:='PASS CMD TO NEXT MODULE';
       execute(cmdix);
       end;
end;

procedure TClientCLI.execute(ix:integer);
var
  c,i:integer;
  client:TIEC104Client;
begin
//    ['start','stop','close','host','port','send','startDt'
//    'stopdt','list'.timer]]
    client:=TIEC104Client(Fobj);
    case (ix) of
        0: begin client.start;
               CLIResult.cmdmsg := 'client started'; exit;  end;
        1: begin client.stop;
               CLIResult.cmdmsg := 'client started'; exit;  end;
        2: begin client.Socket.CloseSocket;  exit;  end;
        3: begin
            if parameter<>'' then
                client.host:=parameter;
           CLIResult.CMDMsg:='host='+client.host;
           exit;  end;
       4: begin
            if parameter<>'' then
               client.port:=strtoint(parameter);
            CLIResult.CMDMsg:='port='+inttostr(client.port);
            exit;  end;
        5: begin
//            if parameter<>'' then begin;
               CLIResult.cmdmsg := 'client send '+inttostr(client.send(parameter))+' Bytes';
//               end;
            exit;  end;
        6 :begin if client.socket<>nil then
                   begin
                   Client.iecsocket.SendStart;
                   CLIResult.cmdmsg := 'client sendes startdt';
                   end
               else begin
                    CLIResult.did:=false;
                    CLIResult.cmdmsg := 'client NOT connected';
                   end;
            exit; end;
        7 :begin  if client.socket<>nil then
                   begin
                   Client.iecsocket.SendStop;
                   CLIResult.cmdmsg := 'client sends stopdt';
                   end
               else begin
                    CLIResult.did:=false;
                    CLIResult.cmdmsg := 'client NOT connected';
                   end;
            exit; end;
        8 :begin
           i:=0;
           CLIResult.hasArray:=true;
           CLIResult.cmdmsg := 'client_settings: ';
           CLIResult.msg[i]:='host='+client.host; inc(i);
           CLIResult.msg[i]:='port='+inttoStr(client.port); inc(i);
           if client.Activ then
                CLIResult.msg[i]:='status=start'
            else
               CLIResult.msg[i]:='status=stop';
           inc(i);
           if client.socket<>nil then
               CLIResult.msg[i]:='connected=true'
           else
               CLIResult.msg[i]:='connected=false';
           inc(i);

           if client.socket<>nil then
               if client.iecSocket.linkStatus =IECStartDT then
                 CLIResult.msg[i]:='iecStatus=StartDt'
               else
                CLIResult.msg[i]:='iecStatus=StopDt'
           else
               CLIResult.msg[i]:='iecStatus=???';

           inc(i);
          CLIResult.Arraysize:=i;
          exit;
        end;

     9 :begin
         FTimerSet:=client.TimerSet;
         TimerCLI.ParseCMD(nil,cmdChild,CLIResult);
         client.TimerSet:= FtimerSet;
        end;
      end;
end;

procedure TTimesetCLI.execute(ix:integer);
var
  c,i:integer;
//  timerset:TIEC104Timerset;
begin
 inherited execute(ix);
// ['list','t0','t1','t2','t3','w','k']);
      if (ix=0) then
          begin
          i:=0;
          CLIResult.hasArray:=true;
          CLIResult.cmdmsg := 'client_timer: ';
          CLIResult.msg[i]:='T0='+inttostr(FTimerSet.T0); inc(i);
          CLIResult.msg[i]:='T1='+inttostr(FTimerSet.T1); inc(i);
          CLIResult.msg[i]:='T2='+inttostr(FTimerSet.T2); inc(i);
          CLIResult.msg[i]:='T3='+inttostr(FTimerSet.T3); inc(i);
          CLIResult.msg[i]:='k='+inttostr(FTimerSet.k); inc(i);
          CLIResult.msg[i]:='w='+inttostr(FTimerSet.w); inc(i);
          CLIResult.Arraysize:=i;  exit;
          end;
      if (Parameter='') then
        case (ix) of
        1: begin CLIResult.cmdmsg:='T0='+inttostr(FTimerSet.T0); exit;  end;
        2: begin CLIResult.cmdmsg:='T1='+inttostr(FTimerSet.T1); exit;  end;
        3: begin CLIResult.cmdmsg:='T2='+inttostr(FTimerSet.T2); exit;  end;
        4: begin CLIResult.cmdmsg:='T3='+inttostr(FTimerSet.T3); exit;  end;
        5: begin CLIResult.cmdmsg:='w='+inttostr(FTimerSet.w); exit;  end;
        6: begin CLIResult.cmdmsg:='k='+inttostr(FTimerSet.k); exit;  end;
        end
    else
       begin
         val(Parameter,i,c);
         if c<>0 then   // Parameter is NOT number
               begin CLIResult.did:=false;  CLIResult.cmdmsg:='Invalid Parameter'; exit; end;
         case (ix)  of
         1: begin FTimerSet.T0:= i; CLIResult.cmdmsg:='T0='+inttostr(FTimerSet.T0); exit;  end;
         2: begin FTimerSet.T1:= i; CLIResult.cmdmsg:='T1='+inttostr(FTimerSet.T1); exit;  end;
         3: begin FTimerSet.T2:= i; CLIResult.cmdmsg:='T2='+inttostr(FTimerSet.T2); exit;  end;
         4: begin FTimerSet.T3:= i; CLIResult.cmdmsg:='T3='+inttostr(FTimerSet.T3); exit;  end;
         5: begin FTimerSet.w:= i; CLIResult.cmdmsg:='w='+inttostr(FTimerSet.w); exit;  end;
         6: begin FTimerSet.k:= i; CLIResult.cmdmsg:='k='+inttostr(FTimerSet.k); exit;  end;
         end;
       end;
end;

initialization
 TimerCLI := TTimesetCLI.Create(nil,
 ['list','t0','t1','t2','t3','w','k']);
 TimerCLI.name := 'TIMER_CLI';

Finalization
 TimerCLI.destroy;

end.

