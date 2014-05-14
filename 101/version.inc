const
  Vstr='0.1.';
  cstr='(c) Jaen /IDS';
  dstr='2014';
  rstr= {$i revision.inc};
//  VersionStr= '1.0.'+inttostr(rstr);

function  PWStr:string;
 begin
    result:= Vstr+inttostr(rstr);
 end;

function  VersionStr:string;
 begin
    result:= 'Beta Version '+vstr+inttostr(rstr)+'  '+cstr+'  '+dstr;
 end;

function  VersionshortStr:string;
 begin
    result:= 'V'+vstr+inttostr(rstr);
 end;

