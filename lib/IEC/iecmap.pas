unit IECMAP;

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
  TIECItemStream = class(TBytesStream)
    public

  end;

  IECQU = (IV,NT,SB,BL,OV,CA,CY);
  IECQUSet= set of IECQU;

  IEC_SType = (IEC_NULL_TYPE,
		M_SP_NA,M_DP_NA,M_ME_NA,M_ME_NB,M_ME_NC,M_IT_NA,
		M_SP_TB,M_DP_TB, M_ME_TB,M_ME_TD,M_ME_TF,M_IT_TB,
                C_IC_NA,C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
		C_SC_NA ,C_DC_NA,C_CS_NA);

 IEC_Types= set of IEC_SType;

 TIECType = record
    sname : String;
    name : String;
    TK : byte;
    BK : Byte;
  end;

 TIECCRC = record
    lenght: smallint;
    iobcount: smallint;
    iolenght : smallint;
    txt:String;
  end;

  TIECBUFFER = array of byte;

//function toString(t : TIECSType):String;
//function BufferToHexStr(const buf:TIECBUFFER;len:integer):string;
//function BufferToHexStr(const buf:TIECBUFFER):string;
function getSType(tk : byte):IEC_SType;

var
  MAP :array[IEC_SType] of TIECType;
  sType : IEC_SType;
//  lastCRC:TIECCRC;//integer;

const
  IECSEPERATOR ='/';

  IEC_M_Type =[	M_SP_NA,M_DP_NA,M_ME_NA,M_ME_NB,M_ME_NC,M_IT_NA,
		M_SP_TB,M_DP_TB, M_ME_TB,M_ME_TD,M_ME_TF,M_IT_TB ];
  IEC_C_Type =[  C_IC_NA,C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
		C_SC_NA ,C_DC_NA,C_CS_NA ];

implementation

uses
  INIFiles, TypInfo, math,dateutils;

var
  INI:TINIFile;
  STypeName : array [IEC_SType] of String;

const
  IECTK : array [IEC_SType] of byte = ($00,
       	$01,$03,$09,$0b,$0d,$0f,     // M_SP_NA, M_DP_NA, M_ME_NA, M_ME_NB ,M_ME_NC, M_IT_NA,
       	$1e,$1f,$0a,$0c,$0e,$10,     // M_SP_TB, M_DP_TB, M_ME_TB, M_ME_TD, M_ME_TF, M_IT_TB,
        $64,$65,  48,49, 50,         // C_IC_NA,C_CI_NA, C_SE_NA, C_SE_NB , C_SE_NC,
        $2d, $2e, $67);             //	C_SC_NA ,C_DC_NA,C_CS_NA);
  IECBK : array [IEC_SType] of byte = ($00,
       	$01,$03,$09,$0b,$0d,$0f,
       	$01,$03,$09,$0b,$0d,$0f,
        $64,$65,  48,49, 50, 	$2d, $2e, $67);



function BufferToHexStr(const buf:TIECBUFFER;len:integer):string;
var
  x:integer;
begin
  result:='';
  for x:=0 to len-1 do
     begin  result:=result+inttohex(buf[x],2)+' ';   end;
end;

function BufferToHexStr(const buf:TIECBUFFER):string;
  begin   result := BufferToHexStr(buf,length(buf)); end;

Procedure readSTypeName(INI:TINIFile);
var
 def,txt:String;
begin
  for sType:=low(IEC_SType) to high(IEC_SType) do
       begin
        def := GetEnumName(TypeInfo(IEC_SType), integer(stype));
        txt := INI.ReadString('TypeName',def,def);
        STypeName[sType]:=txt;
       end;
 end;

Procedure readSTypeName;
var
 INI:TINIFile;
begin
  INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iecgw.ini');
  readSTypeName(INI);
  ini.Destroy;
 end;

//function IECTypeToString(t : IEC_SType):String;
// begin result := STypeName[sType]; end;

function getSType(tk :byte):IEC_SType;
  begin
  for sType:=low(IEC_SType) to high(IEC_SType) do
          if MAP[sType].tk=tk then
             begin
             result := sType;
             exit;
             end;
  result := IEC_NULL_TYPE;
  end;


Initialization
   begin
   readSTypeName;
   for sType:=low(IEC_SType) to high(IEC_SType) do
          begin
          MAP[sType].sname:=GetEnumName(TypeInfo(IEC_SType), integer(stype));
          MAP[sType].name:= STypeName[sType];
          MAP[sType].TK:=IECTK[sType];
          MAP[sType].BK:=IECBK[sType];
          end;
   end;

end.

