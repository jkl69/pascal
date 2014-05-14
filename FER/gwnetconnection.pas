unit GWNetConnection;

{$mode objfpc}{$H+}
interface

//uses  Classes, SysUtils;
uses
  session, customserver1, telnetsock1;

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


implementation

uses
  cli;

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
 fsession.Destroy;
end;


function TIECGWNetServer.CreateServerConnection(aSocket: TTCPCustomConnectionSocket): TCustomConnection;
var
    r : TTelnetServerConnections;
begin
  fncSocket := aSocket;
  result:= TIECGWNetconnection.Create(aSocket);
end;

end.

