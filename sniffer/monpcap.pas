unit monpcap;

{ Magenta Systems Internet Packet Monitoring Components

Magenta Systems Monitor WinPCAP Component.
Updated by Angus Robertson, Magenta Systems Ltd, England, v1.1 31st October 2005
delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/
Copyright Magenta Systems Ltd

This module requires the WinPcap (windows packet library) device driver package
to installed, from http://www.winpcap.org/.  It has been tested on Windows 2000,
XP and 2003, it may work on Windows 9x but is untested.
Use of the latest WinPcap version 3.1 5th August 2005 is strongly recommended,
but the component also supports WinPcap 3.0 10 February 2003.

WinPcap for NT4 and later comprises packet.dll, wanpacket.dll, wpcap.dll. npf.sys.

The Delphi conversion for packet.dll in pcap.pas and packet32 is by Lars Peter
Christiansen, http://www.nzlab.dk, but modified by Magenta Systems from static
linkage to dynamic DLL loading to allow the application to load without the DLL
and to fix problems reading the adaptor list 



}

interface

uses
  Windows, Messages, Classes, SysUtils, Packhdrs, Winsock,
  Pcap, Packet32, Bpf;
//  MagClasses ;

type

  TPcapThread = class ;  // forward declaration 

  TMonitorPcap = class(TComponent)
  protected
      FLastError: string ;
      FAddr: string ;
      FAddrMask: string ;
//      FIgnoreIPList: TFindList ;
      FInAddr: TInAddr ;
      FInAddrMask: TInAddr ;
      FIgnoreData: boolean ;
      FIgnoreLAN: boolean ;
      FIgnoreNonIP: boolean ;
      FPromiscuous: boolean ;
      FTotRecvBytes: int64 ;
      FTotSendBytes: int64 ;
      FTotRecvPackets: integer ;
      FTotSendPackets: integer ;
      FDriverVersion: string ;
      FPacketVersion: string ;
      FOnPacketEvent: TPacketEvent ;
//      FPcapHandle: PPCAP ;        // control record handle
      FPcapThread: TPcapThread ;  // read packet thread
      FAdapterNameList: TStringList;  // ethernet adapters internal names
      FAdapterDescList: TStringList;  // ethernet adapters descriptions
      FMonAdapter: string ;       // adapter to monitor
      FConnected: boolean ;       // are we connected to PCap driver
      FAdapterMac: TMacAddr ;
      FLocalBiasUTC: TDateTime ;
      function GetAdapters: boolean ;
      procedure ThreadTerminate (Sender: TObject);
      procedure MonDataAvailable (const Header: Ppcap_pkthdr ; const PackPtr: Pchar) ;
  public
      FPcapHandle: PPCAP ;        // control record handle
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;
      procedure StartMonitor;
      procedure StopMonitor;
      function GetIPAddresses (AdapterName: string ;
                                IPList, MaskList, BcastList: TStringList): integer ;
  published
      property AdapterNameList: TStringList read FAdapterNameList ;
      property AdapterDescList: TStringList read FAdapterDescList ;
      property DriverVersion: string    read FDriverVersion ;
      property PacketVersion: string    read FPacketVersion ;
      property MonAdapter: string       read FMonAdapter
                                        write FMonAdapter ;
      property Connected: boolean       read FConnected ;
      property LastError: string        read FLastError ;
      property Addr: string             read FAddr
                                        write FAddr ;
      property AddrMask: string         read FAddrMask
                                        write FAddrMask ;
      property IgnoreData: boolean      read FIgnoreData
                                        write FIgnoreData ;
      property IgnoreLAN: boolean       read FIgnoreLAN
                                        write FIgnoreLAN ;
      property IgnoreNonIP: boolean     read FIgnoreNonIP
                                        write FIgnoreNonIP ;
      property Promiscuous: boolean     read FPromiscuous
                                        write FPromiscuous ;
      property TotRecvBytes: int64      read FTotRecvBytes ;
      property TotSendBytes: int64      read FTotSendBytes ;
      property TotRecvPackets: integer  read FTotRecvPackets ;
      property TotSendPackets: integer  read FTotSendPackets ;
      property OnPacketEvent: TPacketEvent read  FOnPacketEvent
                                           write FOnPacketEvent;
  end;

  TPcapThread = class(TThread)
  private
      FMonitorPcap: TMonitorPcap ;
      procedure GetPackets ;
  public
      procedure Execute; override;
  end;

implementation

procedure Register;
begin
    RegisterComponents('FPiette', [TMonitorPcap]) ;
end ;

function GetLocalBiasUTC: Integer;
var
    tzInfo : TTimeZoneInformation;
begin
    case GetTimeZoneInformation(tzInfo) of
    TIME_ZONE_ID_STANDARD: Result := tzInfo.Bias + tzInfo.StandardBias;
    TIME_ZONE_ID_DAYLIGHT: Result := tzInfo.Bias + tzInfo.DaylightBias;
    else
        Result := tzInfo.Bias;
    end;
end;

