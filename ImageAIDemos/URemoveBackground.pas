unit URemoveBackground;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.ListBox, FMX.Controls.Presentation, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, TMS.MCP.CustomComponent, TMS.MCP.CloudBase,
  TMS.MCP.CloudImageAI;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Button1: TButton;
    Image1: TImage;
    Image2: TImage;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    Panel2: TPanel;
    Memo1: TMemo;
    Label1: TLabel;
    TMSMCPCloudImageAI1: TTMSMCPCloudImageAI;
    Button3: TButton;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    Button4: TButton;
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudImageAI1ImageGenerated(Sender: TObject;
      ARequestResult: TTMSMCPCloudBaseRequestResult; ABase64Image: string);
    procedure Button3Click(Sender: TObject);
    procedure TMSMCPCloudImageAI1RequestError(Sender: TObject;
      ARequestResult: TTMSMCPCloudBaseRequestResult);
    procedure Timer1Timer(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    FOpenAI, FGemini, FBFL, FStability, FReve: string;
    procedure Log(AText: string);
    procedure UpdateSettings;
    procedure EnableTimer(AValue: Boolean);
  end;

var
  Form2: TForm2;

implementation

uses
  TMS.MCP.Utils, UAPIKeys;

{$R *.fmx}

procedure TForm2.Button1Click(Sender: TObject);
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

  //Generate new image
  TMSMCPCloudImageAI1.RemoveBackground(Image2.Bitmap);
  Log('Removing background. Please wait, this might take a while.');

  EnableTimer(True);
end;

procedure TForm2.TMSMCPCloudImageAI1ImageGenerated(Sender: TObject;
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

procedure TForm2.UpdateSettings;
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

procedure TForm2.Timer1Timer(Sender: TObject);
var
  val: Integer;
begin
  val := Round(ProgressBar1.Value + 1) mod Round(ProgressBar1.Max);
  ProgressBar1.Value := val;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    Image2.Bitmap.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm2.Button3Click(Sender: TObject);
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

procedure TForm2.Button4Click(Sender: TObject);
begin
  if not Image1.Bitmap.IsEmpty then
  begin
    if SaveDialog1.Execute then
      Image1.Bitmap.SaveToFile(SaveDialog1.FileName);

    SaveDialog1.FileName := '';
  end;
end;

procedure TForm2.EnableTimer(AValue: Boolean);
begin
  ProgressBar1.Value := 0;
  Timer1.Enabled := AValue;
  ProgressBar1.Visible := AValue;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  LoadKeys(FOpenAI, FGemini, FBFL, FStability, FReve);
  Image2.Bitmap.LoadFromFile('.\teddy_bear.png');
  ComboBox1.ItemIndex := 0;
  SaveDialog1.InitialDir := ExtractFilePath(ParamStr(0));
end;

procedure TForm2.FormResize(Sender: TObject);
begin
  Image2.Width := Width / 2;
end;

procedure TForm2.Log(AText: string);
begin
  Memo1.Lines.Clear;
  Memo1.Text := AText;
end;

procedure TForm2.TMSMCPCloudImageAI1RequestError(Sender: TObject;
  ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  EnableTimer(False);
  Log(ARequestResult.ResultString);
end;

end.
