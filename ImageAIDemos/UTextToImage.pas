unit UTextToImage;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ListBox, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation,
  FMX.Objects, TMS.MCP.CustomComponent, TMS.MCP.CloudBase, TMS.MCP.CloudImageAI;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Memo1: TMemo;
    ComboBox1: TComboBox;
    Panel2: TPanel;
    Memo2: TMemo;
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    TMSMCPCloudImageAI1: TTMSMCPCloudImageAI;
    Button2: TButton;
    Button3: TButton;
    SaveDialog1: TSaveDialog;
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure TMSMCPCloudImageAI1ImageGenerated(Sender: TObject;
      ARequestResult: TTMSMCPCloudBaseRequestResult; ABase64Image: string);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudImageAI1RequestError(Sender: TObject;
      ARequestResult: TTMSMCPCloudBaseRequestResult);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    FOpenAI, FGemini, FBFL, FStability, FReve: string;
    procedure Log(AText: string);
    procedure UpdateSettings;
    procedure EnableTimer(AValue: Boolean);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  TMS.MCP.Utils, UAPIKeys;

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  //Clear current image
  Image1.Bitmap.Clear(TAlphaColorRec.Null);

  //Update settings
  UpdateSettings;

  if TMSMCPCloudImageAI1.APIKey = '' then
  begin
    ShowMessage('Please fill in the API key');
    Exit;
  end;

  //Generate new
  TMSMCPCloudImageAI1.Execute(Memo1.Text);
  Log('Generating image. Please wait, this might take a while.');

  EnableTimer(True);
end;

procedure TForm1.TMSMCPCloudImageAI1ImageGenerated(Sender: TObject;
  ARequestResult: TTMSMCPCloudBaseRequestResult; ABase64Image: string);
var
  strm: TMemoryStream;
begin
  strm := TMemoryStream.Create;
  try
    TTMSMCPUtils.LoadStreamFromBase64(ABase64Image, strm);

    strm.Position := 0;
    Image1.Bitmap.LoadFromStream(strm);
  finally
    strm.Free;
  end;

  EnableTimer(False);
  Log('Done!');
end;

procedure TForm1.UpdateSettings;
var
  i: Integer;
begin
  i := ComboBox1.ItemIndex;
  TMSMCPCloudImageAI1.Service := TTMSMCPCloudImageAIService(i);

  //Default timeout
  TMSMCPCloudImageAI1.Request.ReadTimeout := 30000;
  TMSMCPCloudImageAI1.Request.ConnectTimeout := 30000;

  case TMSMCPCloudImageAI1.Service of
    isOpenAI:
    begin
      //OpenAI requires a higher timeout
      TMSMCPCloudImageAI1.Request.ReadTimeout := 600000;
      TMSMCPCloudImageAI1.Request.ConnectTimeout := 600000;
      TMSMCPCloudImageAI1.Model := 'gpt-image-1.5';
      TMSMCPCloudImageAI1.APIKey := FOpenAI;
    end;
    isGemini:
    begin
      TMSMCPCloudImageAI1.Model := 'gemini-3-pro-image-preview';
      TMSMCPCloudImageAI1.APIKey := FGemini;
    end;
    isBFL:
    begin
      TMSMCPCloudImageAI1.Model := 'flux-2-flex';
      TMSMCPCloudImageAI1.APIKey := FBFL;
    end;
    isStability:
    begin
      TMSMCPCloudImageAI1.Model := 'ultra';
      TMSMCPCloudImageAI1.APIKey := FStability;
    end;
    isReve:
    begin
      TMSMCPCloudImageAI1.Model := 'reve-create@20250915';
      TMSMCPCloudImageAI1.APIKey := FReve;
    end;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  frm: TKeysForm;
begin
  frm := TKeysForm.Create(Self);
  try
    frm.ShowModal;
  finally
    frm.Free;
  end;

  LoadKeys(FOpenAI, FGemini, FBFL, FStability, FReve);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  val: Integer;
begin
  val := Round(ProgressBar1.Value + 1) mod Round(ProgressBar1.Max);
  ProgressBar1.Value := val;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if not Image1.Bitmap.IsEmpty then
  begin
    if SaveDialog1.Execute then
      Image1.Bitmap.SaveToFile(SaveDialog1.FileName);

    SaveDialog1.FileName := '';
  end;
end;

procedure TForm1.EnableTimer(AValue: Boolean);
begin
  ProgressBar1.Value := 0;
  Timer1.Enabled := AValue;
  ProgressBar1.Visible := AValue;
  SaveDialog1.InitialDir := ExtractFilePath(ParamStr(0));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LoadKeys(FOpenAI, FGemini, FBFL, FStability, FReve);
  ComboBox1.ItemIndex := 0;
end;

procedure TForm1.Log(AText: string);
begin
  Memo2.Lines.Clear;
  Memo2.Text := AText;
end;

procedure TForm1.TMSMCPCloudImageAI1RequestError(Sender: TObject;
  ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  EnableTimer(False);
  Log(ARequestResult.ResultString);
end;

end.
