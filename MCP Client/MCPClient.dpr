program MCPClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  UMain in 'UMain.pas' {FormMain},
  UMCPClient in 'UMCPClient.pas' {DM: TDataModule},
  ULogs in 'ULogs.pas' {FormLog};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TFormMain, FormMain);
  //Application.CreateForm(TFormLog, FormLog);
  Application.Run;
end.
