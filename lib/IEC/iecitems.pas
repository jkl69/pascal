unit IECItems;

{$mode objfpc}{$H+}

interface

{
 *
 * DOS not support Block packet TC Streams
 *
 * @author jaen
 *
 *
 }

uses
  Classes, SysUtils;

Type

  TIECSType = (IEC_NULL_TYPE,
		M_SP_NA,M_DP_NA,M_ME_NA,M_ME_NB,M_ME_NC,M_IT_NA,
		M_SP_TB,M_DP_TB, M_ME_TB,M_ME_TD,M_ME_TF,M_IT_TB,
                C_IC_NA,C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
		C_SC_NA ,C_DC_NA,C_CS_NA);

  TIECType = record
    sname : String;
    name : String;
    TK : byte;
    BK : Byte;
  end;

  TIECTime = record
    time : TDatetime;
    lenght : byte;
    DST : Boolean;
  end;

  TIECCRC = record
    lenght: smallint;
    iobcount: smallint;
    iolenght : smallint;
    txt:String;
  end;

  TIECBUFFER = array of byte;

  TIECTCOBJ =class;

  TIECTCItem =class(TObject)
    protected
       Stream : array[0..250] of byte;
       StreamLength :integer;
    private
//      IOB :TArrayList;
      IOB : Tlist;
      sType : TIECSType;
      fASDU : integer;
      procedure readASDU();
      function getObj(index :integer):TIECTCOBJ;
      function getadr(index :integer):integer;
      Procedure setval(index :integer;val :single);
      function getval(index :integer):single;
      Procedure setqu(index :integer;val :byte);
      function getqu(index :integer):byte;
//      Procedure settime(index :integer;val :TDatetime);
      Procedure settime(index :integer;val :TIECTime);
      function gettime(index :integer):TIECTime;
      function gettimeStr(index :integer):String;
//      function gettime(index :integer):TDatetime;
      function IsCRC(len :integer):boolean;
//      function crcLength:integer;
//      function crcLength(len :integer):boolean;
      function MaxObjects():integer;
      procedure setCOT(cot : word);
      function getCOT:word;
   public
       Name:String;
       ID: integer;
     constructor create();
     constructor create(tk:TIECSType;asdu:integer;adr:integer); overload;
//     constructor create(b : TIECBUFFER;len : integer); overload;
     constructor create(b : array of byte;len : integer); overload;
     Function ToString:String;
     Function Equal(item:TIECTCItem):boolean;
     procedure setType(t: TIECSType);
     function getType:TIECSType;
     procedure setASDU(ASDU : integer);
     procedure addIOB();
     procedure addIOB(item : TIECTCOBJ); overload;
     procedure setIOBCount(c :integer);
     function getIOBCount():integer;
     function getStream:TIECBUFFER;
     property ASDU:integer read Fasdu write Fasdu;
     property COT:Word read getCOT write setCOT;
     property Obj[index:integer]:TIECTCOBJ Read getObj;
     property Adr[index:integer]:integer Read getadr;
     property Value[index:integer]:single Read getval write setval;
     property Qu[index:integer]:byte Read getqu write setqu;
     property time[index:integer]:TIECTime Read gettime write settime;
//     property timeRX[index:integer]:TIECTime Read gettimeRx write settime;
     property timeStr[index:integer]:String Read gettimeStr;
  end;

  TIECTCOBJ =class(TObject)
  protected
     buf :array[0..16] of byte;
     fItem : TIECTCItem;
     MIN_VALUE : Double;
     MAX_VALUE : Double;
     ValueParam : Integer;
     fQU : byte;
     SEQ : byte;
     Fonchange : TnotifyEvent;
       ftime :TIECTime;
//     ftime :Tdatetime;
//     Time_TX : TDatetime;
//     Time_RX : TDatetime;
     Time_TX : TIECTime;
     Time_RX : TIECTime;
//     DST : Boolean;
//     timequ :byte;
  private
    value : double;
    procedure init();
    procedure setDefLimits();
    function getDef_MAX():double;
    function getDef_MIN():double;
    function isTimeType():boolean;
    function  getTimeIndex():integer;
    function  getIOBLength():integer;
    function getBufLength:integer;
    function getTimeLength():integer;
    procedure readValue();
    procedure writeValue();
    PROCEDURE readQU();
    procedure writeQu();
    procedure writeTime();
    function readTime():tIECTime;
//    function readTime():tdatetime;
    function readTime(index: integer):tIECTime; overload;
//    function readTime(index: integer):tdatetime; overload;
    procedure writeTime(TimeIndex: integer); overload;
  public
     constructor create(item :TIECTCItem; adr :integer);
     procedure setAdr(a :integer);
     function Path():String;
     function getAdr:integer;
     Function getValue:double;
     procedure setValues(v :single;qu:byte; d : Tdatetime);
     Function setValue(v : double):boolean;
     procedure setqu(val:byte);
     function getStream:TIECBUFFER;
     function getTime:TIECTime;
     procedure setTime(t:Tdatetime);
     procedure setTime(v:TIECTime);
     property min:double read MIN_VALUE write MIN_VALUE;
     property max:double read MAX_VALUE write MAX_VALUE;
     property asdu:TIECTCItem read Fitem;
     property onChange:TNotifyEvent read fonchange write fonchange;
  end;

