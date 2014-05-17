unit IEC104Socket;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, fptimer,
  blcksock,
//  cliexecute,
  TLoggerUnit, TLevelUnit;

type

TIEC104Socket = class;
TIECSocketEvent = procedure (Sender: TObject; Socket: TIEC104Socket) of object;
TIECSocketType= (TIECUnkwon,TIECClient,TIECServer,TIECMonitor);
TIEC104LinkStatus= (IECOFF,IECINIT,IECStartDT,IECStopDT);

TRTXEvent = procedure(Sender: TObject;const Buffer:array of byte;count :integer) of object;

TIEC104Timerset = record
    T0:        integer;  //time to restart IP socket
    T1:        integer;  //Time untill my sended information has to be confirned
    T2:        integer;  //time befor sending confirmation
    T3:        integer;  //Pollingtime;
    k:         integer;  //max receive I_frames before confirm
    w:         integer;  //max send I_frames befor i expect a confirmation
 end;

TIECStatusinfo = Record
  asdu:   word;
  obj:    word;
  end;

{ TIEC104Socket }

TIEC104Socket = class(TObject)
  private
    Fth:TThreadID;
//    Fcli: Tcliexecute;
    FName:    String;
    FIECSocketType: TIECSocketType;
    FID:      integer;
    FRun :    Boolean;
    FLinkStatus: TIEC104LinkStatus;
    FTimerSet:   TIEC104Timerset;
    FcounterSet: TIEC104Timerset;
    FAPDU_tx:   array[0..255]of byte;
    Fip_tx:   array[0..5000]of byte;
    IPinitpos :Integer;
    FIP_bufpos: integer;
    FAPDU_TX_Count:integer;
    FAPDU_Rx:   array[0..255]of byte;
    FAPDU_RX_Count:integer;
    FAPDUlength:      integer;
    FASDUlength:      integer;
//    FTIFilter:  byte; // Type Identification filter;
    FVR:        integer;  // Receive variable
    FVS:        integer;  // send variable
    FStatus:    TIECStatusinfo;
    Flogger:Tlogger;
    FOnRXData: TRTXEvent;
    FOnTXData: TRTXEvent;
    FOn0nTimerEvent:  TNotifyEvent;
    FbSocket: TTCPBlockSocket;
    Fip_rx_count:integer;
    Fip_tx_count:integer;
    Fsend: boolean;
    Fwrite:boolean;
    procedure confirm;
    procedure setName(AValue: String);
    procedure log(l:TLevel;s:String);

  protected
    LogRStr:String;
    LogSStr:String;
    Procedure irq(Sender: TObject);
//    procedure connect(Sender: TObject;Socket: TCustomWinSocket);
    procedure DisConnect;
//    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure readAPDU(ip_rx:array of byte);
    procedure readAPCI;
    procedure ReadASDU;
    procedure update_VS;
//    procedure setActive(val:boolean);
    procedure setLinkStatus(val:TIEC104LinkStatus);
    procedure writeStream;
    procedure sendStream;
    procedure send;
    procedure SendStartAck;
    procedure SendStopAck;
    procedure SendPoll;
    procedure SendPollAck;
    procedure SendQuitt;
//    procedure settimeractive(val:boolean);
    procedure setSocketType(s:TIECSocketType);
  public
    constructor Create; overload;
//    constructor Create(Loggerinstance:String); overload;
    destructor destroy; override;
    procedure Start;
    procedure Stop;
    procedure SendStart;
    procedure SendStop;
    Procedure DecodeStream(ip_rx:array of byte);
//    procedure readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);
    procedure sendBuf(buf:array of byte; count:integer;direct:boolean);
    function sendHexStr(var s:string):integer;
//    procedure CLIExecute(s:string;result:TCLIResult);
    property Name:String read FName write setName;
    property SocketType:TIECSocketType read FIECSocketType write setSocketType;
    property Socket:TTCPBlockSocket read FbSocket write FbSocket;
    property Logger:Tlogger read Flogger write Flogger;
    property active:boolean read FRun;
    property StreamCount:integer read Fip_rx_count write Fip_rx_count;
    property RXCount: Integer read FVR;
    property TXCount: Integer read FVS;
    property onRXData: TRTXEvent read FonRXData write FonRXData;
    property onTXData: TRTXEvent read FonTXData write FonTXData;
    property onOnTimerEvent: TNotifyEvent read Fon0nTimerEvent write Fon0nTimerEvent;
    property ASDULength: integer read FASDULength write FASDULength;
    property ID: integer read FID write FID;
