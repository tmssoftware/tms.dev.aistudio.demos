{********************************************************************}
{                                                                    }
{ written by TMS Software                                            }
{            copyright (c) 2025                                      }
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
unit Uaikeys;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, TMS.MCP.CustomComponent,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI;

type
  TForm2 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Edit4: TEdit;
    Label4: TLabel;
    Edit5: TEdit;
    Label5: TLabel;
    Edit6: TEdit;
    Label6: TLabel;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    Edit7: TEdit;
    Label7: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LoadKeys;
    procedure SaveKeys;
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
begin
  LoadKeys;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  SaveKeys;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  LoadKeys;
end;

procedure TForm2.LoadKeys;
begin

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\aikeys.cfg','tmssoftware.com');

  Edit1.Text := TMSMCPCloudAI1.APIKeys.Claude;
  Edit2.Text := TMSMCPCloudAI1.APIKeys.DeepSeek;
  Edit3.Text := TMSMCPCloudAI1.APIKeys.Gemini;
  Edit4.Text := TMSMCPCloudAI1.APIKeys.Grok;
  Edit5.Text := TMSMCPCloudAI1.APIKeys.Mistral;
  Edit6.Text := TMSMCPCloudAI1.APIKeys.OpenAI;
  Edit7.Text := TMSMCPCloudAI1.APIKeys.Perplexity;
end;

procedure TForm2.SaveKeys;
begin
  TMSMCPCloudAI1.APIKeys.Claude := Edit1.Text;
  TMSMCPCloudAI1.APIKeys.DeepSeek := Edit2.Text;
  TMSMCPCloudAI1.APIKeys.Gemini := Edit3.Text;
  TMSMCPCloudAI1.APIKeys.Grok := Edit4.Text;
  TMSMCPCloudAI1.APIKeys.Mistral := Edit5.Text;
  TMSMCPCloudAI1.APIKeys.OpenAI := Edit6.Text;
  TMSMCPCloudAI1.APIKeys.Perplexity := Edit7.Text;

  TMSMCPCloudAI1.APIKeys.SaveToFile('.\..\..\aikeys.cfg','tmssoftware.com');
end;

end.
