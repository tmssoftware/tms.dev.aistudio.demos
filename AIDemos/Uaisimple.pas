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
unit Uaisimple;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI, Vcl.ExtCtrls, Vcl.ComCtrls,
  TMS.MCP.CustomComponent;

type
  TForm1 = class(TForm)
    Memo2: TMemo;
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Memo1: TMemo;
    Button1: TButton;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    ProgressBar1: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  TMSMCPCloudAI1.Context.Text := Memo1.Text;
  TMSMCPCloudAI1.Execute();
  ProgressBar1.State := pbsNormal;
  memo2.Lines.Clear;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  i: integer;
begin
  i := integer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(i);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aisimple.log';
  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\aikeys.cfg','tmssoftware.com');

  { latest models
  TMSMCPCloudAI1.Settings.ClaudeModel := 'claude-opus-4-20250514';
  TMSMCPCloudAI1.Settings.GeminiModel := 'gemini-2.5-pro-preview-tts';
  TMSMCPCloudAI1.Settings.MistralModel := 'mistral-medium-latest';
  }
  
  //Define the model that you downloaded to llama.cpp
  //TMSMCPCloudAI1.Settings.LlamaCppModel := '';

  //Note: You might need to increase the timeout depending the speed you can
  //      run local models with your machine
  //TMSMCPCloudAI1.Request.ConnectTimeout := 600000;
  //TMSMCPCloudAI1.Request.ReadTimeout := 600000;


  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices);
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);
end;

procedure TForm1.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  ProgressBar1.State := pbsPaused;
  if AHttpStatusCode = 200 then
  begin
    memo2.Text := AResponse.Content.Text;
  end
  else
    ShowMessage('HTTP error code: '+AHttpStatusCode.ToString+#13#13+ AHttpResult);

end;

end.