//    property TIFilter: byte read FTIFilter write FTIFIlter;
    property TimerSet: TIEC104TimerSet read FtimerSet write FTimerSet;
//    property Status: TIECStatusInfo read FStatus write FStatus;
    property linkStatus: TIEC104LinkStatus read FLinkStatus write setLinkstatus;
  published
  end;

function DefaultTimerset: TIEC104Timerset;

const
  off=90000000;

implementation

var
  shutdown:Boolean=false;
  sockcount: integer =1;

const
  ID_104=$68;
  S_Frame=$01;U_Frame=$03;I_Frame=$00;//Unknown=-1;
  UStart=$07; UStart_ack=$0B;  // 0000 0111   0000 1011
  UStop=$13;  UStop_ack=$23;   // 0001 0011   0010 0011
  Utest=$43;  Utest_ack=$83;   // 0100 0011   1000 0011

function BufferToHexStr(const buf:array of byte;count:integer):string;
   var
     x:integer;
  begin
   result:='';
   for x:=0 to count-1 do
      begin
      result:=result+inttohex(buf[x],2)+' ';
 //     inc(buf);
      end;
 end;

function DefaultTimerset: TIEC104Timerset;
  begin
    result.T0:=30000;
    result.T1:=15000;
    result.T2:=10000;
    result.T3:=20000;
    result.k:=12;
    result.w:=8;
  end;

function runTimer(p: Pointer): ptrint;
var
  sock: TIEC104Socket;
begin
  sock := TIEC104Socket(p);
  while (sock.Frun) do
    begin
    sock.irq(sock);
    sleep(500);
    end;
  sock.log(debug,'THREAD END');
end;

{ TIEC104Socket }
//+++++++++++++++++++++++++++++++++++++
 //   TIECSocket    implementation
 //+++++++++++++++++++++++++++++++++++++

 constructor TIEC104Socket.Create;
 //constructor TIEC104Socket.Create(settings:TIEC104Settings);
 begin
  inherited Create;
  inc(sockcount);
  FIECSocketType:= TIECUnkwon;
  FAPDU_RX_count:=-1;
  FIP_TX_count:=0;
  Fvr:=0;
  FVS:=0;
//  FTIFilter:=0;
  FLinkStatus:=IECOFF;
  FtimerSet:=DefaultTimerset;
  FcounterSet.T1:=OFF;
//  FCLI := nil;
 end;

 Destructor TIEC104Socket.destroy;
 begin
//  log(DEBUG,'Destroy');
  stop; //  WaitsForTimerThreadTerminate;
  inherited destroy;
  log(DEBUG,'Destroyed');
 end;

{
procedure TIEC104Socket.CLIExecute(s:string;result:TCLIResult);
begin
 if (FCLI<>nil) then
    Fcli.ParseCMD(nil,s,result)
 else
   log(error,'CLI-Not assinged!');
end;
}

procedure TIEC104Socket.log(l:TLevel;s:String);
begin
 if logger <> nil then
      begin
//      s:='SOCK_'+inttostr(Fid)+'_'+s;
      logger.Log(l,Fname+' '+s);     //
      end;
end;

procedure TIEC104Socket.confirm;
begin
   case FAPDU_RX[2] of
       UStart: begin
               Fcounterset.k:=0;
               Fcounterset.w:=0;
//               FVR:=0;
//               FVS:=0;
               Fcounterset.T1:=off;
               Fcounterset.T2:=off;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3; //polltime;
               sendStartAck;
               LinkStatus:=iecStartDT;
//               FLinkactive:=true;
//               StatusToDataOut;
               LogRStr:='uStaA';
               end;
       UStart_ack: begin
               Fcounterset.k:=0;
               Fcounterset.k:=0;
//               FVR:=0;
//               FVS:=0;
               Fcounterset.T1:=off;
               Fcounterset.T2:=off;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3; //polltime;
//               FLinkactive:=true;
               LinkStatus:=iecStartDT;
//               StatusToDataOut;
               LogRStr:='uStaC';
              end;
       Utest: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               sendPollAck;
               Fcounterset.T3:=datetimetotimestamp(now).time+FTimerset.T3;
               LogRStr:='uTstA';
               end;
       Utest_ack: begin
               if FLinkStatus=IECInit then
                  LinkStatus:=iecStopDT;
               Fcounterset.T1:=off;
               LogRStr:='uTstC';
               end;
       Ustop: begin
               sendStopAck;
