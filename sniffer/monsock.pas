unit monsock;

{ Magenta Systems Internet Packet Monitoring Components

Magenta Systems Monitor Socket ICS Component.
Updated by Angus Robertson, Magenta Systems Ltd, England, v1.1 29th October 2005
delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/
Copyright Magenta Systems Ltd

TMonitorSocket needs WSocket from François PIETTE internet component suite
http://www.overbyte.be/

Note this component uses RAW sockets, which are only available in Windows 2000
and later, and only for administrator level users.

Also note Windows 2000 SP4 and Windows XP SP2 appear to ignore most sent packets,
but Windows 2003 SP1 correctly captures all (or most) sent packets. 

Microsoft is also restricting the use of RAW sockets in recent service packs,
XP SP2 stops raw sockets being used to send data but receive still works.

}

{$mode Delphi}{$H+}
//{$mode objfpc}

interface

uses
  Windows, Messages, Classes, SysUtils, WSocket, Winsock,
   Packhdrs, TLoggerUnit;
//  MagClasses, Magsubs1 ;

type


  TMonitorSocket = class(TCustomWSocket)
  protected
      Flogger : Tlogger;
      FAddrMask: string ;
//      FIgnoreIPList: TFindList ;
      FInAddr: TInAddr ;
      FInAddrMask: TInAddr ;
      FIgnoreData: boolean ;
      FIgnoreLAN: boolean ;
      FTotRecvBytes: int64 ;
      FTotSendBytes: int64 ;
      FTotRecvPackets: integer ;
      FTotSendPackets: integer ;
      FOnPacketEvent: TPacketEvent;
      procedure MonDataAvailable (Sender: TObject; ErrCode: Word) ;
  public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure StartMonitor;
      procedure StopMonitor;
  protected
  published
      property logger :Tlogger read FLogger write Flogger;
      property Addr ;
      property AddrMask: string         read FAddrMask
                                        write FAddrMask ;
      property IgnoreData: boolean      read FIgnoreData
                                        write FIgnoreData ;
      property IgnoreLAN: boolean       read FIgnoreLAN
                                        write FIgnoreLAN ;
      property TotRecvBytes: int64      read FTotRecvBytes ;
      property TotSendBytes: int64      read FTotSendBytes ;
      property TotRecvPackets: integer  read FTotRecvPackets ;
      property TotSendPackets: integer  read FTotSendPackets ;
      property OnDataAvailable ;
      property OnPacketEvent: TPacketEvent read  FOnPacketEvent
                                           write FOnPacketEvent;
  end;

implementation

function BufferToHexStr(const buf:Pchar;count:integer):string;
 var
   x:integer;
   w:word;
begin
 result:='';
 for x:=0 to count-1 do
    begin
    w:=word(buf[x]);
    result:=result+inttohex(w,2)+' ';
//     inc(buf);
    end;
end;

procedure Register;
begin
    RegisterComponents('FPiette', [TMonitorSocket]) ;
end ;

constructor TMonitorSocket.Create(AOwner: TComponent);
begin
    logger := TLogger.GetInstance('RawMon');
    ReqVerHigh := 2 ;
    ReqVerLow := 2 ;
    FIgnoreData := false ;
//    FIgnoreIPList := TFindList.Create ;
//    FIgnoreIPList.Sorted := true ;
    inherited Create(AOwner);
//    onDataAvailable := @MonDataAvailable ;
    onDataAvailable := MonDataAvailable ;
end ;

destructor TMonitorSocket.Destroy;
begin
//    FreeAndNil (FIgnoreIPList) ;
    inherited Destroy;
end ;

// called by TFindList for sort and find comparison of file records

function CompareFNext (Item1, Item2: Pointer): Integer;
// Compare returns < 0 if Item1 is less than Item2, 0 if they are equal
// and > 0 if Item1 is greater than Item2.
begin
    result := 0 ;
    if longword (Item1) > longword (Item2) then result := 1 ;
    if longword (Item1) < longword (Item2) then result := -1 ;
end ;


procedure TMonitorSocket.MonDataAvailable (Sender: TObject; ErrCode: Word) ;
var
    s:String;
    hdrlen, iploc: integer ;
    packetbuff: array [0..2000] of char ;
    iphdr: PHdrIP;
    tcphdr: PHdrTCP;
    udphdr: PHdrUDP;
    PacketInfo: TPacketInfo ;  // the data we return in the event


    procedure GetDataByOffset (offset: integer) ;
    var
        datastart: PChar ;
        u:u_short;
    begin
        datastart := PChar (PChar (iphdr) + offset) ;
        with PacketInfo do
        begin
//            u:= iphdr.tot_len;
//            u:= ntohs (iphdr.tot_len);
            if ntohs (iphdr.tot_len) < Sizeof (packetbuff) then
                DataLen := ntohs (iphdr.tot_len) - offset
            else
                DataLen := Sizeof (packetbuff) - offset;
            if DataLen = 0 then exit ;
            if FIgnoreData then exit ;
            SetLength (DataBuf, DataLen) ;
            Move (datastart^, ByteBuff [0], DataLen) ;
