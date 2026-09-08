unit ResourceServerServiceMain;

// Windows service wrapper around the same OAuth 2.1 / MCP Authorization
// resource-server logic used by the "OAuth Resource Server Demo" console app
// (RequireBearerAuthentication, Protected Resource Metadata, RFC 7662
// introspection against the Authorization Server), so it can be installed to
// run unattended on a server instead of in a console window.
//
// All settings that differ per deployment (port, the Authorization Server's
// issuer URL, TLS) are read from an INI file next to the service .exe (same
// base name, .ini extension) rather than hardcoded - see
// TResourceServerService.LoadConfig below.
//
// Install / uninstall (elevated command prompt):
//   OAuthResourceServerService.exe /install
//   OAuthResourceServerService.exe /uninstall
// Then start it from services.msc or: net start "TMS MCP OAuth Resource Server"

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.JSON, System.Rtti, System.DateUtils, System.Generics.Collections,
  System.SyncObjs, System.IniFiles, System.IOUtils,
  IdHTTP, IdSSLOpenSSL,
  Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  TMS.MCP.Server, TMS.MCP.Tools, TMS.MCP.Helpers, TMS.MCP.Auth, TMS.MCP.Utils,
  TMS.MCP.Transport.StreamableHTTP;

type
  // Supplies the OnLog/OnValidateAccessToken handlers the transport requires,
  // and calls out to the Authorization Server's introspection endpoint to
  // validate whatever bearer token a caller presents. Logs to a file since a
  // service has no console.
  TDemoAuthHandlers = class
  private
    FLogFile: string;
    FLogLock: TCriticalSection;
    FAuthorizationServerIssuer: string;
  public
    constructor Create(const AAuthorizationServerIssuer, ALogFile: string);
    destructor Destroy; override;
    procedure LogMessage(const Msg: string);
    procedure ValidateAccessToken(Sender: TObject; const AToken, AResourceURI: string;
      var AValidation: TTMSMCPAccessTokenValidation);
  end;

  TNote = record
    Id: string;
    Text: string;
    CreatedAt: TDateTime;
  end;

  TResourceServerService = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    Server: TTMSMCPServer;
    Transport: TTMSMCPStreamableHTTPTransport;
    Handlers: TDemoAuthHandlers;
    ListTool, AddTool, DeleteTool: TTMSMCPTool;
    FPort: Word;
    FMCPEndpoint: string;
    FAuthorizationServerIssuer: string;
    FUseSSL: Boolean;
    FCertFile, FKeyFile, FKeyPassword: string;
    FPublicHost: string;
    FLogFile: string;
    procedure LoadConfig;
  public
    function GetServiceController: TServiceController; override;
  end;

var
  ResourceServerService: TResourceServerService;
  // Declared here (ahead of the tool callbacks below) so they can read
  // Server.CurrentSessionId to scope notes to the calling MCP session - each
  // connected client sees only its own notes.
  SessionNotes: TObjectDictionary<string, TList<TNote>>;
  NotesLock: TCriticalSection;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ResourceServerService.Controller(CtrlCode);
end;

function TResourceServerService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

{ TDemoAuthHandlers }

constructor TDemoAuthHandlers.Create(const AAuthorizationServerIssuer, ALogFile: string);
begin
  inherited Create;
  FAuthorizationServerIssuer := AAuthorizationServerIssuer;
  FLogFile := ALogFile;
  FLogLock := TCriticalSection.Create;
end;

destructor TDemoAuthHandlers.Destroy;
begin
  FLogLock.Free;
  inherited;
end;

procedure TDemoAuthHandlers.LogMessage(const Msg: string);
begin
  FLogLock.Enter;
  try
    TFile.AppendAllText(FLogFile, Format('[%s] %s' + sLineBreak,
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Msg]));
  finally
    FLogLock.Leave;
  end;
end;

procedure TDemoAuthHandlers.ValidateAccessToken(Sender: TObject; const AToken, AResourceURI: string;
  var AValidation: TTMSMCPAccessTokenValidation);
var
  Http: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  ReqBody, RespBody: TStringStream;
  Json: TJSONObject;
  Audience: string;
