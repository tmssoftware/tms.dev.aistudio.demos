unit UMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Memo.Types, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.ListView, FMX.ListBox, TMS.MCP.CloudAI,
  FMX.Objects, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.TMSFNCCustomControl, FMX.TMSFNCTableView,
  FMX.TMSFNCChat, FMX.TMSFNCWaitingIndicator, ULogs, UMCPClient, TMS.MCP.Client,
  System.JSON;

type
  TFormMain = class(TForm)
    lblTitle: TLabel;
    memAsk: TMemo;
    btnAsk: TButton;
    cbModel: TComboBox;
    chatAI: TTMSFNCChat;
    btnSettings: TButton;
    btnToolsLog: TButton;
    pbWait: TTMSFNCWaitingIndicator;
    lblWarn: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnAskClick(Sender: TObject);
    procedure cbModelChange(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnToolsLogClick(Sender: TObject);
    procedure memAskKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
  private
    { Private declarations }
    procedure MCPClientLog(Sender: TObject; AServer: TTMSMCPClientServerItem; ATimeStamp: TDateTime; ALevel: TTMSMCPLoggingLevel; AMessage: string);
    procedure MCPClientExecuted(Sender: TObject; AResponse: string; AHttpStatusCode: Integer; AHttpResult: string);
  public
    { Public declarations }
    procedure LoadSettings;
    procedure LoadServers;
    procedure CheckAPIKey;
    procedure ScrollToBottom;
    procedure ShowLoading(AShow: Boolean);
    procedure SendToAI;
  end;

var
  FormMain: TFormMain;

implementation

uses
  IniFiles, IOUtils,
  FMX.TextLayout;

{$R *.fmx}

procedure TFormMain.btnAskClick(Sender: TObject);
begin
  SendToAI;
end;

procedure TFormMain.btnSettingsClick(Sender: TObject);
begin
  DM.SettingsDialog.Execute;
end;

procedure TFormMain.btnToolsLogClick(Sender: TObject);
begin
  FormLog.Show;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;

  chatAI.Clear;
  chatAI.EmojiList.Clear;

  DM.MCPClient.OnExecuted := MCPClientExecuted;
  DM.MCPClient.OnLog := MCPClientLog;

  Application.CreateForm(TFormLog, FormLog);
  LoadSettings;
  LoadServers;
end;

procedure TFormMain.LoadServers;
var
  I: Integer;
begin
  if TFile.Exists(ChangeFileExt(ParamStr(0),'-config.json')) then
    DM.MCPClient.Servers.LoadFromJSONFile(ChangeFileExt(ParamStr(0),'-config.json'));

  for I := 0 to DM.MCPClient.Servers.Count - 1 do
    DM.MCPClient.Servers[I].Start;
end;

procedure TFormMain.LoadSettings;
var
  ini: TiniFile;
  fn: string;
begin
  fn := ChangeFileExt(ParamStr(0),'.ini');
  ini := TiniFile.Create(fn);
  try
    DM.MCPClient.LLM.Settings.OllamaHost := ini.ReadString('Settings', 'OllamaHost', 'localhost');
    DM.MCPClient.LLM.Settings.OllamaPort := ini.ReadInteger('Settings', 'OllamaPort', 11434);
  finally
    ini.Free;
  end;
  DM.MCPClient.LLM.APIKeys.LoadFromFile(fn, ParamStr(0));
end;

procedure TFormMain.MCPClientExecuted(Sender: TObject;
  AResponse: string; AHttpStatusCode: Integer;
  AHttpResult: string);
var
  itm: TTMSFNCChatItem;
begin
  if AResponse <> '' then
  begin
    itm := chatAI.ChatMessages.Add;
    itm.Text := AResponse;
    itm.MessageLocation := cmlLeft;
    ScrollToBottom;

    ShowLoading(False);
  end;
end;

procedure TFormMain.MCPClientLog(Sender: TObject; AServer: TTMSMCPClientServerItem;
  ATimeStamp: TDateTime; ALevel: TTMSMCPLoggingLevel; AMessage: string);
var
  lvl, s: string;
begin
  case ALevel of
    llDebug: lvl := '[DEBUG] ';
    llInfo: lvl := '[INFO] ';
    llNotice: lvl := '[NOTICE] ';
    llWarning: lvl := '[WARNING] ';
    llError: lvl := '[ERROR] ';
    llCritical: lvl := '[CRITICAL] ';
    llAlert: lvl := '[ALERT] ';
    llEmergency: lvl := '[EMERGENCY] ';
  end;

  s := '';
  if Assigned(AServer) and (AServer.ServerName <> '') then
    s := ' (Calling server: ' + AServer.ServerName + ')';

  FormLog.Add(lvl + DateTimeToStr(ATimeStamp) + ': ' + AMessage + s);
end;

procedure TFormMain.memAskKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: WideChar; Shift: TShiftState);
begin
  if (Shift = []) and (Key = vkReturn) then
  begin
    SendToAI;
    Key := 0;
    KeyChar := #0;
  end;
