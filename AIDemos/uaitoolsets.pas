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

unit uaitoolsets;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, VCL.TMSFNCCustomComponent, TMS.MCP.CloudBase,
  TMS.MCP.CloudAI, TMS.MCP.CloudAIToolSets, TMS.MCP.CustomComponent;

type
  TForm1 = class(TForm)
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Button1: TButton;
    Memo1: TMemo;
    ProgressBar1: TProgressBar;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    fs: TTMSMCPCloudAIFileSystem;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  ProgressBar1.State := pbsNormal;

  TMSMCPCloudAI1.Context.Text := Memo1.Lines.Text;
  TMSMCPCloudAI1.Execute();
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
  ReportMemoryLeaksOnShutdown := true;

  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aitoolsets.log';

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\aikeys.cfg','tmssoftware.com');

  fs := TTMSMCPCloudAIFileSystem.Create(Self);
  fs.AI := TMSMCPCloudAI1;

  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices(false, false));
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(Self);
  
  //Define the model that you downloaded to llama.cpp
  //TMSMCPCloudAI1.Settings.LlamaCppModel := '';

  //Note: You might need to increase the timeout depending the speed you can
  //      run local models with your machine
  //TMSMCPCloudAI1.Request.ConnectTimeout := 500000;
  //TMSMCPCloudAI1.Request.ReadTimeout := 500000;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  fs.Free;
end;

procedure TForm1.TMSMCPCloudAI1Executed(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  ProgressBar1.State := pbsPaused;
  if AHttpStatusCode div 100 = 2 then
  begin
    Memo2.Lines.Text := AResponse.Content.Text;
  end
  else
    Memo2.Lines.Text := 'HTTP Status code: '+ AHttpStatusCode.ToString +' : ' + AHttpResult;
end;

end.