//function toString(t : TIECSType):String;
function BufferToHexStr(const buf:TIECBUFFER;len:integer):string;
function BufferToHexStr(const buf:TIECBUFFER):string;
function print:String;
function  getIOBLength(t:TIECSType):integer;
function isTimeType(t:TIECSType):boolean;
function getSType(tk : integer):TIECSType;
function StringToIECType(s:String): TIECSType;
//function toString(t : TIECSType):String;
function crcLength(item:TIECTCItem):integer;
procedure copyIECTime(s:TIECTime;var d:TIECTime);

var
  TypeAsNumber :boolean=false;
  iobx:integer=1001;
  index:integer;
  P_SHORT : boolean =false;
  Respone_Unknown : boolean  = true;
  IECType :array[TIECSType] of TIECType;
  sType : TIECSType;
  lastCRC:TIECCRC;//integer;

const   C_Type =[C_IC_NA,C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC, C_SC_NA ,C_DC_NA,C_CS_NA];

implementation

uses
  INIFiles, TypInfo, math,dateutils;

var
  INI:TINIFile;
  STypeName : array [TIECSType] of String;


const
  IECTK : array [TIECSType] of byte = ($00,
       	$01,$03,$09,$0b,$0d,$0f,   //M_SP_NA, M_DP_NA, M_ME_NA, M_ME_NB, M_ME_NC, M_IT_NA,
       	$1e,$1f,$0a,$0c,$0e,$10,   //M_SP_TB, M_DP_TB, M_ME_TB, M_ME_TD ,M_ME_TF, M_IT_TB,
        $64,$65,  48,49, 50,      //C_IC_NA, C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
        $2d, $2e, $67);          //C_SC_NA ,C_DC_NA,C_CS_NA
  IECBK : array [TIECSType] of byte = ($00,
       	$01,$03,$09,$0b,$0d,$0f,   //M_SP_NA, M_DP_NA, M_ME_NA, M_ME_NB, M_ME_NC, M_IT_NA,
       	$01,$03,$09,$0b,$0d,$0f,  //M_SP_TB, M_DP_TB, M_ME_TB, M_ME_TD ,M_ME_TF, M_IT_TB,
        $64,$65,  48,49, 50,      //C_IC_NA, C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
        $2d, $2e, $67);           //C_SC_NA ,C_DC_NA,C_CS_NA
  sepchar ='/';

function print:String;
begin
  result:='';
  for sType:=low(TIECSType) to high(TIECSType) do
       begin
         result:=result+IECType[sType].name+',';
//         result:=result+IECType[sType].TK;
//         result:=result+IECType[sType].BK;
       end;
end;

function BufferToHexStr(const buf:TIECBUFFER;len:integer):string;
var
  x:integer;
begin
  result:='';
  for x:=0 to len-1 do
     begin
     result:=result+inttohex(buf[x],2)+' ';
     end;
end;

function BufferToHexStr(const buf:TIECBUFFER):string;
  begin
  result := BufferToHexStr(buf,length(buf));
//   for x:=0 to length(buf)-1 do
//      begin result:=result+inttohex(buf[x],2)+' ';  end;
 end;

Procedure readSTypeName(INI:TINIFile);
var
 def,txt:String;
begin
  for sType:=low(TIECSType) to high(TIECSType) do
       begin
        def := GetEnumName(TypeInfo(TIECSType), integer(stype));
        txt := INI.ReadString('TypeName',def,def);
        STypeName[sType]:=txt;
       end;
 end;

Procedure readSTypeName;
var
 INI:TINIFile;
begin
  INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iec.ini');
//  writeln(INI.ReadString('TypeName','M_SP_NA','hallo'));
  readSTypeName(INI);
  ini.Destroy;
 end;

function IECTypeToString(t : TIECSType):String;
 begin
   //    result := GetEnumName(TypeInfo(TIECSType), integer(t));
    result := STypeName[sType];
 end;

function StringToIECType(s:String): TIECSType;
var sType:TIECSType;
begin
   result:=TIECSType.IEC_NULL_TYPE;
   for sType:=low(TIECSType) to high(TIECSType) do
       if IECType[sType].name=s then
          begin
           result:=sType;
           exit;
          end;
 end;

function getSType(tk : integer):TIECSType;
  begin
  for sType:=low(TIECSType) to high(TIECSType) do
          if IECType[sType].tk=tk then
             begin
             result := sType;
             exit;
             end;
  result := IEC_NULL_TYPE;
  end;

function ArraycopyOF(source: TIECBuffer; len : integer):TIECBuffer;
var
  x:integer;
begin
 setLength(result,len);
 for x:=0 to len-1 do
     result[x]:=source[x];
end;

