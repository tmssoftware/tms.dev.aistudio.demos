unit UChangeText;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.ListBox, FMX.Controls.Presentation, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, TMS.MCP.CustomComponent, TMS.MCP.CloudBase,
  TMS.MCP.CloudImageAI, FMX.Edit;

type
  TForm3 = class(TForm)
    S: TPanel;
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
    Edit1: TEdit;
    Label2: TLabel;
    Button4: TButton;
    SaveDialog1: TSaveDialog;
    Timer1: TTimer;
    ProgressBar1: TProgressBar;
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
  Form3: TForm3;

implementation

uses
  TMS.MCP.Utils, UAPIKeys;

{$R *.fmx}

procedure TForm3.Button1Click(Sender: TObject);
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
  TMSMCPCloudImageAI1.Execute(Image2.Bitmap, Edit1.Text);
  Log('Changing text. Please wait, this might take a while.');

  EnableTimer(True);
end;

procedure TForm3.TMSMCPCloudImageAI1ImageGenerated(Sender: TObject;
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

procedure TForm3.UpdateSettings;
begin
  //Default timeout
  TMSMCPCloudImageAI1.Request.ReadTimeout := 30000;
  TMSMCPCloudImageAI1.Request.ConnectTimeout := 30000;

  case ComboBox1.ItemIndex of
    0:
    begin
      //OpenAI requires a higher timeout
      TMSMCPCloudImageAI1.Request.ReadTimeout := 600000;
      TMSMCPCloudImageAI1.Request.ConnectTimeout := 600000;
      TMSMCPCloudImageAI1.Service := isOpenAI;
      TMSMCPCloudImageAI1.Model := 'gpt-image-1.5';
      TMSMCPCloudImageAI1.APIKey := FOpenAI;
    end;
    1:
    begin
      TMSMCPCloudImageAI1.Service := isGemini;
      TMSMCPCloudImageAI1.Model := 'gemini-3-pro-image-preview';
      TMSMCPCloudImageAI1.APIKey := FGemini;
    end;
    2:
    begin
      TMSMCPCloudImageAI1.Service := isBFL;
      TMSMCPCloudImageAI1.Model := 'flux-2-flex';
      TMSMCPCloudImageAI1.APIKey := FBFL;
    end;
    3:
    begin
      TMSMCPCloudImageAI1.Service := isReve;
      TMSMCPCloudImageAI1.Model := 'reve-create@20250915';
      TMSMCPCloudImageAI1.APIKey := FReve;
    end;
  end;
end;

procedure TForm3.Timer1Timer(Sender: TObject);
var
  val: Integer;
begin
  val := Round(ProgressBar1.Value + 1) mod Round(ProgressBar1.Max);
  ProgressBar1.Value := val;
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    Image2.Bitmap.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm3.Button3Click(Sender: TObject);
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

procedure TForm3.Button4Click(Sender: TObject);
begin
  if not Image1.Bitmap.IsEmpty then
  begin
    if SaveDialog1.Execute then
      Image1.Bitmap.SaveToFile(SaveDialog1.FileName);

    SaveDialog1.FileName := '';
  end;
end;

procedure TForm3.EnableTimer(AValue: Boolean);
begin
  ProgressBar1.Value := 0;
  Timer1.Enabled := AValue;
  ProgressBar1.Visible := AValue;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  LoadKeys(FOpenAI, FGemini, FBFL, FStability, FReve);
  Image2.Bitmap.LoadFromFile('.\birthday_card.png');
  ComboBox1.ItemIndex := 0;
  SaveDialog1.InitialDir := ExtractFilePath(ParamStr(0));
end;

procedure TForm3.FormResize(Sender: TObject);
begin
  Image2.Width := Width / 2;
end;

procedure TForm3.Log(AText: string);
begin
  Memo1.Lines.Clear;
  Memo1.Text := AText;
end;

procedure TForm3.TMSMCPCloudImageAI1RequestError(Sender: TObject;
  ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  EnableTimer(False);
  Log(ARequestResult.ResultString);
end;

end.
