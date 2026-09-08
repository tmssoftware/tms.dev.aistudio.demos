{********************************************************************}
{                                                                    }
{ written by TMS Software                                            }
{            copyright (c) 2025 - 2026                               }
{            Email : info@tmssoftware.com                            }
{            Web : http://www.tmssoftware.com                        }
{                                                                    }
{ The source code is given as is. The author is not responsible      }
{ for any possible damage done due to the use of this code.          }
{ The complete source code remains property of the author and may    }
{ not be distributed, published, given or sold in any form as such.  }
{ No parts of the source code can be included in any other component }
{ or application without written authorization of the author.        }
{********************************************************************}

unit Uaiocr;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.ListBox, TMS.MCP.CustomComponent, FMX.Memo.Types;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    Panel1: TPanel;
    Button1: TButton;
    Button3: TButton;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Panel2: TPanel;
    ComboBox1: TComboBox;
    ProgressBar1: TProgressBar;
    Splitter1: TSplitter;
    ImageControl1: TImageControl;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ComboBox1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    fname1: string;
    fname2: string;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if opendialog1.Execute then
  begin
    fname1 := opendialog1.FileName;
    ImageControl1.Bitmap.LoadFromFile(opendialog1.FileName);
    ImageControl1.Bitmap.Rotate(+90);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  timer1.Enabled := true;
  TMSMCPCloudAI1.AddFile(fname1, aiftImage);
  TMSMCPCloudAI1.Context.Clear;
  TMSMCPCloudAI1.Context.Text := 'extract the text from the picture';
  TMSMCPCloudAI1.Execute;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  i: integer;
begin
  if ComboBox1.ItemIndex = -1 then
    Exit;

  i := integer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(i);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aiocr.log';
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\aikeys.cfg','tmssoftware.com');
  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices);
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);

  TMSMCPCloudAI1.Settings.GeminiModel := 'gemini-2.0-flash-exp';
  TMSMCPCloudAI1.Settings.GrokModel := 'grok-2-vision-latest';
  TMSMCPCloudAI1.Settings.MistralModel := 'mistral-small-2503';
  TMSMCPCloudAI1.Settings.OllamaModel := 'llama3.2-vision';
  TMSMCPCloudAI1.Settings.OllamaPath := 'api/generate';

  //Define the model that you downloaded to llama.cpp
  //TMSMCPCloudAI1.Settings.LlamaCppModel := '';

  //Note: You might need to increase the timeout depending the speed you can
  //      run local models with your machine
  //TMSMCPCloudAI1.Request.ConnectTimeout := 600000;

  TMSMCPCloudAI1.Request.ReadTimeout := 600000;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if progressbar1.Value = 100 then
    ProgressBar1.Value := 0
  else
    ProgressBar1.Value := ProgressBar1.Value + 1;
end;

procedure TForm1.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  Memo1.Lines.Clear;
  timer1.Enabled := false;
  ProgressBar1.Value := 0;
  if AHttpStatusCode = 200 then
    Memo1.Lines.Text := AResponse.Content.Text
  else
  begin
    Memo1.Lines.Text := AHttpResult;
    ShowMessage('Error processing request:'+ AHttpStatusCode.ToString);
  end;
end;

end.