//               Flinkactive:=False;
               LinkStatus:=iecStopDT;
               LogRStr:='uStoA';
               end;
      UStop_ack:begin
                LinkStatus:=iecStopDT;
                LogRStr:='uTstC';
                end;
    end;
end;

procedure TIEC104Socket.setName(AValue: String);
begin
  if FName=AValue then Exit;
  FName:=AValue;
//  log.Name:=FName;
end;

procedure TIEC104Socket.irq(Sender: TObject);
var
 t0:integer;

begin
// logger.debug('IRQ');
t0:=datetimetotimestamp(now).time;

// Try reconnect after t0
if (t0 > FcounterSet.T0) then
   begin
   if assigned(Fon0nTimerEvent) then
       Fon0nTimerEvent(self);
   end;

 //Trace('now'+inttostr(t0)+'_T1_'+inttostr(Fcounterset.T1));
//Trace('_(T1)_'+inttostr(Fcounterset.T1-t0));
if (t0>Fcounterset.T1) then //Time untill my sendings has to be confirned is expired
   if (FLinkStatus<>IECINIT) then
       begin
       log(WARN,'_Missing confirmation (T1)_should close IP connection');
       Fcounterset.T1:=off;
       end;

//if (t0>Fcounterset.T2)and FLinkactive then
if (t0>Fcounterset.T2)and (FLinkStatus=iecStartDT) then
//Time i should send confirnetions is expired
   begin
   log(DEBUG,'(T2) expired send Quitt');
   sendQuitt;
   end;

if (t0>Fcounterset.T3) and (Flinkstatus<>IECINIT) then
   begin
   if (FIECSocketType=TIECClient) then
      begin
      log(DEBUG,'(T3) expired send poll');
      Sendpoll;
      Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1; //wait for poll_ack;
      Fcounterset.T3:=datetimetotimestamp(now).time+Ftimerset.T3; //reload next polltime;
      end;
   if (FIECSocketType=TIECServer) then
      begin
      log(WARN,'Missing Polling fron client(T3)');
      Fcounterset.T3:=datetimetotimestamp(now).time+Ftimerset.T3; //polltime;
      end;
   end;

if Fsend= true then
     send;

// Fwrite idicates if some Data are writen in senstream (procedure writestream)
if (Fip_tx_count >0) and (Fwrite=False) then
   sendStream;

if Fcounterset.k  >FTimerset.k then  //too much sendings without ackwolegement
   begin
   log(WARN,'missing confirmation (w)__should close IP connection');
   Fcounterset.k:=0;
   end;
end;

procedure TIEC104Socket.DisConnect;
 begin
if not shutdown then
   if FlinkStatus<>IECOFF then
      begin
      if FlinkStatus<>IECINIT then
 //         log(DEBUG,'Lost Connection to '+FSocket.peerAddress+':'+inttostr(Fsocket.peerPort));
      FlinkStatus:=IECINIT;
      FCounterset.T0:=datetimetotimestamp(now).time+Ftimerset.T0; //reconnecttime;
//      StatusToDataOut(False);
      end;
end;

Procedure TIEC104Socket.DecodeStream(ip_rx:array of byte);
//var
//   IP_bufpos: integer;
begin
 FIP_bufpos:=0;
 while Fip_bufpos < Fip_rx_count do     // there could be moe than 1 APDU in a IP-Stream
    begin
    if (Fip_bufpos >0 ) then
       log(DEBUG,'NEXT APDU');
//    readAPDU(IP_RX,FIP_Bufpos);          //Read 1 IEC_APDU message out of the IP-stream
    readAPDU(IP_RX);          //Read 1 IEC_APDU message out of the IP-stream
    end;

end;


//procedure TIEC104Socket.readAPDU(ip_rx:array of byte;var IP_Bufpos:integer);  //copy 1 IEC message out of the IP-stream
procedure TIEC104Socket.readAPDU(ip_rx:array of byte);  //copy 1 IEC message out of the IP-stream
//var
//   offsetstr,s:string;
begin
 IPinitpos:=FIp_bufPos;
 if ip_rx[FIP_bufpos]=ID_104 then
    begin
    if FAPDU_RX_Count<= -1 then // a new APDU should start
      begin
      FAPDUlength:=ip_rx[Fip_bufpos+1]+2;   //get length of new APDU message in IP stream
      FAPDU_RX_Count:=Fapdulength;         // count how many Bytes are missed for the complet APDU
      end;