end;

procedure TFormMain.SendToAI;
var
  itm: TTMSFNCChatItem;
begin
  itm := chatAI.ChatMessages.Add;
  itm.Text := memAsk.Text;
  itm.MessageLocation := cmlRight;
  itm.Fill.Color := gcDodgerblue;
  itm.TextColor := gcWhite;
  ScrollToBottom;

  DM.MCPClient.Execute(memAsk.Text);
  memAsk.Lines.Clear;

  ShowLoading(True);
end;

procedure TFormMain.ShowLoading(AShow: Boolean);
var
  c: TCursor;
begin
  pbWait.Active := AShow;
  pbWait.Visible := AShow;

  if AShow then
    c := crHourGlass
  else
    c := crDefault;

  Cursor := c;
  chatAI.Cursor := c;
  memAsk.Cursor := c;
  btnAsk.Cursor := c;
  btnSettings.Cursor := c;
  btnToolsLog.Cursor := c;
  cbModel.Cursor := c;
  pbWait.Cursor := c;
end;

procedure TFormMain.cbModelChange(Sender: TObject);
begin
  case cbModel.ItemIndex of
    0: DM.MCPClient.LLM.Service := aiOpenAI;
    1: DM.MCPClient.LLM.Service := aiGemini;
    2: DM.MCPClient.LLM.Service := aiClaude;
    3: DM.MCPClient.LLM.Service := aiGrok;
    4: DM.MCPClient.LLM.Service := aiMistral;
    5: DM.MCPClient.LLM.Service := aiDeepSeek;
    6: DM.MCPClient.LLM.Service := aiOllama;
  end;

  CheckAPIKey;
end;

procedure TFormMain.CheckAPIKey;
var
  key: string;
begin
  case DM.MCPClient.LLM.Service of
    aiOpenAI: key := DM.MCPClient.LLM.APIKeys.OpenAI;
    aiGemini: key := DM.MCPClient.LLM.APIKeys.Gemini;
    aiClaude: key := DM.MCPClient.LLM.APIKeys.Claude;
    aiGrok: key := DM.MCPClient.LLM.APIKeys.Grok;
    aiMistral: key := DM.MCPClient.LLM.APIKeys.Mistral;
    aiDeepSeek: key := DM.MCPClient.LLM.APIKeys.DeepSeek;
    aiOllama: key := DM.MCPClient.LLM.Settings.OllamaHost;
  end;

  btnAsk.Enabled := key <> '';
  memAsk.Enabled := key <> '';
  lblWarn.Visible := key = '';
end;

procedure TFormMain.ScrollToBottom;
var
  I: Integer;
begin
  for I := 0 to chatAI.ChatMessages.Count - 1 do
    chatAI.ScrollToItem(I);
end;


end.