Procedure memcpy(Const source: Pointer; dest: Pointer; size: Integer);
    Var
      i: Integer;
      b, b2: PByte;
    Begin
      b := Source;
      b2 := dest;
      For i := 0 To Size - 1 Do Begin
        b2^ := b^;
        inc(b);
        inc(b2);
      End;
    End;

procedure arraycopy(source : TIECBuffer; s_index:integer; dest : TIECBuffer; d_index:integer; len:integer);
//   e.g. Stream,4,Stream_s,3,StreamLength-4;
//var
//  x:integer;
begin
//for x:=0 to len-1 do
//   dest[d_index+x]:=source[s_index+x];
memcpy(@source[s_index],@dest[d_index],len);
end;

{   IECTCItem }

constructor TIECTCItem.create();
var
 o:TIECTCOBJ;
 begin
  inherited create;
  IOB := TList.Create();
//  IOB := TArrayList.Create('IOB',1);
  setType(M_SP_NA);
  setCOT(3);
  setASDU(1);
  o := TIECTCObj.create(self,iobx);// new IECTCObject(this,iob++);
  addIOB(o);
  name:='Item'+inttostr(iobx);
  inc(iobx);
  end;

constructor TIECTCItem.create(tk:TIECSType;asdu:integer;adr:integer);
var
 o:TIECTCOBJ;
 begin
  inherited create;
  IOB := TList.Create();
  setType(tk);
  setCOT(3);
  setASDU(asdu);
  o := TIECTCObj.create(self,adr);// new IECTCObject(this,iob++);
  addIOB(o);
  name:='/'+IECItems.IECType[tk].name+'/'+inttostr(asdu)+'/'+inttostr(adr);
//  inc(iobx);
  end;

{**
 * Create new IECStream from an byte stream<br>
 *}

// constructor TIECTCItem.create(b : TIECBUFFER;len : integer);
 constructor TIECTCItem.create(b : array of byte;len : integer);
var
 o:TIECTCOBJ;
 oi,i,index :integer;
 begin
   memcpy(@b[0],@Stream[0],len);
   StreamLength := len;
   sTYPE := getType();
   name:='Stream';

   if (sType <> IEC_NULL_TYPE) then
     begin
     index := 6;
     if (P_SHORT) then
        begin
        Stream[3] :=0;
        memcpy(@b[3],@Stream[4],len-3);//  arraycopy(b,3,Stream,4,length-3);
        inc(StreamLength);
        index := 5;
        end;

    IOB := TList.Create();
    o := TIECTCObj.create(self,iobx);
    addIOB(o);
    setIOBCount(b[1]);
    if (crcLength(self) = len ) then
        begin
        readASDU();
        for oi:=0 to getIOBCount-1 do
          begin
          o :=TIECTCObj( iob[oi]);
          for i:=0 to o.getBufLength-1 do
            begin
            o.buf[i]:=b[index+i];
            end;
          o.readValue();
          o.readTime();
          inc(index,o.getBufLength);
          end;
        end;
//     else   writeln('CRC-Error '+inttoStr(len)+ ' '+LASTCRC.txt);
     end;
     //raise EMathError.Create('CRC-Error');
//   writeln('Create-Exit:'+toString);
end;

Function TIECTCItem.Equal(item:TIECTCItem):boolean;
begin
 result :=(gettype=item.getType)and(asdu=item.ASDU)and(getadr(0)=item.getadr(0));
end;

Function TIECTCItem.ToString:String;
 begin
  if gettype<>TIECSType.IEC_NULL_TYPE then
     result:='/'+IECType[getType].name+'/ASDU:'+inttostr(ASDU)+'/Adr.:'+inttostr(Adr[0])+
             '  [cot:'+inttoStr(cot)+'; val:'+floattostr(Value[0])+'; QU:$'+inttohex(QU[0],2)+'; time:'+TimeStr[0]+']'
  else
      result:= 'IEC_NULL_TYPE '+ buffertohexStr(Stream,streamlength);
end;

{**
   *
   * @param length
   * @return
   *}
function TIECTCItem.isCrc(len : integer):boolean;
begin
    if (len = crcLength(self)) then
// 	 log.log(Level.FINE,"Stream Length:{2} (Head.length[{0}] + IOB.count[{3}]*IOB.length[{1}])",new Object[]{index,l,l+index,getIOBCount()});
 	 result := true
  else
//     log(warn,'Stream Length:{3} should {2} (Head.length[{0}] + IOB.count[{4}]*IOB.length[{1}])",new Object[]{index,l,l * getIOBCount()+index,length,getIOBCount()});
     result := false;

end;

//function TIECTCItem.crcLength:integer;
//function TIECTCItem.crcLength(len : integer):integer;
function crcLength(item:TIECTCItem):integer;
var
 index : integer=6;
begin
 if (P_SHORT) then
     begin
     index := 5;
     end;
