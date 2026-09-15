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
unit Uaifiles;

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
    ListView1: TListView;
    btnAdd: TButton;
    btnDelete: TButton;
    Label1: TLabel;
    OpenDialog1: TOpenDialog;
    btnExec: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure TMSMCPCloudAI1Executed(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure TMSMCPCloudAI1GetFiles(Sender: TObject;
      AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
      AHttpResult: string);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure TMSMCPCloudAI1FileUpload(Sender: TObject; HttpStatusCode: Integer;
      HttpResult: string; Index: Integer);
    procedure btnExecClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure FileToListItem(FileIndex: integer; ListItem: TListItem);
    procedure RunThread(id: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnAddClick(Sender: TObject);
begin
//
  if OpenDialog1.Execute then
  begin
    TMSMCPCloudAI1.UploadFile(OpenDialog1.FileName, FileExtToFileType(OpenDialog1.FileName));
  end;

end;

procedure TForm1.btnDeleteClick(Sender: TObject);
begin
  if ListView1.ItemIndex < TMSMCPCloudAI1.Files.Count then
  begin
    TMSMCPCloudAI1.Files[ListView1.ItemIndex].Delete;
    ListView1.Items[ListView1.ItemIndex].Delete;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  btnAdd.Enabled := false;
  btnDelete.Enabled := false;
  ListView1.Items.Clear;
  TMSMCPCloudAI1.GetFiles;
  ProgressBar1.State := pbsNormal;
  memo2.Lines.Clear;
end;

procedure TForm1.btnExecClick(Sender: TObject);
begin
  btnExec.Enabled := false;

  TMSMCPCloudAI1.Context.Text := memo1.Lines.Text;

  if TMSMCPCloudAI1.Service = aiOpenAI then
  begin
    TMSMCPCloudAI1.GetAssistants(procedure(AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer; AHttpResult: string)
     var
       id: string;
     begin
       if AHttpStatusCode div 100 = 2 then
       begin
         if TMSMCPCloudAI1.Assistants.Count > 0 then
         begin
           id := TMSMCPCloudAI1.Assistants[0].ID;
           RunThread(id);
         end
         else
           TMSMCPCloudAI1.CreateAssistant('My assistant','you assist me with files',[aitFileSearch], procedure(const AID: string)
             begin
               id := AID;
               RunThread(id);
             end);

       end;
     end);
  end
  else
  begin
    TMSMCPCloudAI1.Execute;
  end;
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

procedure TForm1.FileToListItem(FileIndex: integer; ListItem: TListItem);
begin
  ListItem.Caption := TMSMCPCloudAI1.Files[FileIndex].ID;
  ListItem.SubItems.Add(TMSMCPCloudAI1.Files[FileIndex].FileName);
  ListItem.SubItems.Add(TMSMCPCloudAI1.Files[FileIndex].FileSize.ToString);
  ListItem.SubItems.Add(TMSMCPCloudAI1.Files[FileIndex].MimeType);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TMSMCPCloudAI1.Logging := true;
  TMSMCPCloudAI1.LogFileName := '.\..\..\aifiles.log';

  TMSMCPCloudAI1.APIKeys.LoadFromFile('.\..\..\..\aikeys.cfg','tmssoftware.com');

  ComboBox1.ItemIndex := -1;
  ComboBox1.Items.Assign(TMSMCPCloudAI1.GetServices(false, true));
  ComboBox1.ItemIndex := 0;
  ComboBox1Change(ComboBox1);
end;

procedure TForm1.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if ListView1.ItemIndex >= 0 then
    btnDelete.Enabled := true;
end;

procedure TForm1.RunThread(id: string);
begin
  TMSMCPCloudAI1.CreateThread(procedure(const AId: string)
    var
      sl: TStringList;
      i: integer;
      threadid: string;
    begin
      threadid := aid;
      //ShowMessage('thread created:'+ThreadId);

      sl := TStringList.Create;
      for i := 0 to TMSMCPCloudAI1.Files.Count - 1 do
        sl.Add(TMSMCPCloudAI1.Files[i].ID);

      TMSMCPCloudAI1.CreateMessage(ThreadId, 'user', Memo1.Lines.Text, sl, aitFileSearch, procedure(const AId: string)
        begin
          // message created
          TMSMCPCloudAI1.RunThreadAndWait(ThreadId, id, procedure(AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer; AHttpResult: string)
            begin
              memo2.Lines.Add(AHttpResult);
              btnExec.Enabled := true;
              progressbar1.State := pbsPaused;
            end);
        end,
        procedure(AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer; AHttpResult: string)
        begin
          memo2.Lines.Add('Error ' + AHttpStatusCode.ToString);
          memo2.Lines.Add(AHttpResult);
          btnExec.Enabled := true;
          progressbar1.State := pbsPaused;
        end
        );
      sl.Free;
    end);
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

procedure TForm1.TMSMCPCloudAI1FileUpload(Sender: TObject;
  HttpStatusCode: Integer; HttpResult: string; Index: Integer);
var
  li: TListItem;
begin
  li := ListView1.Items.Add;
  FileToListItem(TMSMCPCloudAI1.Files.Count - 1, li);
end;

procedure TForm1.TMSMCPCloudAI1GetFiles(Sender: TObject;
  AResponse: TTMSMCPCloudAIResponse; AHttpStatusCode: Integer;
  AHttpResult: string);
var
  i: integer;
  li: TListItem;
begin
//
  ProgressBar1.State := pbsPaused;
  if AHttpStatusCode = 200 then
  begin
    btnAdd.Enabled := true;
    btnDelete.Enabled := false;

    ListView1.Items.BeginUpdate;
    for i := 0 to TMSMCPCloudAI1.Files.Count - 1 do
    begin
      li := ListView1.Items.Add;
      FileToListItem(i, li);
    end;
    ListView1.Items.EndUpdate;
  end;
end;

end.