begin
  LogMessage(Format('Introspecting token against %s for resource %s', [FAuthorizationServerIssuer, AResourceURI]));
  AValidation.Valid := False;

  Http := TIdHTTP.Create(nil);
  SSLHandler := nil;
  ReqBody := TStringStream.Create('token=' + TTMSMCPUtils.URLEncode(AToken));
  RespBody := TStringStream.Create;
  try
    try
      if SameText(Copy(FAuthorizationServerIssuer, 1, 8), 'https://') then
      begin
        SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Http);
        SSLHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
        Http.IOHandler := SSLHandler;
      end;

      Http.Request.ContentType := 'application/x-www-form-urlencoded';
      Http.Post(FAuthorizationServerIssuer + '/introspect', ReqBody, RespBody);

      Json := TJSONObject.ParseJSONValue(RespBody.DataString) as TJSONObject;
      try
        if not Assigned(Json) or not Assigned(Json.GetValue('active')) or
          not (Json.GetValue('active') as TJSONBool).AsBoolean then
        begin
          AValidation.ErrorDescription := 'Token is not active per introspection';
          LogMessage('Token rejected: introspection reports inactive');
          Exit;
        end;

        // Audience binding: only accept tokens the Authorization Server issued for
        // THIS resource, per the MCP Authorization spec's access-token-privilege-
        // restriction requirement.
        Audience := '';
        if Assigned(Json.GetValue('aud')) then
          Audience := Json.GetValue('aud').Value;
        if Audience <> AResourceURI then
        begin
          AValidation.ErrorDescription := 'Token audience does not match this resource';
          LogMessage(Format('Token rejected: audience "%s" does not match "%s"', [Audience, AResourceURI]));
          Exit;
        end;

        AValidation.Valid := True;
        if Assigned(Json.GetValue('sub')) then
          AValidation.Subject := Json.GetValue('sub').Value;
        if Assigned(Json.GetValue('scope')) then
          AValidation.Scopes := Json.GetValue('scope').Value.Split([' ']);

        LogMessage(Format('Token accepted for subject "%s" with scopes [%s]',
          [AValidation.Subject, string.Join(', ', AValidation.Scopes)]));
      finally
        Json.Free;
      end;
    except
      on E: Exception do
      begin
        AValidation.Valid := False;
        AValidation.ErrorDescription := 'Introspection call failed: ' + E.Message;
        LogMessage('Token rejected: ' + AValidation.ErrorDescription);
      end;
    end;
  finally
    RespBody.Free;
    ReqBody.Free;
    Http.Free;
  end;
end;

function NewNoteId: string;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := GUIDToString(GUID).Replace('{', '').Replace('}', '').Replace('-', '');
end;

function NoteToJSON(const ANote: TNote): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ANote.Id);
  Result.AddPair('text', ANote.Text);
  Result.AddPair('createdAt', DateToISO8601(ANote.CreatedAt, False));
end;

// Returns the note list belonging to the MCP session currently being served,
// creating it on first use. Must be called with NotesLock held. Empty
// SessionId (sessionless transport) falls back to one shared bucket, which
// doesn't apply to this demo's Streamable HTTP transport but keeps this safe
// to reuse elsewhere.
function NotesForCurrentSession: TList<TNote>;
var
  SessionId: string;
begin
  SessionId := ResourceServerService.Server.CurrentSessionId;
  if not SessionNotes.TryGetValue(SessionId, Result) then
  begin
    Result := TList<TNote>.Create;
    SessionNotes.Add(SessionId, Result);
  end;
end;

// Read: lists every note belonging to the calling session. Conceptually needs
// only demo:read.
function HandleListNotesTool(const Args: array of TValue): TValue;
var
  Arr: TJSONArray;
  Note: TNote;
begin
  Arr := TJSONArray.Create;
  try
    NotesLock.Enter;
    try
      for Note in NotesForCurrentSession do
        Arr.Add(NoteToJSON(Note));
    finally
      NotesLock.Leave;
    end;
    Result := TValue.From<string>(Arr.ToJSON);
  finally
    Arr.Free;
  end;
end;

// Write: appends a note to the calling session's list. Conceptually needs
// demo:write (see the comment on RequiredScopes in ServiceCreate below - the
// SDK's scope gate is server-wide today, not per-tool, so this isn't actually
// enforced differently from list_notes yet).
function HandleAddNoteTool(const Args: array of TValue): TValue;
var
  Note: TNote;
  Obj: TJSONObject;
begin
  if (Length(Args) = 0) or (Trim(Args[0].AsString) = '') then
    raise Exception.Create('"text" is required');

  Note.Id := NewNoteId;
  Note.Text := Args[0].AsString;
  Note.CreatedAt := Now;

  NotesLock.Enter;
  try
    NotesForCurrentSession.Add(Note);
  finally
    NotesLock.Leave;
  end;

  Obj := NoteToJSON(Note);
  try
    Result := TValue.From<string>(Obj.ToJSON);
  finally
    Obj.Free;
  end;
end;

// Write: removes a note by id from the calling session's list only.
function HandleDeleteNoteTool(const Args: array of TValue): TValue;
var
  Id: string;
  I: Integer;
  Deleted: Boolean;
  Obj: TJSONObject;
  List: TList<TNote>;