//  o := TIECTCObj (item.iob[0]);
//  lastCRC.iolenght :=  o.getBufLength();
  lastCRC.iolenght :=  getIOBLength(item.getType)+3;
  if (P_SHORT) then lastCRC.iolenght :=  getIOBLength(item.getType)+2;
  if isTimeType(item.getType) then
      lastCRC.iolenght :=   lastCRC.iolenght+7;
  lastCRC.iobcount := item.getIOBCount();
  lastCRC.lenght := (lastCRC.iolenght * lastCRC.iobcount) + index ;
  lastCRC.txt:='CRC [ Head:6'
         +' +(IOB.lenght:'+inttostr(LastCRC.iolenght)
         +' * IOB.Count:'+inttostr(LastCRC.iobcount)
         +') =lenght:'+inttoStr(LastCRC.lenght)+']';
  result :=   lastCRC.lenght;
end;

{**
 *  set IECStream-ASDU by reading out of the Stream
 *}

procedure TIECTCItem.readASDU();
var
  index :integer = 4;
begin
 //		System.out.println(c+"[4]"+ (int) Stream[4] +"[5]"+ (int) Stream[5] +"getASDU "+re);
  fASDU := ((Stream[index+1] and $FF) << 8) or (Stream[index] and $FF);
//  log.finest("Stream-ASDU: "+ASDU);
end;

function TIECTCItem.getObj(index :integer):TIECTCobj;
begin
 result:=nil;
 if (index >= iob.Count) then
    begin
    exit;
    end;
 result:=TIECTCOBJ(iob[index]);
end;

function TIECTCItem.getadr(index :integer):integer;
var
 o:TIECTCOBJ;
begin
 result:=-1;
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 result := o.getAdr;
end;

Procedure TIECTCItem.setqu(index :integer;val :byte);
var
 o:TIECTCOBJ;
begin
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 o.setqu(val);
end;

function TIECTCItem.getqu(index :integer):byte;
var
 o:TIECTCOBJ;
begin
 result:=-1;
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 result := o.fQU;
end;

Procedure TIECTCItem.setval(index :integer;val :single);
var
 o:TIECTCOBJ;
begin
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 o.setvalue(val);
end;

function TIECTCItem.getval(index :integer):single;
var
 o:TIECTCOBJ;
begin
 result:=-1;
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 result := o.value;
end;

Procedure TIECTCItem.setTime(index :integer;val :TIECTime);
//  Procedure TIECTCItem.setTime(index :integer;val :Tdatetime);
var
 o:TIECTCOBJ;
begin
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 o.setTime(val);
end;

function TIECTCItem.getTime(index :integer):TIECTime;
//function TIECTCItem.getTime(index :integer):Tdatetime;
var
 o:TIECTCOBJ;
begin
// result.time:=now();
 if (index >= iob.Count) then
    begin
    exit;
    end;
 o:=TIECTCOBJ(iob[index]);
 result := o.getTime();
end;

function TIECTCItem.getTimeStr(index :integer):String;
Var
  YY,MM,DD,HH,MIN,SS,MS : word;
  t:TiecTime;
  dst:String;
begin
  DecodeTime(time[0].time,HH,MIN,SS,MS);
 dst:='w';
 t := getTime(index);
 if (t.DST) then dst:='s';
 result := Datetimetostr(t.time)+','+inttoStr(Ms);//+dst;
end;

function TIECTCItem.MaxObjects():integer;
var
 o:TIECTCOBJ;
begin
  o := TIECTCObj (iob[0]);
  result :=  240 div o.getBufLength();
end;

procedure TIECTCItem.setIOBCount(c :integer);
var
 count:byte;
 o:TIECTCOBJ;
begin
 if (c > MaxObjects()) then
    raise EMathError.Create('Number of Elements exides Max Element numbers');
 count := byte(c);
 if (count <> Stream[1]) then
    begin
    while (IOB.Count < count) do  //create new objects until maxobjs
        begin
        o := TIECTCObj.create(self,iobx);
    	addIOB(o);
        inc(iobx);
        end;
    end;
    while (IOB.count > count) do   //if already to many obj del last
        begin
	IOB[IOB.Count-1] := nil;
	IOB.Delete(IOB.Count-1);
	end;
   if (count <> Stream[1]) then
	Stream[1] := count;
end;

procedure TIECTCItem.setType(t : TIECSType);
 var
  o:TIECTCOBJ;
  it:integer;
  begin
    Stream[0] := IECType[t].tk;
    for it:=0  to IOB.Count-1 do
        begin
        o := TIECTCOBJ(IOB[it]);
//   	IOB.get(it).setDefLimits();   //Reset The Limits
//   	IOB.get(it).setQU((byte) 0);  //Reset The Quality
        end;
  sTYPE := t;
  end;

function TIECTCItem.getType:TIECSType;
  begin
    result := getSType(Stream[0]);
  end;


procedure TIECTCItem.setCOT(cot : word);
  begin
    if (cot > 65535) then cot := 65535;
    if (cot < 1) then cot := 1;
    Stream[2] := byte(cot mod 256);
    Stream[3] := byte(cot div 256);
  end;

Function TIECTCItem.getCOT: word;
  begin
    result:= Stream[2]+Stream[3]*256;
  end;

