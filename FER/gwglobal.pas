unit GWGlobal;

{$mode objfpc}{$H+}

interface

uses
  TLoggerUnit, GWAppender, INIFiles,
  Classes, SysUtils,
  IECList;

type

 Tproc = (item,server);

 TProcess = record
   o:Tobject;
   name:String;
   hint:String;
 end;

var
  Logger : TLogger;
   GWapp:TGWAppender;
   INI:TINIFile;
//  Items : TIECList;
//  IList : TIECList;
  IList : TIECList;
  Process : Array[Tproc] of Tprocess;

implementation

uses TConfiguratorUnit, TFileAppenderUnit, TLevelUnit, TypInfo;

var
 Fapp:TFileAppender;
 Proc: Tproc;
// GWapp:TGWAppender;

procedure initProcs;
begin
 for Proc:=low(TProc) to high(TProc) do
         begin
         Process[proc].name:=GetEnumName(TypeInfo(proc), integer(proc));
         Process[proc].hint:=ini.ReadString(Process[proc].name,'Description','??');
         case proc of
           item:begin
                IList := TIECList.create();
                IList.Logger:=TLogger.getInstance(Process[proc].name);
                IList.Logger.setLevel(TLevelUnit.INFO);
                if assigned(Fapp) then
                   IList.Logger.AddAppender(Fapp);
                logger.Info('add Logger to '+Process[proc].name);
                IList.Logger.AddAppender(Gwapp);
                Process[proc].o:=IList;
                end;
           else  Process[proc].o:=nil;
         end;
         end;
// Process[item].o:=TIECList.create() ;
// IList := TIECList.create();
// IList := TIECList (Process[item].o);
 if Process[item].o.ClassType=TIECList then
     writeln('GLOBAL_item')
 else
    writeln('GLOBAL_Object')
end;

procedure destroy;
begin
 for Proc:=low(TProc) to high(TProc) do
     begin
     if (Process[proc].o<>nil) then
         Process[proc].o.destroy;
     end;
end;

Initialization
  begin
  tconfiguratorunit.doBasicConfiguration;
  logger := TLogger.getInstance;
 // logger.setLevel(TLevelUnit.Warn);
  logger.setLevel(TLevelUnit.INFO);

  INI:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'iecgw.ini');

  Fapp:=nil;
  if ini.ReadBool('logging','logToFile',false) then
    begin
      Fapp := TFileAppender.Create(ini.ReadString('logging','File',ExtractFilePath(ParamStr(0))+'IECGW.log'));
      logger.addAppender(Fapp);
    end ;
  GWapp := TGWAppender.Create;

//  initProcs;
  end;

finalization
  destroy;
  ini.Destroy;
end.

