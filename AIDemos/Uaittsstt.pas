unit Uaittsstt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, AudioRecorder,
  TMS.MCP.CustomComponent, TMS.MCP.CloudBase, TMS.MCP.CloudAI;

type
  TForm3 = class(TForm)
    Memo1: TMemo;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Memo2: TMemo;
    PaintBox1: TPaintBox;
    ComboBox1: TComboBox;
    btnTranslate: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PaintBox1Click(Sender: TObject);
    procedure TMSMCPCloudAI1TranscribeAudio(Sender: TObject;
      HttpStatusCode: Integer; HttpResult, Text: string);
    procedure TMSMCPCloudAI1SpeechAudio(Sender: TObject;
      HttpStatusCode: Integer; HttpResult: string; SoundBuffer: TMemoryStream);
    procedure btnTranslateClick(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private
    { Private declarations }
     FIsSpeaking: Boolean;
  public
    { Public declarations }
    ar: TAudioRecorder;
    procedure DoTranslate(Text, Language: string);
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}
uses
  Math;

procedure DrawToggleButton(ACanvas: TCanvas; const R: TRect; IsSpeaking: Boolean);
var
  size, pad, cx, cy, radius: Integer;
  circleRect, calcRect: TRect;
  textStr: string;
  bgColor: TColor;
  oldBkMode,h: Integer;
  flags: Longint;
begin
  // Background
  ACanvas.Brush.Color := clBtnFace;
  ACanvas.FillRect(R);

  // Make a centered circle that fits the paintbox
  pad := MulDiv(12, ACanvas.Font.PixelsPerInch, 96); // scale padding with DPI
  size := Min(R.Width, R.Height) - pad * 2;
  if size < 10 then Exit;
  cx := (R.Left + R.Right) div 2;
  cy := (R.Top  + R.Bottom) div 2;
  radius := size div 2;
  circleRect := Rect(cx - radius, cy - radius, cx + radius, cy + radius);

  // Colors & text for the current state
  if IsSpeaking then
  begin
    bgColor := RGB(244, 67, 54);   // red
    textStr := 'Stop';
  end
  else
  begin
    bgColor := RGB(76, 175, 80);   // green
    textStr := 'Click to'#13#10'Speak';
  end;

  // Draw filled circle with a subtle border
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := bgColor;
  ACanvas.Pen.Color := RGB(0, 0, 0);
  ACanvas.Pen.Width := 2;
  ACanvas.Ellipse(circleRect);

  // Button text (centered)
  ACanvas.Font.Color := clWhite;
  ACanvas.Font.Style := [fsBold];

  // Scale font roughly with circle size
  ACanvas.Font.Height := -Max(12, size div 6); // negative = height in pixels

  oldBkMode := SetBkMode(ACanvas.Handle, TRANSPARENT);
  try
    flags := DT_CENTER or DT_WORDBREAK or DT_CALCRECT;
    calcRect := circleRect;
    h := DrawText(ACanvas.Handle, PChar(textStr), Length(textStr), calcRect, flags);

    h := (circleRect.Bottom - circleRect.Top - h) div 2;
    circleRect.Top := circleRect.Top + h;

    flags := DT_CENTER or DT_WORDBREAK;
    DrawText(ACanvas.Handle, PChar(textStr), Length(textStr), circleRect, flags);
  finally
    SetBkMode(ACanvas.Handle, oldBkMode);
  end;
end;


procedure TForm3.btnTranslateClick(Sender: TObject);
begin
  DoTranslate(Memo1.Lines.Text, ComboBox1.Text);
end;

procedure TForm3.DoTranslate(Text, Language: string);
begin
  TMSMCPCloudAI1.AssistantRole.Text := 'You are a translator that literally translates this text to '+ Language;
  TMSMCPCloudAI1.Context.Text := Text;
  TMSMCPCloudAI1.Execute('abc');
end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ar.Free;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := true;
  FIsSpeaking := false;

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\aikeys.cfg','tmssoftware.com');

  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\tts_stt.log';

  TMSMCPCloudAI1.Service := aiOpenAI;

  ar := TAudioRecorder.Create;
end;

procedure TForm3.Memo1Change(Sender: TObject);
begin
  btnTranslate.Enabled := memo1.Lines.Text <> '';
end;

procedure TForm3.PaintBox1Click(Sender: TObject);
var
  s: TMemoryStream;
begin
  if not FIsSpeaking then
  begin
    ar.ClearRecordedData;
    ar.StartRecording;
  end
  else
  begin
    ar.StopRecording;
    s := ar.GetMP3Stream(20500);
    s.Position := 0;
    TMSMCPCloudAI1.Transcribe(s);
    s.Free;
  end;

  FIsSpeaking := not FIsSpeaking;  // toggle state
  PaintBox1.Invalidate;            // repaint with new state
end;

procedure TForm3.PaintBox1Paint(Sender: TObject);
begin
  DrawToggleButton(PaintBox1.Canvas, PaintBox1.ClientRect, FIsSpeaking);
end;

procedure TForm3.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  if ahttpstatuscode div 100 = 2 then
  begin
    memo2.Lines.Text := AResponse.Content.Text;
    TMSMCPCloudAI1.Speak(memo2.Lines.Text);
  end
  else
    memo2.Lines.Text := AHttpResult;
end;

procedure TForm3.TMSMCPCloudAI1SpeechAudio(Sender: TObject;
  HttpStatusCode: Integer; HttpResult: string; SoundBuffer: TMemoryStream);
begin
  if Assigned(ar) then
    ar.PlayMP3FromStream(SoundBuffer);
end;

procedure TForm3.TMSMCPCloudAI1TranscribeAudio(Sender: TObject;
  HttpStatusCode: Integer; HttpResult, Text: string);
begin
  if HttpStatusCode div 100 =  2 then
  begin
    memo1.Lines.Text := Text;

    if ComboBox1.Text <> '' then
      DoTranslate(Text, ComboBox1.Text);
  end
  else
    memo1.Lines.Text := 'Error ' + HttpStatusCode.ToString+ ' ' + HttpResult;
end;

end.