procedure TIECTCItem.setASDU(ASDU : integer);
var
 index : integer;
  begin
    if (asdu > 65535) then asdu := 65535;
    if (asdu < 1) then	asdu := 1;
    fASDU := asdu;
    if (P_SHORT) then index :=3
    else index := 4;
    Stream[index] := byte (ASDU mod 256);
    Stream[index +1] := byte (ASDU div 256);
  end;

procedure TIECTCItem.addIOB();
var
  o:TIECTCObj;
  begin
   o := TIECTCObj.create(self,iobx);
//   IECTCObject item = new IECTCObject(this);
   addIOB(o);
   end;

procedure TIECTCItem.addIOB(item : TIECTCObj);
   begin
//   log.finest(String.valueOf(item.getIOB()));
   IOB.add(item);
   Stream[1] := byte (IOB.Count);
  end;

function TIECTCItem.getIOBCount():integer;
    begin
//	log.finest(String.valueOf(Stream[1]));
    Result := Stream[1];
    end;


function TIECTCItem.getStream:TIECBUFFER;
var
  index,indexIOB,bl,l,i,it :integer;
  Stream_s,b:TIECBUFFER;
  o : TIECTCObj;
begin

  Stream_s := ArraycopyOf(Stream,200);  //Arrays.copyOf(Stream,StreamLength);
  if (getType()=IEC_NULL_TYPE) then   // Type NOT supported
        begin
        if (Respone_Unknown) then
	   begin
           setCOT($44);
           if (P_SHORT) then
              begin
//              arraycopy(Stream,4,Stream_s,3,StreamLength-4);
	      memcpy(@Stream[4],@Stream_s[3],Streamlength-4);
              result := arraycopyOf(Stream_s,StreamLength-1);
	      end
           else  result :=  ArraycopyOf(Stream,StreamLength);
	   end;
        exit;
        end;
  //  Known Type
//     Stream_s := ArraycopyOf(Stream,StreamLength+200);
     Stream[4] := byte(fASDU mod 256);
     Stream[5] := byte(fASDU div 256);
     Stream_s[3] := byte (fASDU mod 256);
     Stream_s[4] := byte (fASDU div 256);
     index :=6;
     if (P_SHORT) then index :=5;
     indexIOB := index;
     bl := 0;
     i := getIOBCount();
     for it:=0 to i-1 do
        begin
        o := TIECTCObj(iob[it]);
        b := o.getStream();
	if (P_SHORT) then begin
//           arraycopy(b,0,Stream_s,indexIOB,length(b))
           memcpy(@b[0],@Stream[indexIOB],length(b));
           end
	else
            begin
//            arraycopy(b,0,Stream,indexIOB,length(b));
            memcpy(@b[0],@Stream[indexIOB],length(b));
            end;
	indexIOB := indexIOB + length(b);
	bl := length(b);
	end;
     l := index+ i *(bl);
     if (P_SHORT) then
         result := ArraycopyOf(Stream_s,l)
     else
         result := ArraycopyOf(Stream,l);
//	log.finer(s+":"+l+"[ "+IECFunctions.byteArrayToHexString(result,0,result.length)+"]");
end;

{ TIECTCOBJ }
constructor TIECTCOBJ.create(item :TIECTCItem; adr :integer);
begin
  inherited create;
  fitem:=item;
  init();
  setAdr(adr);
end;

procedure TIECTCOBJ.init();
begin
   //log.finest("");
   setDefLimits();
   setValues(0,0,now);
   Time_TX := fTime;
//   Time_TX.time := fTime;
end;

procedure TIECTCOBJ.setDefLimits();
begin
  MAX_VALUE := getDef_MAX();
  MIN_VALUE := getDef_MIN();
end;

function TIECTCOBJ.getDef_MAX():double;
begin
   if (fitem.getType = IEC_NULL_TYPE) then
       begin result := MAX_VALUE; exit; end;

   case (fitem.getType) of
     M_SP_NA,M_SP_TB : result :=1;
     C_SC_NA : result :=1;
     M_DP_NA,M_DP_TB : result :=3;
     C_DC_NA : result :=3;
     M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD : result := High(SmallInt);
     C_SE_NA,C_SE_NB : result := High(SmallInt);
//     M_ME_NC,M_ME_TF,C_SE_NC : result := MaxValue(single);
     M_ME_NC,M_ME_TF,C_SE_NC : result := 1000000000000.0;
     M_IT_NA,M_IT_TB : result := High(Longint);
     C_IC_NA,C_CI_NA : result := 255;
   end;
end;

function TIECTCOBJ.getDef_MIN():double;
begin
   if (fitem.getType = IEC_NULL_TYPE) then
       begin result := MAX_VALUE; exit; end;

   case (fitem.getType) of
     M_SP_NA,M_SP_TB : result :=0;
     C_SC_NA : result :=0;
     M_DP_NA,M_DP_TB : result :=0;
     C_DC_NA : result :=0;
     M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD : result := Low(SmallInt);
     C_SE_NA,C_SE_NB : result := Low(SmallInt);
