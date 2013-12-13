unit WPcap;

//{$mode delphi}
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils,
  WinSock, Windows, sockets,
  Pcap,    packhdrs, TLoggerUnit;

type

  // [Gotten from LIBPCAP\ntddpack.h]
  // Data structure to control the device driver
  PPACKET_OID_DATA = ^TPACKET_OID_DATA;
  TPACKET_OID_DATA = packed record
    Oid   : LongWord;               // Device control code
    Length: LongWord;               // Length of data field
    Data  : Pointer;                // Start of data field
  end;

  TWPcapThread = class ;  // forward declaration

  { TWPcap }

  TWPcap = class(TComponent)
  protected
    Flogger :TLogger;
    FMonAdapter:TPcap_If;
//    FAdapterMac: array[0..5]of byte;
    FAdapterMac: TMacAddr;
    FWPcapThread : TWPcapThread;
    FConnected   :boolean;

    FTotRecvPackets: integer ;
    FTotSendPackets: integer ;
    FTotPackets    : Integer;
    FOnPacketEvent: TPacketEvent;

      procedure ThreadTerminate (Sender: TObject);
      procedure MonDataAvailable (const Header: Ppcap_pkthdr ; const PackPtr: Pchar) ;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Start;
    procedure Stop;
//  published
    property MonAdapter:TPcap_If read FMonAdapter write FMonAdapter;
//    property Log :Tlog read  Flog write FLog;
    property Logger :TLogger read  Flogger write FLogger;
//    property Header :TPcap_Pkthdr read  FPkthdr write FPkthdr;
    property connected :Boolean read  FConnected write FConnected;
    property TotRecvPackets: integer  read FTotRecvPackets ;
    property TotSendPackets: integer  read FTotSendPackets ;
    property OnPacketEvent: TPacketEvent read  FOnPacketEvent
                                         write FOnPacketEvent;
  end;

  { TWPcapThread }

  TWPcapThread = class(TThread)
  private
      Fp:PPcap;
      FWPcap     : TWPcap ;
      Fcallback  : TPCapHandler;
      FHeader    : PPcap_Pkthdr;
      Fbuf       : Pchar;
      procedure GetPackets ;
  public
      procedure Execute; override;
  end;

  Padapter = ^Tadapter;
  Tadapter = packed Record
    hFile        : LongWord;
    SymbolicLink : array [0..63] of char;
  end;

function AdapterDescList:TStringlist;
function getAdapter(index:integer):TPcap_If;
function getmacStr(MonAdapter:TPcap_If):string;

Function PacketRequest( AdapterObject:Padapter;isSet:Longbool;OidData:
                        PPacket_oid_data ):Longbool;cdecl ; external 'Packet.dll';
Function PacketOpenAdapter(AdapterName:Pchar) : PAdapter; cdecl ; external 'Packet.dll';

var
  errorbuf : string;
//  if_list:TWPcapAdapterlist;
//  i:integer;

implementation

//uses
//  packet;

var
   next_if : Ppcap_if;
   pcap_if: TPcap_If;
   if_array:array[0..10] of TPcap_If;
   if_list:TStringList;
   MACAddr :array[0..5] of byte;
   i:integer;

function AdapterDescList: TStringlist;
begin
  result:=if_list;
end;

//------------------------------------------------------------------------------
// Get adaptor MAC address
// Added By Angus Robertson
//------------------------------------------------------------------------------
{function Pcap_GetMacAddress (P: pPcap; var ErrStr:string): TMacAddr ;
var
    OidData: array [0..20] of char ;
    POidData :PPACKET_OID_DATA ;
begin
    FillChar (Result, SizeOf (Result), 0) ;
    ErrStr := '' ;
    if NOT LoadPacketDll then
    begin
        ErrStr:='Cannot load packet.dll';
        exit;
    end;
    FillChar (OidData [0], SizeOf (OidData), 0) ;
    POidData := @OidData ;
    POidData.Oid := OID_802_3_CURRENT_ADDRESS ;
    POidData.Length := 6 ;
    if NOT PacketRequest (P.Adapter, false, POidData) then  // get data, not set it!
    begin
        ErrStr:= 'Failed to get adaptor MAC';
        exit;
    end;
    Move (POidData.Data, Result, SizeOf (Result)) ;
end ;
}

function getAdapter(index:integer): TPcap_If;
begin
  result:=if_array[index];
end;