procedure CaptureCallBack (User: Pointer; const Header: Ppcap_pkthdr ; const PackPtr: Pchar) ;
begin
    TPcapThread (User).FMonitorPcap.MonDataAvailable (Header, PackPtr) ;
end ;

procedure TPcapThread.GetPackets ;
var
 p:ppcap;
begin
    p:=FMonitorPcap.FPcapHandle;
//    Pcap_Read (FMonitorPcap.FPcapHandle, 0, CaptureCallBack, Pointer (Self)) ;
    Pcap_Read (p, 0, CaptureCallBack, Pointer (Self)) ;
//   Pcap_Read (FMonitorPcap, 0, CaptureCallBack, Pointer (Self)) ;
end ;

procedure TPcapThread.Execute;
begin
    if NOT Assigned (FMonitorPcap) then exit ;
    if FMonitorPcap.FPcapHandle = Nil then exit ;
//    PacketSetReadTimeout (FMonitorPcap.FPcapHandle.Adapter, 100) ;
    while NOT Terminated do
    begin
        GetPackets ;
    end;
end ;

procedure TMonitorPcap.ThreadTerminate (Sender: tobject);
begin
    FConnected := false ;
    Pcap_Close (FPcapHandle) ;
    FPcapHandle := Nil ;
end;

constructor TMonitorPcap.Create(AOwner: TComponent);
begin
    FIgnoreData := false ;
//    FIgnoreIPList := TFindList.Create ;
//    FIgnoreIPList.Sorted := true ;
    FAdapterDescList := TStringList.Create ;
    FAdapterNameList := TStringList.Create ;
    FLastError := '' ;
    FPcapHandle := Nil ;
    FConnected := false ;
    FDriverVersion := Pcap_GetDriverVersion ;
    FPacketVersion := Pcap_GetPacketVersion ;
    GetAdapters ;
    if FAdapterNameList.Count <> 0 then FMonAdapter := FAdapterNameList [0] ;
    inherited Create(AOwner);
end ;

destructor TMonitorPcap.Destroy;
begin
    if FConnected then StopMonitor ;
//    FreeAndNil (FIgnoreIPList) ;
    FreeAndNil (FAdapterNameList) ;
    FreeAndNil (FAdapterDescList) ;
    inherited Destroy;
end ;

function TMonitorPcap.GetAdapters: boolean ;
var
    total: integer ;
begin
    result := false;
    if NOT Assigned (FAdapterNameList) then exit ;
    FAdapterNameList.Clear ;
    FAdapterDescList.Clear ;
    total := Pcap.pcap_GetAdapterNamesEx (FAdapterNameList, FAdapterDescList, FLastError) ;
    if total = 0 then exit ;
    result := true;
end ;

function TMonitorPcap.GetIPAddresses (AdapterName: string ;
                                    IPList, MaskList, BcastList: TStringList): integer ;
var
    IPArray, MaskArray, BcastArray: IPAddrArray ;
    I: integer ;
begin
    IPList.Clear ;
    MaskList.Clear ;
    BcastList.Clear ;
    result := Pcap_GetIPAddresses (AdapterName, IPArray, MaskArray, BcastArray, FLastError) ;
    if result = 0 then exit ;
    for I := 0 to Pred (result) do
    begin
        IPList.Add (IPToStr (IPArray [I])) ;
        MaskList.Add (IPToStr (MaskArray [I])) ;
        BcastList.Add (IPToStr (BcastArray [I])) ;
    end ;
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

// convert seconds since 1 Jan 1970 (UNIX time stamp) to proper Delphi stuff
// and micro seconds 

function UnixStamptoDT (stamp: TunixTimeVal): TDateTime ;
begin
    result := ((stamp.tv_Sec / SecsPerDay) + 25569) +
                                    ((stamp.tv_uSec / 1000000) / SecsPerDay) ;
end ;

procedure TMonitorPcap.MonDataAvailable (const Header: Ppcap_pkthdr ; const PackPtr: Pchar) ;
var
    hdrlen, iploc: integer ;
    ethernethdr: PHdrEthernet ;
    iphdr: PHdrIP;
    tcphdr: PHdrTCP;
    udphdr: PHdrUDP;
    PacketInfo: TPacketInfo ;  // the data we return in the event

    procedure GetDataByOffset (offset: integer) ;
    var
        datastart: PChar ;
    begin
        datastart := PChar (PChar (iphdr) + offset) ;
        with PacketInfo do
        begin
            if ntohs (iphdr.tot_len) < (Header.Len - OFFSET_IP) then
                DataLen := ntohs (iphdr.tot_len) - offset
            else
                DataLen := Header.Len - OFFSET_IP - offset;
            if DataLen = 0 then exit ;
            if FIgnoreData then exit ;
            SetLength (DataBuf, DataLen) ;
            Move (datastart^, DataBuf [1], DataLen) ;
        end ;
    end;