//      offsetstr:=inttostr(IP_bufpos);
      repeat
         FAPDU_RX[FAPDUlength-FAPDU_RX_count]:=ip_RX[FIP_bufpos];
         inc(FIP_bufpos);
         dec(FAPDU_RX_count);
      until (FAPDU_RX_count=0)  // End fo IEC message reached
            or (FIP_bufpos = Fip_rx_count);  //end of IP stream reached (Fip_rx_count= length of IP stream)

     if FAPDU_RX_count=0 then  //End fo IEC message reached --> APDU Complet ??
        begin
        logRstr:='';

        readAPCI;
        FAPDU_RX_count:=-1;   // APDU complet reset APDU length counter
        if Fsend then send;
        end      //END APDU complet
     else
        begin       // APDU NOt Yet Complet
        log(WARN,'_!_IP_Stream to short_!_');
        log(DEBUG,'_'+inttostr(FIP_RX_Count)+' IP Stream-Bytes recived');
        log(DEBUG,'_need '+inttostr(FAPDU_RX_Count)+' more bytes from next IP Stream: ');
        end;
     end       // END first byte OK
 else
     begin
     log(FATAL,'APDU NOT starts with Byte $68 idx:'+inttostr(IPinitpos)+' '+BuffertoHexStr(ip_rx[IPinitpos],6)+' ...--> exit');
     Fip_bufpos:=Fip_rx_count;
     end;
end;

procedure TIEC104Socket.ReadASDU;
   var
    tvr:integer;
    x:integer;
    asdu:array[0..249] of byte;
    s:String;
//    res:T104_Res;
   begin
   update_VS;
   tvr:=(FAPDU_RX[2]+FAPDU_RX[3]*256)shr 1;  //read sendsequenc
   if (tvr<>fvr) and (FIECSocketType<>TIECMonitor) then
      begin
      log(ERROR,'Sequenc recived '+inttostr(tvr)+' expect '+inttostr(Fvr));
      fvr:= tvr;  //fix Sequenz value
      end;
   inc(fvr);         //inc incomming since my last confirmation
   inc(Fcounterset.w);

   if Fcounterset.w > FTimerSet.w-1 then
      begin
      Fcounterset.T2:=0;
      Fcounterset.w:=0;
      end;
   if Fcounterset.T2=off then
      Fcounterset.T2:=datetimetotimestamp(now).time+FTimerSet.T2; //quiettimer;
   FASDUlength:=FAPDU_RX[1]-4;

   for x:=0 to FASDUlength-1 do
      asdu[x]:=FAPDU_Rx[x+6];
  //   trace('data recived');
   Fcounterset.T3:=datetimetotimestamp(now).time+FTimerSet.T3; //polltime; //update pollingtime

   if (logger<>nil) and(logger.GetLevel.equals(DEBUG)) then
       begin
       s:=BufferToHexStr(FAPDU_RX,FAPDUlength);
       log(DEBUG,'R'+logRstr+'['+inttostr(FAPDUlength)+'/'+inttostr(IPinitpos)+'] '+s);
       end;
   if ((logger<>nil) and (logger.GetLevel.equals(INFO)) AND (FAPDUlength >6)) then
//         if (FAPDUlength >6) then
       begin
       s:=BufferToHexStr(FAPDU_RX[6],FAPDUlength-6);
       log(INFO,'R['+inttostr(FAPDUlength-6)+'] '+s);
       end;

//TRXEvent = procedure(Sender: TObject;const Buffer,count :integer)
   if assigned(FonRXData) then
        FonRXData(self,ASDU,FASDULength);
end;

procedure TIEC104Socket.update_VS;
var
  tvs:integer;
begin
 tvs:=(FAPDU_RX[4]+FAPDU_RX[5]*256)shr 1; //read confirmation from partner
 if tvs=Fvs then
    begin
    Fcounterset.T1:=off;
    Fcounterset.k:=0;
    end;
end;

procedure TIEC104Socket.readAPCI;
var
   APCI:byte;
   s:String;
