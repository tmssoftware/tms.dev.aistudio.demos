unit Umain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  TMS.MCP.ChatView, FMX.Controls.Presentation, FMX.StdCtrls,
  TMS.MCP.CustomComponent, TMS.MCP.CloudBase, TMS.MCP.CloudAI,
  FMX.ListBox, FMX.Edit;

type
  TForm3 = class(TForm)
    TMSMCPChatView1: TTMSMCPChatView;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Panel1: TPanel;
    ServiceLabel: TLabel;
    ServiceComboBox: TComboBox;
    APIKeyLabel: TLabel;
    APIKeyEdit: TEdit;
    InteractionsCheckBox: TCheckBox;
    ImageGenerationCheckBox: TCheckBox;
    FileGenerationCheckBox: TCheckBox;
    FeatureSupportLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ServiceComboBoxChange(Sender: TObject);
    procedure APIKeyEditChangeTracking(Sender: TObject);
    procedure FeatureCheckBoxChange(Sender: TObject);
  private
    FUpdatingAPIKey: Boolean;
    procedure LoadAPIKeys;
    function CurrentAPIKey: string;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

uses
  System.IOUtils;

{$R *.fmx}

procedure TForm3.FormCreate(Sender: TObject);
begin
  LoadAPIKeys;
  ServiceComboBox.Items.Assign(TMSMCPCloudAI1.GetServices);
  ServiceComboBox.ItemIndex := ServiceComboBox.Items.IndexOfObject(
    TObject(NativeInt(TMSMCPCloudAI1.Service)));
  ServiceComboBoxChange(ServiceComboBox);
  InteractionsCheckBox.IsChecked := TMSMCPChatView1.Interaction.EnableCloudAIInteractions;
  ImageGenerationCheckBox.IsChecked := TMSMCPChatView1.Interaction.EnableCloudAIImageGeneration;
  FileGenerationCheckBox.IsChecked := TMSMCPChatView1.Interaction.EnableCloudAIFileCreation;
end;

procedure TForm3.FeatureCheckBoxChange(Sender: TObject);
begin
  if Sender = InteractionsCheckBox then
    TMSMCPChatView1.Interaction.EnableCloudAIInteractions := InteractionsCheckBox.IsChecked
  else if Sender = ImageGenerationCheckBox then
    TMSMCPChatView1.Interaction.EnableCloudAIImageGeneration := ImageGenerationCheckBox.IsChecked
  else if Sender = FileGenerationCheckBox then
    TMSMCPChatView1.Interaction.EnableCloudAIFileCreation := FileGenerationCheckBox.IsChecked;
end;

procedure TForm3.LoadAPIKeys;
var
  Directory, ParentDirectory, FileName: string;
begin
  // Resolve from the executable so IDE and standalone launches behave alike.
  Directory := ExtractFilePath(ParamStr(0));
  while Directory <> '' do
  begin
    FileName := TPath.Combine(TPath.Combine(Directory, 'AI Language Models'),
      'aikeys.cfg');
    if TFile.Exists(FileName) then
    begin
      try
        TMSMCPCloudAI1.APIKeys.LoadFromFile(FileName, 'tmssoftware.com');
      except
        on E: Exception do
          ShowMessage('Unable to load the shared API keys. Enter a key below.' +
            sLineBreak + E.Message);
      end;
      Exit;
    end;
    if ExcludeTrailingPathDelimiter(Directory) =
      ExcludeTrailingPathDelimiter(TPath.GetPathRoot(Directory)) then
      Break;
    ParentDirectory := TDirectory.GetParent(ExcludeTrailingPathDelimiter(Directory));
    if ParentDirectory = Directory then
      Break;
    Directory := ParentDirectory;
  end;
end;

function TForm3.CurrentAPIKey: string;
begin
  Result := '';
  with TMSMCPCloudAI1 do
    case Service of
      aiOpenAI: Result := APIKeys.OpenAI;
      aiGemini: Result := APIKeys.Gemini;
      aiGrok: Result := APIKeys.Grok;
      aiClaude: Result := APIKeys.Claude;
      aiPerplexity: Result := APIKeys.Perplexity;
      aiMistral: Result := APIKeys.Mistral;
      aiDeepSeek: Result := APIKeys.DeepSeek;
      aiOpenRouter: Result := APIKeys.OpenRouter;
    end;
end;

procedure TForm3.ServiceComboBoxChange(Sender: TObject);
begin
  if ServiceComboBox.ItemIndex < 0 then
    Exit;

  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(NativeInt(
    ServiceComboBox.Items.Objects[ServiceComboBox.ItemIndex]));
  FUpdatingAPIKey := True;
  try
    APIKeyEdit.Enabled := not (TMSMCPCloudAI1.Service in [aiOllama, aiLlamaCpp]);
    APIKeyEdit.Text := CurrentAPIKey;
    if APIKeyEdit.Enabled then
      APIKeyEdit.TextPrompt := 'Enter API key'
    else
      APIKeyEdit.TextPrompt := 'No API key required for local services';
  finally
    FUpdatingAPIKey := False;
  end;
end;

procedure TForm3.APIKeyEditChangeTracking(Sender: TObject);
var
  Key: string;
begin
  if FUpdatingAPIKey then
    Exit;

  // Keep manual changes in memory; the shared key file is managed by API Keys.
  Key := Trim(APIKeyEdit.Text);
  with TMSMCPCloudAI1 do
    case Service of
      aiOpenAI: APIKeys.OpenAI := Key;
      aiGemini: APIKeys.Gemini := Key;
      aiGrok: APIKeys.Grok := Key;
      aiClaude: APIKeys.Claude := Key;
      aiPerplexity: APIKeys.Perplexity := Key;
      aiMistral: APIKeys.Mistral := Key;
      aiDeepSeek: APIKeys.DeepSeek := Key;
      aiOpenRouter: APIKeys.OpenRouter := Key;
    end;
end;

end.
