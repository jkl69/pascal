const
  Vstr='0.3.';
  cstr='(c) Jaen';
  dstr='2013';
  rstr= {$i revision.inc};
//  VersionStr= '1.0.'+inttostr(rstr);

function  PWStr:string;
 begin
    result:= Vstr+inttostr(rstr);
 end;

function  VersionStr:string;
 begin
//    lrstr= {$i revision.inc};
    result:= 'Version '+vstr+inttostr(rstr)+'  '+cstr+'  '+dstr;
 end;