//     M_ME_NC,M_ME_TF,C_SE_NC : result := MaxValue(single);
     M_ME_NC,M_ME_TF,C_SE_NC : result := -1000000000000.0;
     M_IT_NA,M_IT_TB : result := Low(Longint);
     C_IC_NA,C_CI_NA : result := 0;
   end;
end;

procedure TIECTCOBJ.setAdr(a :integer);
begin
  if (a > $ffffff) then a := $ffffff;
  if (a < 0) then  a := 0;
  buf[0] := byte (a and $00ff);
  buf[1] := byte (a shr 8);
  buf[2] := byte (a shr 16);
//  buf[1] := byte (a and $00ff00)>>8);
//  buf[2] := byte (a and $ff0000)>>16);
//  log.log(Level.FINEST,"{0} [{1}] ",new Object[]{getIOB(),IECFunctions.byteArrayToHexString(buf, 0, 3)});
end;

function TIECTCOBJ.Path:String;
begin
 if TypeAsNumber then
      result := sepchar+inttoStr(IECType[Fitem.getType].tk)+sepchar+inttoStr(fitem.ASDU)+sepchar+inttostr(getAdr)
  else
     result := sepchar+IECType[Fitem.getType].name+sepchar+inttoStr(fitem.ASDU)+sepchar+inttostr(getAdr);
end;

function TIECTCOBJ.getAdr:integer;
begin
  if (P_SHORT) then
     result :=  (buf[0] and $FF) or ((buf[1] and $FF) << 8)
  else
     result :=  (buf[0] and $FF) or ((buf[1] and $FF) << 8) or ((buf[2] and $FF) << 16);
end;

function TIECTCOBJ.getTime:TIECTime;
begin
 result :=fTime;
end;

procedure TIECTCOBJ.setTime(t:Tdatetime);
begin
  fTime.time:= t;
  if assigned(fonChange) then
     Fonchange(self);
end;

procedure TIECTCOBJ.setTime(v:TIECTime);
begin
 fTime.DST:= v.DST;
 fTime.lenght:= v.lenght;
 setTime(v.time);
end;

Function TIECTCOBJ.getValue():double;
begin
  result:=Value;
end;

Function TIECTCOBJ.setValue(v : double):boolean;
begin
 result:= false;
 if (v > MAX_VALUE) then v := MAX_VALUE;
 if (v < MIN_VALUE) then v := MIN_VALUE;
 if (v <>  Value) then
     begin
     Value := v;
//		System.out.println("setValue(newValue : "+v+")");
//     fTime := now();
    setTime(now());
    fTime.lenght := 7;
    result:=true;
    end;
end;

procedure TIECTCOBJ.setValues(v :single;qu:byte; d : Tdatetime);
begin
  setValue(v);
//  setQU(qu);
  fQU := qu;
//  setTime(d);
  ftime.time := d;
//  ftime := d;
end;

function TIECTCOBJ.isTimeType():boolean;
begin
 result:= IECItems.isTimeType(fitem.getType);
end;


function isTimeType(t:TIECSType):boolean;
begin
  case (t) of
    M_SP_TB,M_DP_TB,
    M_ME_TB,M_ME_TD,M_ME_TF,M_IT_TB : result:=true;
  else
    result:=false;
  end;
end;

function  getIOBLength(t:TIECSType):integer;
begin
  result:=0;
  case (t) of
    M_SP_NA,M_SP_TB,M_DP_NA,M_DP_TB,
    C_SC_NA,C_DC_NA,C_IC_NA,C_CI_NA : result:=1;

    M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD,
    C_SE_NA,C_SE_NB : result :=3;

    M_ME_NC,M_ME_TF,    C_SE_NC : result :=5;

    M_IT_NA,M_IT_TB : result :=5;

    C_CS_NA : result :=7;
  end;
end;

function  TIECTCOBJ.getIOBLength():integer;
begin
  result:=IECItems.getIOBLength(fitem.getType);
{*  case (fitem.getType) of
    M_SP_NA,M_SP_TB,M_DP_NA,M_DP_TB,
    C_SC_NA,C_DC_NA,C_IC_NA,C_CI_NA : result:=1;

    M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD,
    C_SE_NA,C_SE_NB : result :=3;

    M_ME_NC,M_ME_TF,    C_SE_NC : result :=5;

    M_IT_NA,M_IT_TB : result :=5;

    C_CS_NA : result :=7;
  end; *}
//log.finest(String.valueOf(result));
end;

function  TIECTCOBJ.getTimeIndex():integer;
begin
  if (P_SHORT) then result := getIOBLength()+2
  else 	result := getIOBLength()+3;
end;

procedure TIECTCOBJ.writeTime();
 begin
    writeTime(getTimeIndex());
 end;

procedure TIECTCOBJ.writeTime(TimeIndex: integer);
Var
  YY,MM,DD,HH,MI,SS,MS : word;
 begin