procedure CaptureCallBack (User: Pointer; const Header: Ppcap_pkthdr ; const PackPtr: Pchar) ; cdecl;
begin
    TWPcapThread (User).FWPcap.MonDataAvailable (Header, PackPtr) ;
end ;

{ TWPcapThread }

procedure TWPcapThread.GetPackets;
begin
  pcap_loop(fp, 0,Fcallback, nil);
end;

procedure TWPcapThread.Execute;
var
  l:Longint;
//  header:PPcap_Pkthdr;
//  Pcap_Pkthdr:TPcap_Pkthdr;
//  buf:array[0..1500]of byte;

begin
  while NOT Terminated do
    begin
//        GetPackets ;
        l:=pcap_next_ex(fp,@Fheader,@Fbuf);
        if l=1 then
           FWPcap.MonDataAvailable (FHeader, Fbuf);
    end;
end;

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

function getmac(MonAdapter:TPcap_If):Pchar;
  const
     OID_802_3_CURRENT_ADDRESS		   = $01010102;
  var
     OidData: TPACKET_OID_DATA;
     pOidData: PPACKET_OID_DATA;
     adapter:Padapter;
begin
  pOidData := @OidData;
  oidData.Oid := OID_802_3_CURRENT_ADDRESS;
  OidData.Length := 6;
  adapter:=PacketOpenAdapter(Pchar(MonAdapter.name));
  if (PacketRequest (adapter, FALSE, pOidData)) then
      begin
         Move (OidData.Data, MACAddr, 6) ;
         result :=@MacAddr;
     end
  else
     result := nil;
end;

function getmacStr(MonAdapter:TPcap_If):string;
var
  x:integer;
begin
  if getmac(MonAdapter)<>nil then
     begin
       for x:=0 to 5 do
         begin
          if x=5 then
             result:=result+inttohex(MACAddr[x],2)
          else
             result:=result+inttohex(MACAddr[x],2)+':';
         end;
     end;
end;

function MACtoStr(p:Pchar):string;
var
  x:integer;
  w:word;
begin
   for x:=0 to 5 do
     begin
     w:=word(p[x]);
     if x=5 then
        result:=result+inttohex(w,2)
     else
        result:=result+inttohex(w,2)+':';
    end;
end;

{ TWPcap }

procedure TWPcap.ThreadTerminate(Sender: TObject);
begin
 logger.info('Thread Terminated');
end;

procedure TWPcap.MonDataAvailable(const Header: Ppcap_pkthdr;const PackPtr: Pchar);
var
   hdrlen, iploc: integer ;
   Pkthdr:TPcap_Pkthdr;
   PacketLen:integer;
   ethernethdr: PHdrEthernet ;
   PacketInfo: TPacketInfo ;  // the data we return in the event
   tcphdr :PHdrTCP;
   iphdr: PHdrIP;
   ipver:byte;
   s:string;

  procedure GetDataByOffset (offset: integer) ;
    var
        datastart: PChar ;
    begin
        datastart := PChar (PChar (iphdr) + offset) ;
        with PacketInfo do
        begin
            if ntohs (iphdr^.tot_len) < (Header^.Len - OFFSET_IP) then
                DataLen := ntohs (iphdr^.tot_len) - offset
            else
                DataLen := Header^.Len - OFFSET_IP - offset;
            if DataLen = 0 then exit ;
            SetLength (DataBuf, DataLen) ;
 //           logger.debug('getDATA  '+inttostr(DataLen));
            Move (datastart^,PacketInfo.ByteBuff[0], DataLen) ;
        end ;
    end;
begin
 Pkthdr:= Header^;
 PacketLen := Header^.Len ;


 if PacketLen <= 0 then exit ;
 ethernethdr := PHdrEthernet (PackPtr) ;
 PacketInfo.EtherProto := ntohs (ethernethdr^.protocol) ;
 s:=('Protokoll : '+GetEtherProtoName(PacketInfo.EtherProto));
 //if PacketLen < 8 then
 //   s:=s+'  DATA  '+inttostr(PacketLen)+': '+ BufferToHexStr(PackPtr,PacketLen)
 //else
 //   s:=s+'  DATA  '+inttostr(PacketLen)+' '+ BufferToHexStr(PackPtr,8)+'..';
 s:=s+' ['+inttostr(PacketLen)+']';

 PacketInfo.EtherSrc := ethernethdr^.smac ;
 PacketInfo.EtherDest := ethernethdr^.dmac ;
 PacketInfo.SendFlag := CompareMem(@FAdapterMAC, @PacketInfo.EtherSrc, SizeOf(MACAddr));
 if PacketInfo.SendFlag then
     inc (FTotSendPackets)
 else
     inc (FTotRecvPackets) ;
 PacketInfo.PacketDT := now();

 //PacketInfo.PortSrc;
 logger.debug(s);