begin
    FillChar (PacketInfo, Sizeof(PacketInfo), 0) ;
    with PacketInfo do
    begin
        PacketLen := Header.Len ;
        if PacketLen <= 0 then exit ;
        ethernethdr := PHdrEthernet (PackPtr) ;
        EtherProto := ntohs (ethernethdr.protocol) ;
        EtherSrc := ethernethdr.smac ;
        EtherDest := ethernethdr.dmac ;
        SendFlag := CompareMem (@EtherSrc, @FAdapterMac, SizeOf (TMacAddr)) ;
        PacketDT := UnixStamptoDT (Header.ts) + FLocalBiasUTC ; // Unix time stamp correct to local time

     // internet layer IP, lots to check
        if EtherProto = PROTO_IP then
        begin
            iphdr := PHdrIP (Pchar (PackPtr) + OFFSET_IP) ;  // IP header is past ethernet header
            AddrSrc := iphdr.saddr ;        // 32-bit IP addresses
            AddrDest := iphdr.daddr ;
     //     SendFlag := (FInAddr.S_addr = AddrSrc.S_addr) ;  // did we sent this packet
            ProtoType := iphdr.protocol ;   // TCP, UDP, ICMP

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

        // check protocol and find ports and data
            if Assigned (FOnPacketEvent) then
            begin
                DataBuf := '' ;
                hdrlen := GetIHlen (iphdr^) ;
                if ProtoType = IPPROTO_ICMP then
                begin
                    IcmpType := PByte (PChar (iphdr) + hdrlen)^ ;
                    GetDataByOffset (hdrlen) ;
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
                    end;
                    if ProtoType = IPPROTO_UDP then
                    begin
                        udphdr := PHdrUDP (PChar (iphdr) + hdrlen) ;
                        PortSrc := ntohs (udphdr.src_port) ;
                        PortDest := ntohs (udphdr.dst_port) ;
                        GetDataByOffset (hdrlen + Sizeof (THdrUDP));
                    end;
                end;
                FOnPacketEvent (Self, PacketInfo) ;
            end ;
        end
        else

     // otherwise ARP or something more obscure
        begin
         //   if FIgnoreLAN then exit ;
            if FIgnoreNonIP then exit ;
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
            if Assigned (FOnPacketEvent) then
            begin
                DataLen := PacketLen - OFFSET_IP ;
                if DataLen <= 0 then exit ;
                SetLength (DataBuf, DataLen) ;
                Move (Pchar (Pchar (PackPtr) + OFFSET_IP)^, DataBuf [1], DataLen) ;
                FOnPacketEvent (Self, PacketInfo) ;
            end ;
        end ;

    end ;
end ;

procedure TMonitorPcap.StartMonitor;
var
    snaplen, mins: integer ;
begin
    if (FAdapterNameList.Count = 0) or (FMonAdapter = '') then
    begin
        FLastError := 'No Adaptors Found to Monitor' ;
        exit;
    end;
    if FConnected or (FPcapHandle <> nil) then
    begin
        FLastError := 'PCap Driver Already Running' ;
        exit;
    end;
    FAddr := Trim (FAddr) ;
    FInAddr := StrToIP (FAddr) ;  // keep 32-bit listen IP address
    FAddrMask := Trim (FAddrMask) ;
    if Length(FAddrMask) = 0 then
        FInAddrMask.S_addr := 0
    else
        FInAddrMask := StrToIP (FAddrMask) ; // and IP mask
    FTotRecvBytes := 0 ;
    FTotSendBytes := 0 ;
    FTotRecvPackets := 0 ;
    FTotSendPackets := 0 ;
    mins := GetLocalBiasUTC ;
    if mins < 0 then          // reverse minutes, -60 for GMT summer time 
        mins := Abs (mins)
    else
        mins := 0 - mins ;
    FLocalBiasUTC := mins  / (60.0 * 24.0) ;  // keep local time bias

  // open winpcap driver for specific adaptor
    FConnected := false ;
    if FIgnoreData then
        snaplen := DEFAULT_SNAPLEN
    else
        snaplen := 2000 ;
    FPcapHandle := pcap_open_live (PChar (FMonAdapter), snaplen,
                                                        FPromiscuous, 100, FLastError) ;
    if FPcapHandle = nil then
       begin
           exit;
       end;
//    Pcap_SetMinToCopy (FPcapHandle, 20000) ;  not sure if this is beneficial
    FAdapterMac := Pcap_GetMacAddress (FPcapHandle, FLastError) ;


  // Start Snoop Read Thread
    FPcapThread := TPcapThread.Create (true) ;
    FPcapThread.FMonitorPcap := Self ;
    FPcapThread.OnTerminate := ThreadTerminate ;
    FPcapThread.FreeOnTerminate := false;
    FPcapThread.Resume;
    FConnected := true;
end ;

procedure  TMonitorPcap.StopMonitor;
begin
    FConnected := false ;

  // stop thread
    if Assigned (FPcapThread) then
    begin
        FPcapThread.Terminate ;
        FPcapThread.WaitFor ;
        FPcapThread.Free ;
        FPcapThread := nil ;
    end ;
    if Assigned (FPcapHandle) then
    begin
        Pcap_Close (FPcapHandle) ;
        FPcapHandle := Nil ;
    end ;
end ;


end.
