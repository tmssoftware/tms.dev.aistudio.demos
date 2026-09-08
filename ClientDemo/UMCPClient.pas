unit UMCPClient;

interface

uses
  System.SysUtils, System.Classes, TMS.MCP.Client, TMS.MCP.CustomDialog,
  TMS.MCP.Client.SettingsDialog, TMS.MCP.CustomComponent;

type
  TDM = class(TDataModule)
    MCPClient: TTMSMCPClient;
    SettingsDialog: TTMSMCPClientSettingsDialog;
    procedure SettingsDialogAPIKeysChanged(Sender: TObject);
    procedure SettingsDialogServersChanged(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DM: TDM;

implementation

uses
  IniFiles;

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDM.SettingsDialogAPIKeysChanged(Sender: TObject);
var
  ini: TiniFile;
  fn: string;
begin
  fn := ChangeFileExt(ParamStr(0),'.ini');
  MCPClient.LLM.APIKeys.SaveToFile(fn, ParamStr(0));
  ini := TiniFile.Create(fn);
  try
    ini.WriteString('Settings', 'OllamaHost', MCPClient.LLM.Settings.OllamaHost);
    ini.WriteInteger('Settings', 'OllamaPort', MCPClient.LLM.Settings.OllamaPort);
  finally
    ini.Free;
  end;
end;

procedure TDM.SettingsDialogServersChanged(Sender: TObject);
begin
  MCPClient.Servers.SaveToJSONFile(ChangeFileExt(ParamStr(0),'-config.json'));
end;

end.
