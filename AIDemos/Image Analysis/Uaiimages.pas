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

unit Uaiimages;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.StdCtrls, TMS.MCP.CustomComponent, FMX.Memo.Types,
  FMX.ListBox;

type
  TForm1 = class(TForm)
    Button1: TButton;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    OpenDialog1: TOpenDialog;
    Button3: TButton;
    ComboBox1: TComboBox;
    ProgressBar1: TProgressBar;
    Timer1: TTimer;
    Button2: TButton;
    Button4: TButton;
    Memo1: TMemo;
    ImageControl1: TImageControl;
    ImageControl2: TImageControl;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ComboBox1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  timer1.Enabled := true;
  TMSMCPCloudAI1.Files.Clear;
  TMSMCPCloudAI1.AddFile(fname1, aiftImage);
  TMSMCPCloudAI1.AddFile(fname2, aiftImage);
  TMSMCPCloudAI1.Context.Clear;
  TMSMCPCloudAI1.Context.Text := 'compare the two pictures and describe the differences';
  TMSMCPCloudAI1.Execute;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  timer1.Enabled := true;
  TMSMCPCloudAI1.Files.Clear;
  TMSMCPCloudAI1.AddFile(fname1, aiftImage);
  TMSMCPCloudAI1.Context.Clear;
  TMSMCPCloudAI1.Context.Text := 'describe the picture';
  TMSMCPCloudAI1.Execute;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if opendialog1.Execute then
  begin
    fname2 := opendialog1.FileName;
    ImageControl2.Bitmap.LoadFromFile(opendialog1.FileName);
  end;
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
  TMSMCPCloudAI1.LogFileName := '.\..\..\aiimages.log';

  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\..\aikeys.cfg','tmssoftware.com');
  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices(true));
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);

  TMSMCPCloudAI1.Settings.MistralModel := 'mistral-small-2503';

  //Define the model that you downloaded to llama.cpp
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