//            Move (datastart^, DataBuf [0], DataLen) ;
            //            Move (datastart^, DataBuf [1], DataLen) ;
        end ;
    end;

begin
    FillChar (PacketInfo, Sizeof(PacketInfo), 0) ;
    with PacketInfo do
    begin
        PacketLen := Receive (@packetbuff [0], SizeOf (packetbuff)) ;

        if PacketLen <= 0 then exit ;
        inc (PacketLen, OFFSET_IP) ;    // add 14-byte ethernet header length
        EtherProto := PROTO_IP ;         // socket only returns IP
        iphdr := PHdrIP (@packetbuff);  // IP header is start of raw packet
        AddrSrc := iphdr.saddr ;        // 32-bit IP addresses
        AddrDest := iphdr.daddr ;
        SendFlag := (FInAddr.S_addr = AddrSrc.S_addr) ;  // did we sent this packet
        ProtoType := iphdr.protocol ;   // TCP, UDP, ICMP
//        PacketDT := NowPC ;  // time using performance counter
        PacketDT := Now();  // time using performance counter



     // check if both IP on the same subnet as the LAN mask, if so ignore
        if (FInAddrMask.S_addr <> 0) and FIgnoreLAN then
        begin
            if (AddrSrc.S_addr AND FInAddrMask.S_addr) =
                            (AddrDest.S_addr AND FInAddrMask.S_addr) then exit ;
            if AddrDest.S_addr = 0 then exit ;
        end ;

     // increment global traffic counters
        if SendFlag then
        begin
            inc (FTotSendBytes, packetlen) ;
            inc (FTotSendPackets) ;
        end
        else
        begin
            inc (FTotRecvBytes, packetlen) ;
            inc (FTotRecvPackets) ;
        end ;
     s:=('['+inttostr(PacketLen)+'] ');
    // check protocol and find ports and data
        if Assigned (FOnPacketEvent) then
        begin
            DataBuf := '' ;
            hdrlen := GetIHlen (iphdr^) ;
            if ProtoType = IPPROTO_ICMP then
            begin
                IcmpType := PByte (PChar (iphdr) + hdrlen)^ ;
                GetDataByOffset (hdrlen) ;
                s := s+'_ICMP';
            end
            else
            begin
                if ProtoType = IPPROTO_TCP then
                begin
                    tcphdr := PHdrTCP (PChar(iphdr) + hdrlen) ;
                    PortSrc := ntohs (tcphdr.source) ;
                    PortDest := ntohs (tcphdr.dest) ;
                    TcpFlags := ntohs (tcphdr.flags) ;
                    GetDataByOffset (hdrlen + GetTHdoff (tcphdr^)) ;
                    s := s+'_TCP';
                end;
                if ProtoType = IPPROTO_UDP then
                begin
                    udphdr := PHdrUDP (PChar (iphdr) + hdrlen) ;
                    PortSrc := ntohs (udphdr.src_port) ;
                    PortDest := ntohs (udphdr.dst_port) ;
                    GetDataByOffset (hdrlen + Sizeof (THdrUDP));
                    s := s+'_UDP';
                end;
            end;
        end ;

      if PacketLen < 8 then
          s:=s+'  DATA  '+inttostr(PacketLen)+': '+ BufferToHexStr(@packetbuff [0],PacketLen)
      else
          s:=s+'  DATA  '+inttostr(PacketLen)+' '+ BufferToHexStr(@packetbuff [0],8)+'..';
       logger.debug(s+'  ['+inttostr(DataLen)+']');
//       logger.debug('receive '+inttostr(Datalen)+' Bytes for port '+inttostr(PortSrc));

      if ProtoType = IPPROTO_TCP then
          FOnPacketEvent (Self, PacketInfo) ;
    end ;
end ;

procedure TMonitorSocket.StartMonitor;
begin
    FInAddr := StrToIP (Addr) ;  // keep 32-bit listen IP address
    FAddrMask := Trim (FAddrMask) ;
    if Length(FAddrMask) = 0 then
        FInAddrMask.S_addr := 0
    else
        FInAddrMask := StrToIP (FAddrMask) ; // and IP mask
    FTotRecvBytes := 0 ;
    FTotSendBytes := 0 ;
    FTotRecvPackets := 0 ;
    FTotSendPackets := 0 ;
    Port := '0' ;  // all ports
    Proto := 'raw_ip' ;
//    PerfFreqAligned := false ;  // force performance counter clock to align with system clock
    ComponentOptions := [wsoSIO_RCVALL] ;  // receive all packets on this address
    Listen ;
end ;

procedure  TMonitorSocket.StopMonitor;
begin
    Close ;
end ;


end.
