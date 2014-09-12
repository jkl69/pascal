unit GWNetConnection;

{$mode objfpc}{$H+}
interface

//uses  Classes, SysUtils;
uses
  GWGlobal,classes, session, customserver1, telnetsock1,
  WebSocket3;

type
  TIECGWNetconnection= class(TTelnetConnection)
      Fsession:Tsession;
  public
     constructor Create(aSocket: TTCPCustomConnectionSocket); override;
     destructor Destroy; override;
     procedure readfull(aSender: TTelnetConnection; txt:string) ;
     procedure sendfull(const s:string) ;
  end;

  TIECGWNetServer = class(TTelnetServer)
     function CreateServerConnection(aSocket: TTCPCustomConnectionSocket): TCustomConnection; override;
  end;



  TIECWebSocketServer = class(TWebSocketServer)
  public
     constructor Create(aBind: string; aPort: string);
     procedure OnAfterAddConnection(Server: TCustomServer;aConnection: TCustomConnection);
  end;

  TIECWebSocketServerConnection = class
      fWS :TWebSocketServerConnection;
      Fsession:Tsession;
   private
      procedure OnClose(aSender: TWebSocketCustomConnection;
                  aCloseCode: integer; aCloseReason: string; aClosedByPeer: boolean);
      procedure OnRead(aSender: TWebSocketCustomConnection; aFinal, aRes1,
               aRes2, aRes3: boolean; aCode: integer; aData: TMemoryStream);
   public
      constructor Create(ws:TWebSocketServerConnection);
      destructor Destroy;
      procedure send(const s:string) ;
  end;

var
 NetServer : TIECGWNetServer=nil;
 WebSocket : TIECWebSocketServer=nil;

implementation

uses
  sysutils,synautil,synachar, math, cli;


constructor TIECGWNetconnection.Create(aSocket: TTCPCustomConnectionSocket);
begin
 inherited;
 Fsession := Tsession.create;
 fsession.Name:='NetConsole';
 fsession.onexecResult:=@sendfull;
 fsession.onexec:=@CLI.execCLI;
 OnReadFull := @readfull;
 fsession.writeResult('IEC GW');
 fSession.writePrompt;
end;

//TTelnetConnectionData = procedure (aSender: TTelnetConnection; txt:string) of object;
procedure TIECGWNetconnection.readfull(aSender: TTelnetConnection; txt:string) ;
begin
  fsession.EcexuteCmd(txt);
  fSession.writePrompt;
  if fsession.terminated then terminate;
end;

procedure TIECGWNetconnection.sendfull(const s:string) ;
begin
  fSocket.SendString(s);
end;

destructor TIECGWNetconnection.Destroy;
begin
 fsession.writeResult('IEC -> EXIT');
 fsession.Destroy;
 inherited;
end;


function TIECGWNetServer.CreateServerConnection(aSocket: TTCPCustomConnectionSocket): TCustomConnection;
var
    r : TTelnetServerConnections;
begin
  fncSocket := aSocket;
  result:= TIECGWNetconnection.Create(aSocket);
end;


{* TIECWebSocketServer *}

constructor TIECWebSocketServer.Create(aBind: string; aPort: string);
begin
 inherited;
 fOnAfterAddConnection := @OnAfterAddConnection;
end;

procedure TIECWebSocketServer.OnAfterAddConnection(Server: TCustomServer;aConnection: TCustomConnection);
var
 aWcon:TIECWebSocketServerConnection;
begin
  aWcon:=TIECWebSocketServerConnection.Create(TWebSocketServerConnection(aConnection));
// TWebSocketServerConnection(aConnection).OnOpen := OnOpen;
 //TWebSocketServerConnection(aConnection).Socket.OnSyncStatus := OnConnectionSocket;
 logger.Info(Format('OnAfterAddConnection (%d) %s:%d', [aConnection.Index, aConnection.Socket.GetRemoteSinIP, aConnection.Socket.GetLocalSinPort]));
end;

{* TIECWebSocketServerConnection *}

constructor TIECWebSocketServerConnection.Create(ws:TWebSocketServerConnection);
 begin
  inherited create;
  fws:= ws;
  fWS.OnRead := @OnRead;
  fWS.onclose := @OnClose;
  Fsession := Tsession.create;
  fsession.Name:='WebSocket';
  fsession.onexecResult:=@send;
  fsession.onexec:=@CLI.execCLI;
  fsession.writeResult('IEC GW');
 end;

destructor TIECWebSocketServerConnection.Destroy;
begin
 logger.Info('IECWebSocketServerConnection.Destroy');
// fsession.writeResult('IECGW -> EXIT');
 fsession.terminate;
 fsession.Destroy;
 inherited;
end;

procedure TIECWebSocketServerConnection.OnRead(aSender: TWebSocketCustomConnection; aFinal, aRes1,
  aRes2, aRes3: boolean; aCode: integer; aData: TMemoryStream);
var
 s:String;
begin
  logger.debug(Format('OnRead %d, final: %d, ext1: %d, ext2: %d, ext3: %d, type: %d, length: %d', [aSender.Index, ord(aFinal), ord(aRes1), ord(aRes2), ord(aRes3), aCode, aData.Size]));

  s := ReadStrFromStream(Fws.ReadStream, min(fWs.ReadStream.size, 10 * 1024));
  if (fWs.ReadCode = wsCodeText) then
     logger.Info('WebSocketRx: '+CharsetConversion(s, UTF_8, GetCurCP))
  else
    Logger.Info(s+'_');

  fWs.ReadStream.Position := 0;
  logger.Info('Header'+fWS.Header.Text);
//  fsession.writeResult('IEC GW');
  fsession.EcexuteCmd(s);
  fsession.onexec:=@CLI.execCLI;
  fsession.path:='';
//  fSession.writePrompt;
  if fsession.terminated then FWs.terminate;
end;

procedure TIECWebSocketServerConnection.send(const s:string) ;
begin
   fws.SendText(CharsetConversion(s, GetCurCP, UTF_8));
end;

procedure TIECWebSocketServerConnection.OnClose(aSender: TWebSocketCustomConnection;
  aCloseCode: integer; aCloseReason: string; aClosedByPeer: boolean);
var
  s:String;
begin
  if (aClosedByPeer) then s:='aClosedByPeer' else s:= 'aClosedByServer';
  logger.Info(Format('OnClose %d, %d, %s, %s', [aSender.Index, aCloseCode, aCloseReason, s]));
  destroy;
//  fsession.terminate;
end;

end.

