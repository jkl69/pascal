const
  Vstr='Version 0.0.0.';
  cstr='(c) Jaen';
  dstr='2013';
  rstr= {$i revision.inc};
//  VersionStr= '1.0.'+inttostr(rstr);

function  VersionStr:string;
 var
   lrstr:string;
 begin
//    lrstr= {$i revision.inc};
    result:= vstr+inttostr(rstr)+'  '+cstr+'  '+dstr;
 end;