begin
  if Length(Args) = 0 then
    raise Exception.Create('"id" is required');
  Id := Args[0].AsString;

  Deleted := False;
  NotesLock.Enter;
  try
    List := NotesForCurrentSession;
    for I := 0 to List.Count - 1 do
      if List[I].Id = Id then
      begin
        List.Delete(I);
        Deleted := True;
        Break;
      end;
  finally
    NotesLock.Leave;
  end;

  Obj := TJSONObject.Create;
  try
    Obj.AddPair('deleted', TJSONBool.Create(Deleted));
    Obj.AddPair('id', Id);
    Result := TValue.From<string>(Obj.ToJSON);
  finally
    Obj.Free;
  end;
end;

{ TResourceServerService }

procedure TResourceServerService.LoadConfig;
var
  Ini: TIniFile;
  IniFile: string;
begin
  IniFile := TPath.ChangeExtension(ParamStr(0), '.ini');
  Ini := TIniFile.Create(IniFile);
  try
    FPort := Ini.ReadInteger('Server', 'Port', 8934);
    FMCPEndpoint := Ini.ReadString('Server', 'MCPEndpoint', '/mcp');
    FUseSSL := Ini.ReadBool('Server', 'UseSSL', False);
    FCertFile := Ini.ReadString('Server', 'CertFile', '');
    FKeyFile := Ini.ReadString('Server', 'KeyFile', '');
    FKeyPassword := Ini.ReadString('Server', 'KeyPassword', '');
    FPublicHost := Ini.ReadString('Server', 'PublicHost', '');
    FAuthorizationServerIssuer := Ini.ReadString('Server', 'AuthorizationServerIssuer', 'http://localhost:9000');
    FLogFile := Ini.ReadString('Logging', 'LogFile', '');
    if FLogFile = '' then
      FLogFile := TPath.ChangeExtension(ParamStr(0), '.log');
  finally
    Ini.Free;
  end;
end;

procedure TResourceServerService.ServiceCreate(Sender: TObject);
begin
  LoadConfig;

  SessionNotes := TObjectDictionary<string, TList<TNote>>.Create([doOwnsValues]);
  NotesLock := TCriticalSection.Create;
  Handlers := TDemoAuthHandlers.Create(FAuthorizationServerIssuer, FLogFile);
  Handlers.LogMessage('Service created.');

  Server := TTMSMCPServer.Create(nil);
  Server.ServerName := 'OAuthResourceServerService';
  Server.ServerVersion := '1.0.0';

  ListTool := TTMSMCPTool.CreateBuilder
    .Name('list_notes')
    .Description('Lists all notes')
    .ExecuteCallback(HandleListNotesTool)
    .ReturnType(ptJSON)
    .Build;
  Server.Tools.Add(ListTool);

  AddTool := TTMSMCPTool.CreateBuilder
    .Name('add_note')
    .Description('Adds a new note and returns it')
    .ExecuteCallback(HandleAddNoteTool)
    .ReturnType(ptJSON)
    .AddProperty
      .Name('text')
      .Description('The note text to store')
      .PropertyType(ptString)
      .Required(True)
      .&End
    .Build;
  Server.Tools.Add(AddTool);

  DeleteTool := TTMSMCPTool.CreateBuilder
    .Name('delete_note')
    .Description('Deletes a note by id')
    .ExecuteCallback(HandleDeleteNoteTool)
    .ReturnType(ptJSON)
    .AddProperty
      .Name('id')
      .Description('The id of the note to delete, as returned by list_notes or add_note')
      .PropertyType(ptString)
      .Required(True)
      .&End
    .Build;
  Server.Tools.Add(DeleteTool);

  // The SDK's RequiredScopes gate below is server-wide, not per-tool (per-tool
  // scope enforcement is a documented future extension).
  Transport := TTMSMCPStreamableHTTPTransport.Create(nil, FPort, FMCPEndpoint);
  Transport.OnLog := Handlers.LogMessage;
  Transport.RequireBearerAuthentication := True;
  Transport.AuthorizationServers.Add(FAuthorizationServerIssuer);
  Transport.ResourceScopesSupported.Add('demo:read');
  Transport.ResourceScopesSupported.Add('demo:write');
  Transport.RequiredScopes.Add('demo:read');
  Transport.OnValidateAccessToken := Handlers.ValidateAccessToken;
  Transport.PublicHost := FPublicHost;
  if FUseSSL then
    Transport.ConfigureSSL(FCertFile, FKeyFile, FKeyPassword);

  Server.Transport := Transport;
end;

procedure TResourceServerService.ServiceDestroy(Sender: TObject);
begin
  FreeAndNil(Server);
  FreeAndNil(Transport);
  FreeAndNil(Handlers);
  FreeAndNil(NotesLock);
  FreeAndNil(SessionNotes);
end;

procedure TResourceServerService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  Server.Start;
  Handlers.LogMessage(Format('Ready. Tokens are validated against %s/introspect.', [FAuthorizationServerIssuer]));
  Started := True;
end;

procedure TResourceServerService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Server.Stop;
  Handlers.LogMessage('Service stopped.');
  Stopped := True;
end;

end.
