const
  Vstr='0.1.';
  cstr='(c) Jaen /IDS';
  dstr='2014';
  rstr= {$i revision.inc};
  platform ='__32Bit';
//  VersionStr= '1.0.'+inttostr(rstr);
{
{$IFDEF linux}  platform ='Linux32Bit';{$ENDIF}
{$IFDEF win32}
  platform ='32Bit';
{$ENDIF}
{$IFDEF win64}
  platform ='64Bit';
{$ENDIF}
 }
function  PWStr:string;
 begin
    result:= Vstr+inttostr(rstr);
 end;

function  VersionStr:string;
 begin
    result:= 'Beta Version '+platform+'  '+vstr+inttostr(rstr)+'  '+cstr+'  '+dstr;
 end;

function  VersionshortStr:string;
 begin
    result:= 'V'+vstr+inttostr(rstr);
 end;