begin
  Fsend := false;
  APCI:=FAPDU_RX[2] and $03;
  if APCI=U_Frame then
    begin
    if FIECSocketType<>TIECMonitor then
      confirm;
    end;
  if APCI=S_Frame then
    begin
    update_Vs;
//    LogRStr:='s'+inttostr(Fvr);
    LogRStr:=format('s%.5d',[Fvr]);
    end;
  if (APCI and $01)=I_Frame then
    begin
    readASDU;
    LogRStr:='i'+inttostr(Fvr);
    end
  else
     if (logger<>nil) and(logger.GetLevel.equals(DEBUG)) then
       begin
       s:=BufferToHexStr(FAPDU_RX,6);
       log(DEBUG,'R'+logRstr+'[6/'+inttostr(IPinitpos)+'] '+s);
       end;
end;

procedure TIEC104Socket.start;
begin
  if (not Frun) then
    begin
    Fvr:=0;
    FVS:=0;
    FcounterSet.T0:=off;
    FcounterSet.T1:=off;
    LinkStatus:=IECINIT;
    fth:=BeginThread(@runTimer,Pointer(self));
    if (FIECSockettype = TIECClient) then sendStart;
    Frun:=true;
    end;
end;

procedure TIEC104Socket.stop;
begin
 if (Frun) then
    begin
    LinkStatus:=IECOFF;
    Frun:=false;
//    Socket.CloseSocket;
    WaitForThreadTerminate( Fth,1200);
    end;
end;


function TIEC104Socket.sendHexStr(var s:string):integer;
var
  count:integer;
  cbuf:array[0..100]of char;
  buf:array[0..100]of byte absolute Cbuf;
begin
  while pos(' ',s)<>0 do
     delete(s,pos(' ',s),1);
  if s<>'' then
     begin
     s:=lowercase(s);
     count:=  hextobin(pchar(s),cbuf,100);
//     trace(inttostr(Count));
     if count >0 then
         begin
         sendbuf(buf,count,true);
         s:=BufferToHexStr(buf,count);
         end;
     end;
  result:=count;
end;

//procedure TIEC104Socket.sendBuf(var buf: array of byte; count:integer);
procedure TIEC104Socket.sendBuf(buf: array of byte; count:integer;direct:boolean);
var
   tvs,tvr:word;
   i:integer;
begin
  tvs:=Fvs shl 1;
  tvr:=Fvr shl 1;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=count+4;
  FAPDU_TX[2]:=tvs mod 256;
  FAPDU_TX[3]:=tvs div 256;
  FAPDU_TX[4]:=tvr mod 256;
  FAPDU_TX[5]:=tvr div 256;
  FAPDU_TX_count:=count+6;

  for i:=0 to count-1 do
     FAPDU_tx[6+i]:=buf[i];

  FAPDU_TX_count:=count+6;
  inc(Fvs);      //variable send
  inc(Fcounterset.k); //counter sended messages
  Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1;

//  Trace('now'+inttostr(datetimetotimestamp(now).time)+'_(T1)_'+inttostr(Fcounterset.T1));
  if direct then
    send
  else
    writestream;
end;

procedure TIEC104Socket.writestream;
var
  s:String;
begin
 Fwrite:=True;  // Block timmer straemsend  action while update stream

// LogSStr:='i'+inttostr(Fvs);
LogSStr:=Format('i%.5d',[Fvs]);

//  if (logger.GetLevel.equals(INFO)) AND (FAPDU_TX_Count >6) then
  if  (FAPDU_TX_Count >6) then
      begin
      s:=BufferToHexStr(FAPDU_TX[6],FAPDU_TX_Count-6);
      log(INFO,'S['+inttostr(FAPDU_TX_Count-6)+'] '+s);
      end;
 //  if (logger.GetLevel.equals(DEBUG)) then
 //     begin
      s:=BufferToHexStr(FAPDU_TX,FAPDU_TX_Count);
      log(DEBUG,'S'+logSstr+'['+inttostr(FAPDU_TX_Count)+'/'+inttostr(Fip_TX_Count)+'] '+s);
//      end;
 move(FAPDU_TX,FIP_TX[Fip_TX_Count],FAPDU_TX_Count);
 Fip_TX_Count:=Fip_TX_Count+FAPDU_TX_Count;
 if  Fip_TX_Count>1000 then
    sendstream;

 Fwrite:=False;
end;

procedure TIEC104Socket.sendStream;
var
  s:String;