if (PacketInfo.EtherProto = PROTO_IP) then
   begin
     iphdr := PHdrIP(Pchar(PackPtr) + OFFSET_IP) ;  // IP header is past ethernet header
     PacketInfo.AddrSrc := iphdr^.saddr ;        // 32-bit IP addresses
     PacketInfo.AddrDest := iphdr^.daddr ;
//      SendFlag := (FInAddr.S_addr = AddrSrc.S_addr) ;  // did we sent this packet
     PacketInfo.ProtoType := iphdr^.protocol ;   // TCP, UDP, ICMP
//      PacketInfo.ProtoType := iphdr.protocol ;   // TCP, UDP, ICMP
     ipver:=GetIHver(iphdr^);
     hdrlen := GetIHlen (iphdr^) ;
     if (PacketInfo.ProtoType = IPPROTO_TCP)and (ipver=4) then
     begin
         tcphdr := PHdrTCP (PChar(iphdr) + hdrlen) ;
         PacketInfo.PortSrc := ntohs (tcphdr^.source) ;
         PacketInfo.PortDest := ntohs (tcphdr^.dest) ;
         PacketInfo.TcpFlags := ntohs (tcphdr^.flags) ;
//          logger.debug('getdataoffset:  '+inttostr(hdrlen + GetTHdoff (tcphdr^))) ;
         GetDataByOffset (hdrlen + GetTHdoff (tcphdr^)) ;
         logger.Info('['+inttostr(PacketLen)+'] TCPIPData  Port:'+inttoStr(PacketInfo.PortSrc)) ;

         if Assigned (FOnPacketEvent) then
             FOnPacketEvent (Self, PacketInfo) ;
         end;
    end;
end;

constructor TWPcap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  logger := TLogger.GetInstance('WinPcap');
  FTotRecvPackets:=0;
  FTotSendPackets:=0;
  FOnPacketEvent:= nil;
  FConnected:=false;
end;

destructor TWPcap.Destroy;
begin
//  if Activ then
//  flogger.Destroy;
  inherited Destroy;
end;

procedure TWPcap.Start;


var
   p:PPcap;
//   s:string;

begin
  if getmac(FMonAdapter)<>NIL then
    begin
      FAdapterMac:=MACAddr;
      logger.info('Start Monitoring on MAC: '+MactoStr(@FAdapterMac));
    end;

  p:=pcap_open_live(Pchar(FMonAdapter.name),65535,0,100,pchar(errorbuf));
  if p=nil then
    begin
        exit;
    end;

//  proc:=@handler;
  FTotRecvPackets:=0;
  FTotSendPackets:=0;

  FWPcapThread := TWPcapThread.Create (true) ;
  FWPcapThread.FWPcap := Self ;
  FWPcapThread.OnTerminate := @ThreadTerminate ;
  FWPcapThread.FreeOnTerminate := false;
  FWPcapThread.Resume;
  FWPcapThread.Fp := p;

  FConnected := true;
end;

procedure TWPcap.Stop;
begin
 if Assigned (FWPcapThread) then
    begin
        FWPcapThread.Terminate ;
        FWPcapThread.WaitFor ;
        FWPcapThread.Free ;
        FWPcapThread := nil ;
    end ;
   FConnected := false;
end;


initialization
//  if_list := TWPcapAdapterlist.Create;
  if_list := TStringList.Create;

  if pcap_findalldevs(@next_if,Pchar(errorbuf))<>0 then
     begin
         exit;
     end;
  i:=0;
  while  next_if<>nil do
    begin
      pcap_if:=next_if^;    // assing  TPCap_if address
      if_array[i]:=pcap_if;
//      log.info(buffertohexStr(pAddr,6));
      if pchar(pcap_if.description)='' then
         pchar(pcap_if.description):='??';
      if_list.Add(pchar(pcap_if.description)+'  MAC: '+getMacStr(pcap_if));
      next_if:= pcap_if.next;
      inc(i);
    end;


finalization
//   pcap_freealldevs(@if_array[0]);
   freeandnil(if_List);
end.