//   DecodeDate(Date,YY,MM,DD);
//   DecodeTime(fTime,HH,MIN,SS,MS);
   DecodeDate(Time_TX.time,YY,MM,DD);
   DecodeTime(Time_TX.time,HH,MI,SS,MS);
   ms := 1000*SS+MS;
   buf[TimeIndex] := byte (MS mod 256);
   buf[TimeIndex+1] := byte (MS div 256);
   buf[TimeIndex+2] := byte (MI);
   buf[TimeIndex+3] := byte (HH);
//   if (TimeZone.getDefault().inDaylightTime(d.getTime()))then 	buf[TimeIndex+3]=(byte) (buf[TimeIndex+3]+0x80) ;
   buf[TimeIndex+4] := byte (DD);
   buf[TimeIndex+5] := byte (MM);
   buf[TimeIndex+6] := byte (YY-2000);
end;

//function TIECTCOBJ.readTime():tdatetime;
function TIECTCOBJ.readTime():TIECTime;
var
 TimeIndex:integer;
begin
  TimeIndex := getTimeIndex();
  result := readTime(TimeIndex);
end;

procedure copyIECTime(s:TIECTime;var d:TIECTime);
begin
  d.time := s.time;
  d.lenght := s.lenght;
  d.DST := s.DST;
end;

//function TIECTCOBJ.readTime(index: integer):tdatetime;
function TIECTCOBJ.readTime(index: integer):TIECTime;
Var
  YY,MM,DD,HH,MI,SS,MS : word;
begin
 if (isTimeType()) then
     begin
//     ms := ((buf[index+1] and $FF) << 8) or (buf[index] and $FF);
     ms := buf[index+1]*256 + buf[index];
     ss := ms div 1000;
     ms := ms mod 1000;
     MI := buf[index+2] and $FF;
     HH := buf[index+3] and $7F;
     result.DST := boolean (buf[index+3] and $80);
     DD := buf[index+4] and $1F;
     MM := (buf[index+5] and $FF)-1;
     YY := (buf[index+6] and $FF)+2000;
     result.time := EncodeDateTime(YY,MM,DD,HH,MI,ss,ms);
     result.lenght := 7;
     end
 else
    begin
    result.time := now;
    result.lenght := 0;
    result.DST := false;
    end;
 copyIECTime(result,Time_Rx);
 copyIECTime(result,ftime);
end;

procedure TIECTCOBJ.setqu(val:byte);
 begin
  if fqu<>val then
      begin
      Fqu:=val;
      settime(now());
      end;
 end;

PROCEDURE TIECTCOBJ.readQU();
var index:integer;
begin
  index:=3;
  case (asdu.getType()) of
  M_SP_NA,M_SP_TB: Fqu := buf[index] and $fe;
  C_SC_NA:         Fqu := buf[index] and $fe;
  M_DP_NA,M_DP_TB : Fqu := buf[index] and $fC;
  C_DC_NA:         Fqu := buf[index] and $fC;
  M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD :
                  fqu := buf[index+2];
  C_SE_NA:          fqu := buf[index+2];
  M_ME_NC:          fqu := buf[index+4];
  C_SE_NC:          fqu := buf[index+4];
  M_IT_NA,M_IT_TB: begin
                  fqu := buf[index+4] and $e0;
                  Seq := buf[index+4] and $1f;
                  end;
  end;
end;

procedure TIECTCOBJ.writeQu();
var index:integer;  b:byte;
 begin
   index := 3;
    case (asdu.getType()) of
    M_SP_NA,M_SP_TB: buf[index] := fQU or  buf[index];
    C_SC_NA:         buf[index] := fQU or  buf[index];
    M_DP_NA,M_DP_TB : buf[index] := fQU or  buf[index];
    C_DC_NA:         buf[index] := fQU or  buf[index];
    M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD :
                    buf[index+2] := fQU;
    C_SE_NA:          buf[index+2] := fQU;
    M_ME_NC:          buf[index+4] := fQU;
    C_SE_NC:          buf[index+4] := fQU;
    M_IT_NA,M_IT_TB: begin
                    buf[7] := fQU or buf[7];
                    buf[index+4] := fQU or SEQ;
                    inc(SEQ);
		    if (SEQ>31) then SEQ := 0;
                    end;
    end;
 end;

procedure TIECTCOBJ.readValue();
var
  res :double =0;
  svalue :SINGLE;
  s_value : array[0..3] of byte absolute svalue;
  index : integer = 3;
begin
  if (P_SHORT) then
  	index :=2;
  case (fitem.getType) of
    M_SP_NA,M_SP_TB: res:= buf[index] and $01;
    M_DP_NA,M_DP_TB: res:= buf[index] and $03;
    C_SC_NA: begin
            res:= buf[index] and $03;
            ValueParam :=  buf[index] and $1c;
            end;
    C_DC_NA: begin
            res:= buf[index] and $03;
            ValueParam :=  buf[index] and $1c;
            end;
    M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD: begin
             res := smallint (buf[index] +buf[index+1]*256);       end;
    M_ME_NC ,M_ME_TF: begin
          S_value[0]:= buf[index];
          S_value[1]:= buf[index+1];
          S_value[2]:= buf[index+2];
          S_value[3]:= buf[index+3];
          res:=svalue;
           end;
    M_IT_NA ,M_IT_TB: begin
             res:= buf[index] +buf[index+1]<<8 +buf[index+2]<<16 +buf[index+3]<<24;
             end;
    C_SE_NA, C_SE_NB: res:= buf[index] + buf[index+1]*256;
    C_IC_NA:  res := buf[index];