begin
 if Fbsocket<>nil then
     Fbsocket.SendBuffer(@Fip_TX,Fip_TX_Count);
//if Fsocket<>nil then
//   Fsocket.Send(Fip_TX,Fip_TX_Count);

// Logging
log(DEBUG,'Send IP_TX_Length: '+inttostr(Fip_tx_Count));
Fip_TX_Count:=0;

 if (FAPDU_TX_Count > 6) and assigned(FonTXData) then
        FonTXData(self,FAPDU_TX[6],FAPDU_TX_Count-6);
end;


procedure TIEC104Socket.send;
var
  s:String;
begin
 if (logSstr='uQuitt') then LogSStr:=Format('i%.5d',[Fvs]);
if (logger<>nil) and (logger.GetLevel.equals(DEBUG)) then
   begin
    s:=BufferToHexStr(FAPDU_TX,FAPDU_TX_Count);
    log(DEBUG,'S'+logSstr+'['+inttostr(FAPDU_TX_Count)+'] '+s);
   end;

//if  (FAPDU_TX_Count >6) then
if (logger<>nil) and (logger.GetLevel.equals(INFO))
    and (FAPDU_TX_Count >6) then
    begin
    s:=BufferToHexStr(FAPDU_TX[6],FAPDU_TX_Count-6);
    log(INFO,'S['+inttostr(FAPDU_TX_Count-6)+'] '+s);
    end;
//if Fsocket<>nil then
  // Fsocket.Send(FAPDU_TX,FAPDU_TX_Count);
if Fbsocket<>nil then
    Fbsocket.SendBuffer(@FAPDU_TX,FAPDU_TX_Count);

 Fsend:= false;

 if (FAPDU_TX_Count > 6) and assigned(FonTXData) then
        FonTXData(self,FAPDU_TX[6],FAPDU_TX_Count-6);
end;

procedure TIEC104Socket.SetLinkstatus(val:TIEC104LinkStatus);
begin
if (val<>Flinkstatus) then
   begin
   FLinkStatus:=val;
//   if assigned(FOnLinkEvent) then
//       FOnlinkEvent(self,FLinkStatus);
   end;
end;

procedure TIEC104Socket.SendQuitt;
var
   tvr:integer;
begin
tvr:=Fvr shl 1;
FAPDU_TX[0]:=ID_104;
FAPDU_TX[1]:=$04;
FAPDU_TX[2]:=s_frame;
FAPDU_TX[3]:=$00;
FAPDU_TX[4]:=tvr mod 256;
FAPDU_TX[5]:=tvr div 256;
FAPDU_TX_count:=6;
Fcounterset.w:=0;
Fcounterset.T2:=off;
logSstr:='s'+inttostr(Fvr);
logSstr:='uQuitt';
Fsend:=true;
end;

Procedure TIEC104Socket.SendStart;
  begin
  Fvr:=0;
  FVS:=0;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustart;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  Fcounterset.T1:=datetimetotimestamp(now).time+Ftimerset.T1; //wait for Start_ack;
  logSstr:='uStarA';
  Fsend:=true;
end;

Procedure TIEC104Socket.SendStartAck;
  begin
  Fvr:=0;
  FVS:=0;
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustart_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  logSstr:='uStarC';
  Fsend:=true;
  end;

Procedure TIEC104Socket.SendStopAck;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustop_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  logSstr:='uStopC';
  Fsend:=true;
  end;

Procedure TIEC104Socket.SendStop;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Ustop;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  logSstr:='uStopA';
  Fsend:=true;
  end;

Procedure TIEC104Socket.Sendpoll;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Utest;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  logSstr:='uTstA';
  Fsend:=true;
  end;

Procedure TIEC104Socket.SendpollAck;
  begin
  FAPDU_TX[0]:=ID_104;
  FAPDU_TX[1]:=$04;
  FAPDU_TX[2]:=Utest_ack;
  FAPDU_TX[3]:=$00;
  FAPDU_TX[4]:=$00;
  FAPDU_TX[5]:=$00;
  FAPDU_TX_count:=6;
  logSstr:='uTstC';
//  send;
  Fsend:=true;
  end;


procedure TIEC104Socket.setSocketType(s: TIECSocketType);
begin
 if s= TIECServer then
    Ftimerset.T3:=Ftimerset.T0;
 FIECsockettype:=s;
end;

end.

