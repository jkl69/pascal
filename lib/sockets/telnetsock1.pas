{==============================================================================|
|==============================================================================|
| Requirements: Ararat Synapse (http://www.ararat.cz/synapse/)                 |
|==============================================================================}

{

}


unit telnetsock1;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}
{$H+}

interface

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, blcksock, syncobjs,
  CustomServer1;


type
  TTelnetConnection = class;

  {:Event procedural type to hook OnOpen events on connection
  }
  TTelntConnectionEvent = procedure (aSender: TTelnetConnection) of object;


  {:Event procedural type to hook OnRead on OnWrite event on connection
  }
  TTelnetConnectionData = procedure (aSender: TTelnetConnection; txt:string) of object;


  TTelnetConnection = class(TCustomConnection)
  private
  protected
    fOnRead: TTelnetConnectionData;
    fOnReadFull: TTelnetConnectionData;
    fOnWrite: TTelnetConnectionData;
    fOnClose: TTelntConnectionEvent;
    fOnOpen: TTelntConnectionEvent;

    ftxt: String;
    ftext:String;
    fstext:String;

//    fWriteStream: TMemoryStream;

    fSendCriticalSection: TCriticalSection;

    procedure ExecuteConnection; override;
    function ReadData(): integer;// virtual;

    procedure SyncClose;
    procedure SyncOpen;
    procedure SyncRead;
    procedure SyncReadFull;
    procedure SyncWrite;
    procedure ProcessClose; virtual;
    function ValidConnection: boolean;

  published
  public
    procedure Close; virtual; abstract;
    procedure SendText(const aData: string); virtual;
    procedure TerminateThread; override;
    property OnClose: TTelntConnectionEvent read fOnClose write fOnClose;
    property OnOpen: TTelntConnectionEvent read fOnOpen write fOnOpen;
    property OnRead: TTelnetConnectionData read fOnRead write fOnRead;
    property OnReadFull: TTelnetConnectionData read fOnReadFull write fOnReadFull;
    property OnWrite: TTelnetConnectionData read fOnWrite write fOnWrite;
  end;

  {: Class of Telnet connections }
  TTelnetConnections = class of TTelnetConnection;

  {: Telnet server connection automatically created by server on incoming connection }
  TTelnetServerConnection = class(TTelnetConnection)
  public
    constructor Create(aSocket: TTCPCustomConnectionSocket); override;
    procedure Close; override;
   procedure TerminateThread; override;
 end;


  TTelnetServerConnections = class of TTelnetServerConnection;

  TTelnetServer = class;


  TTelnetServerReceiveConnection = procedure ( Server: TTelnetServer; Socket: TTCPCustomConnectionSocket) of object;

  TTelnetServer = class(TCustomServer)
  protected
    {CreateServerConnection sync variables}
    fncSocket: TTCPCustomConnectionSocket;
    fOnReceiveConnection: TTelnetServerReceiveConnection;  protected

    function CreateServerConnection(aSocket: TTCPCustomConnectionSocket): TCustomConnection; override;
    procedure SyncReceiveConnection;
    property Terminated;

  public
    property OnReceiveConnection: TTelnetServerReceiveConnection read fOnReceiveConnection write fOnReceiveConnection;
    procedure CloseAllConnections(aCloseCode: integer; aReason: string);
    procedure TerminateThread; override;
    procedure BroadcastText(aData: string);
  end;

implementation

uses  synautil, synacode, synsock {$IFDEF Win32}, Windows{$ENDIF Win32},
  BClasses, synachar;



{$IFDEF Win32} {$O-} {$ENDIF Win32}


{ TTelnetServer }

procedure TTelnetServer.BroadcastText(aData: string);
var i: integer;
begin
  LockTermination;
  for i := 0 to fConnections.Count - 1 do
  begin
    if (not TTelnetServerConnection(fConnections[i]).IsTerminated) then
      TTelnetServerConnection(fConnections[i]).SendText(aData);
  end;
  UnLockTermination;
end;

procedure TTelnetServer.CloseAllConnections();
var i: integer;
begin
  LockTermination;
  for i := fConnections.Count - 1 downto 0 do
  begin
    if (not TTelnetServerConnection(fConnections[i]).IsTerminated) then
      TTelnetServerConnection(fConnections[i]).Close;// SendBinary(aData, aFinal, aRes1, aRes2,  aRes3);
  end;
  UnLockTermination;

end;

function TTelnetServer.CreateServerConnection(aSocket: TTCPCustomConnectionSocket): TCustomConnection;
var
    r : TTelnetServerConnections;
begin
  fncSocket := aSocket;
//  result := inherited CreateServerConnection(aSocket);
//  result := r.Create(aSocket);
  result:= TTelnetConnection.Create(aSocket);
//  writeln('ServerConnectionCount:'+inttoStr(count));
end;