//    C_CS_NA : res := readTime(index);//.getTime();
    C_CS_NA : res := readTime(index).time;
  end;
  Value := res;
end;

procedure TIECTCOBJ.writeValue();
var
  Index :integer;
  ivalue :smallint;
  lvalue :longint;
  svalue :SINGLE;
  s_value : array[0..3] of byte absolute svalue;
  i_value : array[0..1] of byte absolute ivalue;
 begin
   index:=3;
   case (fitem.getType) of
   M_SP_NA,M_SP_TB : begin buf[index]:= byte ( round(value) and $01); end;
   C_SC_NA :  begin
      		buf[index] := byte(byte(round(Value)) and $01) ;
   		buf[index] := byte(buf[index] or byte(ValueParam));
               end;
   M_DP_NA,M_DP_TB : begin buf[index]:= byte ( round(value) and $03); end;
   C_DC_NA :  begin
      		buf[index] := byte(byte(round(Value)) and $03) ;
   		buf[index] := byte(buf[index] or byte(ValueParam));
               end;
   M_ME_NA,M_ME_TB,M_ME_NB,M_ME_TD :  begin
      		ivalue := round(value);
//                buf[index] :=  byte(iValue mod 256) ;
//   		buf[index+1] :=byte(iValue div 256) ;
                buf[index] :=  i_value[0];
                buf[index+1] :=  i_value[1];
               end;
   C_SE_NA,C_SE_NB :  begin
      		ivalue := round(value);
                buf[index] :=  i_value[0];
                buf[index+1] :=  i_value[1];
                //buf[index] := byte(iValue mod 256) ;
   	       //buf[index+1] :=byte(iValue div 256) ;
               end;
   M_ME_NC,M_ME_TF :  begin
                svalue := single(value);
                buf[index+3] := s_Value[3] ;
                buf[index+2] := s_Value[2] ;
                buf[index+1] := s_Value[1] ;
                buf[index+0] := s_Value[0] ;
               end;
   C_SE_NC:  begin
                svalue := single(value);
                buf[index+3] := s_Value[3] ;
                buf[index+2] := s_Value[2] ;
                buf[index+1] := s_Value[1] ;
                buf[index] := s_Value[0] ;
               end;
   M_IT_NA,M_IT_TB:  begin
                lvalue := round(value);
                buf[index+3] := byte (lvalue shr 24);
                buf[index+2] := byte (lvalue shr 16) ;
                buf[index+1] := byte (lvalue shr 8) ;
                buf[index] := byte (lvalue ) ;
               end;
   C_IC_NA:  begin  buf[index] := byte (round(value)); end;
   C_CS_NA:  begin  writeTime(index); end;
   end;
   {
   	case M_IT_NA: case M_IT_TB :
   		int value=(int)Value;
   		buf[index+3] =(byte) ((value & 0xff000000)>>24);
   		buf[index+2] =(byte) ((value & 0x00ff0000)>>16);
   		buf[index+1] =(byte) ((value & 0x0000ff00)>>8);
   		buf[index] =(byte) ((value & 0x000000ff));
   		break;
       }
 end;

function TIECTCOBJ.getTimeLength():integer;
begin
  if (isTimeType()) then result := 7
  else 	result :=0;
end;

function TIECTCOBJ.getBufLength:integer;
begin
  result := getTimeIndex()+getTimeLength();
end;

function TIECTCOBJ.getStream:TIECBUFFER;
var
  l:integer;
  result_l,result_s :TIECBUFFER;
begin
    writeValue();
    writeQU();
    if (isTimeType()) then writeTime();
    l := getBufLength();
    result_l := ArraycopyOf(buf, l);
    if (P_SHORT) then  	//creates "short array"
        begin
        result_s :=  ArraycopyOf(buf, l);
//	arraycopy(buf, 3, result_s, 2, l-3);
        memcpy(@buf[3],@result_s[2],l-3);
//	log.finer("s:"+l+"[ "+IECFunctions.byteArrayToHexString(result_s,0,result_s.length)+"]");
	result := result_s;
        end
    else
       begin
//  	log.finer("S:"+l+"[ "+IECFunctions.byteArrayToHexString(result,0,result.length)+"]");
  	result:= result_l;
       end;
  end;


Initialization
   begin
   readSTypeName;
   for sType:=low(TIECSType) to high(TIECSType) do
          begin
          IECType[sType].sname:=GetEnumName(TypeInfo(TIECSType), integer(stype));
          IECType[sType].name:=IECTypetoString(sType);
          IECType[sType].TK:=IECTK[sType];
          IECType[sType].BK:=IECBK[sType];
          end;
   end;

end.

