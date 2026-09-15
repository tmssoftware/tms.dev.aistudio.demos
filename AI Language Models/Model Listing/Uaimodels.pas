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
unit Uaimodels;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  TMS.MCP.CloudBase, TMS.MCP.CloudAI, Vcl.Menus, Vcl.Clipbrd, TMS.MCP.CustomComponent;

type
  TForm5 = class(TForm)
    Panel1: TPanel;
    ComboBox1: TComboBox;
    Button1: TButton;
    ListBox1: TListBox;
    TMSMCPCloudAI1: TTMSMCPCloudAI;
    PopupMenu1: TPopupMenu;
    Copytoclipboard1: TMenuItem;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TMSMCPCloudAI1GetModels(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ComboBox1Change(Sender: TObject);
    procedure Copytoclipboard1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

procedure TForm5.Button1Click(Sender: TObject);
begin
  TMSMCPCloudAI1.GetModels();
end;

procedure TForm5.ComboBox1Change(Sender: TObject);
var
  i: integer;
begin
  i := integer(ComboBox1.Items.Objects[ComboBox1.ItemIndex]);
  TMSMCPCloudAI1.Service := TTMSMCPCloudAIService(i);
end;

procedure TForm5.Copytoclipboard1Click(Sender: TObject);
var
  clip: TClipboard;
begin
  if ListBox1.ItemIndex >= 0 then
  begin
    Clip := TClipboard.Create;
    Clip.AsText := Listbox1.Items[ListBox1.ItemIndex];
    Clip.Free;
  end
  else
    ShowMessage('No model selected');
end;

procedure TForm5.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\..\aikeys.cfg','tmssoftware.com');
  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices);
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);
end;

procedure TForm5.TMSMCPCloudAI1GetModels(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
begin
  if AHttpStatusCode = 200 then
  begin
    Listbox1.Items.Assign(TMSMCPCloudAI1.Models);
  end
  else
    ShowMessage('HTTP error ' + AHttpStatusCode.ToString+' : ' + AHttpResult);
end;

end.