procedure TTelnetServer.SyncReceiveConnection;
begin
  if (assigned(fOnReceiveConnection)) then
     fOnReceiveConnection(self, fncSocket);
end;

procedure TTelnetServer.TerminateThread;
begin
  if (terminated) then exit;
  fOnReceiveConnection := nil;  
  inherited;
end;

{ TTelnetConnection }

function TTelnetConnection.ValidConnection: boolean;
begin
//  if (IsTerminated) then Writeln('TERM');
//  if (Socket.Socket <> INVALID_SOCKET) then Writeln('<> INVALID_SOCKET');
  result := (not IsTerminated);// and (Socket.Socket <> INVALID_SOCKET);
end;

procedure TTelnetConnection.SendText(const aData: string);
begin
  fstext:=aData;
  SyncWrite;
end;

function TTelnetConnection.ReadData(): integer;// virtual;
begin
 result := 0;
// writeln( 'ExecuteRead');
   repeat
//     writeln( 'ExecuteRead');
     if (fSocket.CanReadEx(1000)) then
      begin
        if ValidConnection then
        begin
          ftxt := fsocket.RecvPacket(300000);
          fsocket.SendString(ftxt);
          SyncRead;
//          writeln( 'LastError:'+inttoStr(fSocket.LastError));
          if (fSocket.LastError = 0) then
             begin
             ftext:=ftext+ftxt;
             end
          else
            result:=-1;
          if (fSocket.LastError <> WSAETIMEDOUT) and (fSocket.LastError <> 0) then
            result := -1;
        end;
       end;
 until (pos(lf,ftext)<>0) or (result=-1);
 while pos(cr,ftext)<>0 do delete(ftext,pos(cr,ftext),1);
 while pos(lf,ftext)<>0 do delete(ftext,pos(lf,ftext),1);
end;

procedure TTelnetConnection.ExecuteConnection;
var
  result:integer;
begin
 SyncOpen;
// writeln( 'Execute.Connection');
 try
    //while(not IsTerminated) or fClosed do
    while ValidConnection do
        begin
         ftext:='';
         result := ReadData;
         if (result <> 0) then
            begin
            if (not Terminated) then
               begin
               TerminateThread;
               break;
               end;
            end
         else
            begin
             writeln('result:'+ftext);
             SyncReadFull;
            end;
        end;
    finally
    {$IFDEF UNIX} sleep(2000); {$ENDIF UNIX}
  end;
  while not terminated do
     begin
       sleep(500);
       Writeln('Wait Thread end');
     end;
 // fSendCriticalSection.Enter;
  Writeln('** Thread end');
end;

procedure TTelnetConnection.ProcessClose;
begin
  SyncClose;
end;


function hexToStr(aDec: integer; aLength: integer): string;
var tmp: string;
    i: integer;
begin
  tmp := IntToHex(aDec, aLength);
  result := '';
  for i := 1 to (Length(tmp)+1) div 2 do
  begin
    result := result + ansichar(StrToInt('$'+Copy(tmp, i * 2 - 1, 2)));
  end;
end;

function StrToHexstr2(str: string): string;
var i: integer;
begin
  result := '';
  for i := 1 to Length(str) do result := result + IntToHex(ord(str[i]), 2) + ' ';
end;

 procedure TTelnetConnection.SyncClose;
begin
  if (assigned(fOnClose)) then
    fOnClose(self);
end;

procedure TTelnetConnection.SyncOpen;
begin
  if (assigned(fOnOpen)) then
    fOnOpen(self);
end;

procedure TTelnetConnection.SyncRead;
begin
  if (assigned(fOnRead)) then
    fOnRead(self, ftxt);
end;

procedure TTelnetConnection.SyncReadFull;
begin
  if (assigned(fOnReadFull)) then
    fOnReadFull(self, ftext);
end;

procedure TTelnetConnection.SyncWrite;
begin
  if (assigned(fOnWrite)) then
    fOnWrite(self, fstext);
end;

procedure TTelnetConnection.TerminateThread;
begin
  if (Terminated) then exit;

//  if (not Closed) then
    SyncClose;
  Socket.OnSyncStatus := nil;
  Socket.OnStatus := nil;
  inherited;
end;


{ TTelnetServerConnection }

procedure TTelnetServerConnection.Close();
begin
  if (Socket.Socket <> INVALID_SOCKET) then
  begin
    ProcessClose();
    TerminateThread;
  end;
end;

constructor TTelnetServerConnection.Create(aSocket: TTCPCustomConnectionSocket);
begin
  inherited ;
end;

procedure TTelnetServerConnection.TerminateThread;
begin
  if (Terminated) then exit;
  //if (not TTelnetSocketServer(fParent).Terminated) and (not fClosedByMe) then DoSyncClose;
  fOnClose := nil;
  inherited;

end;

end.
