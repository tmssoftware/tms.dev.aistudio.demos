program OAuthAuthorizationServerDemo;

// A minimal but spec-faithful OAuth 2.1 Authorization Server, built purely to let the
// "OAuth Resource Server Demo" (and any real MCP client - Claude Desktop, MCP Inspector)
// exercise the full MCP Authorization loop end to end:
//
//   discovery -> dynamic client registration -> PKCE authorize + fake login/consent
//   -> token exchange -> (resource server calls back here to introspect the token)
//
// This is a TEST TOOL, not a production identity provider: there is no real credential
// check (the "login" page just asks you to approve as a fixed demo user), all state is
// in-memory only, and only public clients (PKCE, no client secret) are supported - which
// matches what MCP clients use.
//
// Endpoints (default port 9000):
//   GET  /.well-known/oauth-authorization-server   RFC 8414 metadata
//   POST /register                                 RFC 7591 dynamic client registration
//   GET  /authorize                                PKCE authorize + consent page
//   POST /authorize/approve                        consent submit -> redirect with code
//   POST /token                                     authorization_code / refresh_token grants
//   POST /introspect                                RFC 7662 token introspection
//
// Run this first, then the OAuth Resource Server Demo (which points its
// AuthorizationServers property at this server's issuer URL and calls /introspect to
// validate bearer tokens).

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.NetEncoding,
  System.Hash,
  TMS.MCP.HTTPServer,
  TMS.MCP.Utils;

const
  Port = 9000;
  Issuer = 'http://localhost:9000';
  AccessTokenLifetimeSeconds = 3600;
  AuthCodeLifetimeSeconds = 120;
  AllScopes: array[0..1] of string = ('demo:read', 'demo:write');

type
  TStringArray = TArray<string>;

  TRegisteredClient = record
    ClientId: string;
    ClientName: string;
    RedirectURIs: TStringArray;
  end;

  TPendingAuthRequest = record
    ClientId: string;
    RedirectURI: string;
    CodeChallenge: string;
    State: string;
    Resource: string;
    RequestedScopes: TStringArray;
  end;

  TAuthCode = record
    ClientId: string;
    RedirectURI: string;
    CodeChallenge: string;
    Resource: string;
    Subject: string;
    Scopes: TStringArray;
    Used: Boolean;
    ExpiresAt: TDateTime;
  end;

  TIssuedGrant = record
    ClientId: string;
    Subject: string;
    Resource: string;
    Scopes: TStringArray;
    ExpiresAt: TDateTime;
  end;

  TAuthServerHandlers = class
  private
    FLock: TObject;
    FClients: TDictionary<string, TRegisteredClient>;
    FPendingRequests: TDictionary<string, TPendingAuthRequest>;
    FAuthCodes: TDictionary<string, TAuthCode>;
    FAccessTokens: TDictionary<string, TIssuedGrant>;
    FRefreshTokens: TDictionary<string, TIssuedGrant>;
    function ReadBody(ARequest: TTMSMCPHTTPServerRequest): string;
    procedure WriteJSON(AResponse: TTMSMCPHTTPServerResponse; const AJSON: string; AStatusCode: Integer = 200);
    procedure WriteOAuthError(AResponse: TTMSMCPHTTPServerResponse; AStatusCode: Integer;
      const AError, ADescription: string);
    function BuildRedirect(const ARedirectURI: string; const AParams: array of TPair<string, string>): string;
    procedure HandleDiscovery(AResponse: TTMSMCPHTTPServerResponse);
    procedure HandleRegister(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
    procedure HandleAuthorize(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
    procedure HandleApprove(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
    procedure HandleToken(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
    procedure HandleIntrospect(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
    procedure IssueGrant(const AGrant: TIssuedGrant; out AAccessToken, ARefreshToken: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LogMessage(const Msg: string);
    procedure HandleServerRequest(AConnection: TTMSMCPHTTPServerConnection;
      ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
  end;

function NewId: string;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := GUIDToString(GUID).Replace('{', '').Replace('}', '').Replace('-', '');
end;

function UnixTimestamp(const ADateTime: TDateTime): Int64;
begin
  Result := Round((ADateTime - EncodeDate(1970, 1, 1)) * 86400);
end;

function ScopesToString(const AScopes: array of string): string;
var
  S: string;
begin
  Result := '';
  for S in AScopes do
    if Result = '' then
      Result := S
    else
      Result := Result + ' ' + S;
end;

function StringToScopes(const AScopeStr: string): TStringArray;
begin
  if Trim(AScopeStr) = '' then
    Result := nil
  else
    Result := AScopeStr.Split([' ']);
end;

function Base64URLEncode(const ABytes: TBytes): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(ABytes);
  Result := StringReplace(Result, '+', '-', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '_', [rfReplaceAll]);
  Result := StringReplace(Result, '=', '', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function PKCEChallengeMatches(const AVerifier, AChallenge: string): Boolean;
begin
  Result := (AVerifier <> '') and (AChallenge <> '') and
    (Base64URLEncode(THashSHA2.GetHashBytes(AVerifier)) = AChallenge);
end;

// Parses application/x-www-form-urlencoded data (also used for raw query strings).
function ParseFormEncoded(const AData: string): TDictionary<string, string>;
var
  Pairs: TArray<string>;
  Pair, Key, Value: string;
  EqPos: Integer;
begin
  Result := TDictionary<string, string>.Create;
  if Trim(AData) = '' then
    Exit;
  Pairs := AData.Split(['&']);
  for Pair in Pairs do
  begin
    if Pair = '' then
      Continue;
    EqPos := Pos('=', Pair);
    if EqPos > 0 then
    begin
      Key := Copy(Pair, 1, EqPos - 1);
      Value := Copy(Pair, EqPos + 1, MaxInt);
    end
    else
    begin
      Key := Pair;
      Value := '';
    end;
    Key := TTMSMCPUtils.URLDecode(StringReplace(Key, '+', ' ', [rfReplaceAll]));
    Value := TTMSMCPUtils.URLDecode(StringReplace(Value, '+', ' ', [rfReplaceAll]));
    Result.AddOrSetValue(Key, Value);
  end;
end;

function GetOrDefault(ADict: TDictionary<string, string>; const AKey: string; const ADefault: string = ''): string;
begin
  if not ADict.TryGetValue(AKey, Result) then
    Result := ADefault;
end;

{ TAuthServerHandlers }

constructor TAuthServerHandlers.Create;
begin
  inherited Create;
  FLock := TObject.Create;
  FClients := TDictionary<string, TRegisteredClient>.Create;
  FPendingRequests := TDictionary<string, TPendingAuthRequest>.Create;
  FAuthCodes := TDictionary<string, TAuthCode>.Create;
  FAccessTokens := TDictionary<string, TIssuedGrant>.Create;
  FRefreshTokens := TDictionary<string, TIssuedGrant>.Create;
end;

destructor TAuthServerHandlers.Destroy;
begin
  FRefreshTokens.Free;
  FAccessTokens.Free;
  FAuthCodes.Free;
  FPendingRequests.Free;
  FClients.Free;
  FLock.Free;
  inherited;
end;

procedure TAuthServerHandlers.LogMessage(const Msg: string);
begin
  WriteLn(Format('[%s] %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), Msg]));
end;

function TAuthServerHandlers.ReadBody(ARequest: TTMSMCPHTTPServerRequest): string;
var
  Stream: TStringStream;
begin
  if not Assigned(ARequest.PostStream) then
    Exit('');
  Stream := TStringStream.Create('', TEncoding.UTF8);
  try
    Stream.CopyFrom(ARequest.PostStream, 0);
    Result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

procedure TAuthServerHandlers.WriteJSON(AResponse: TTMSMCPHTTPServerResponse; const AJSON: string;
  AStatusCode: Integer = 200);
begin
  AResponse.ResponseCode := AStatusCode;
  AResponse.Headers.AddValue('Content-Type', 'application/json');
  AResponse.ContentText := AJSON;
end;

procedure TAuthServerHandlers.WriteOAuthError(AResponse: TTMSMCPHTTPServerResponse; AStatusCode: Integer;
  const AError, ADescription: string);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('error', AError);
    if ADescription <> '' then
      Obj.AddPair('error_description', ADescription);
    WriteJSON(AResponse, Obj.ToJSON, AStatusCode);
  finally
    Obj.Free;
  end;
end;

function TAuthServerHandlers.BuildRedirect(const ARedirectURI: string;
  const AParams: array of TPair<string, string>): string;
var
  Sep: string;
  P: TPair<string, string>;
begin
  Result := ARedirectURI;
  if Pos('?', ARedirectURI) > 0 then
    Sep := '&'
  else
    Sep := '?';
  for P in AParams do
  begin
    Result := Result + Sep + P.Key + '=' + TTMSMCPUtils.URLEncode(P.Value);
    Sep := '&';
  end;
end;

procedure TAuthServerHandlers.HandleDiscovery(AResponse: TTMSMCPHTTPServerResponse);
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  S: string;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('issuer', Issuer);
    Obj.AddPair('authorization_endpoint', Issuer + '/authorize');
    Obj.AddPair('token_endpoint', Issuer + '/token');
    Obj.AddPair('registration_endpoint', Issuer + '/register');
    Obj.AddPair('introspection_endpoint', Issuer + '/introspect');

    Arr := TJSONArray.Create;
    Arr.Add('code');
    Obj.AddPair('response_types_supported', Arr);

    Arr := TJSONArray.Create;
    Arr.Add('authorization_code');
    Arr.Add('refresh_token');
    Obj.AddPair('grant_types_supported', Arr);

    Arr := TJSONArray.Create;
    Arr.Add('S256');
    Obj.AddPair('code_challenge_methods_supported', Arr);

    Arr := TJSONArray.Create;
    Arr.Add('none');
    Obj.AddPair('token_endpoint_auth_methods_supported', Arr);

    Arr := TJSONArray.Create;
    for S in AllScopes do
      Arr.Add(S);
    Obj.AddPair('scopes_supported', Arr);

    WriteJSON(AResponse, Obj.ToJSON);
  finally
    Obj.Free;
  end;
end;

procedure TAuthServerHandlers.HandleRegister(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
var
  ReqObj, RespObj: TJSONObject;
  ReqJSON: TJSONValue;
  RedirectArr, RespRedirectArr, RespGrantArr, RespRespArr: TJSONArray;
  Client: TRegisteredClient;
  RedirectURIs: TStringArray;
  I: Integer;
  ClientName: string;
begin
  ReqJSON := TJSONObject.ParseJSONValue(ReadBody(ARequest));
  try
    if not (ReqJSON is TJSONObject) then
    begin
      WriteOAuthError(AResponse, 400, 'invalid_client_metadata', 'Request body must be a JSON object');
      Exit;
    end;
    ReqObj := TJSONObject(ReqJSON);

    if Assigned(ReqObj.GetValue('redirect_uris')) and (ReqObj.GetValue('redirect_uris') is TJSONArray) then
      RedirectArr := TJSONArray(ReqObj.GetValue('redirect_uris'))
    else
      RedirectArr := nil;

    if not Assigned(RedirectArr) or (RedirectArr.Count = 0) then
    begin
      WriteOAuthError(AResponse, 400, 'invalid_client_metadata', 'redirect_uris is required and must be non-empty');
      Exit;
    end;

    SetLength(RedirectURIs, RedirectArr.Count);
    for I := 0 to RedirectArr.Count - 1 do
      RedirectURIs[I] := RedirectArr.Items[I].Value;

    if Assigned(ReqObj.GetValue('client_name')) then
      ClientName := ReqObj.GetValue('client_name').Value
    else
      ClientName := 'MCP Client';

    Client.ClientId := NewId;
    Client.ClientName := ClientName;
    Client.RedirectURIs := RedirectURIs;
    FClients.AddOrSetValue(Client.ClientId, Client);

    LogMessage(Format('Registered client "%s" (%s) with %d redirect URI(s)',
      [ClientName, Client.ClientId, Length(RedirectURIs)]));

    RespObj := TJSONObject.Create;
    try
      RespObj.AddPair('client_id', Client.ClientId);
      RespObj.AddPair('client_name', ClientName);
      RespObj.AddPair('client_id_issued_at', TJSONNumber.Create(UnixTimestamp(Now)));
      RespObj.AddPair('token_endpoint_auth_method', 'none');

      RespRedirectArr := TJSONArray.Create;
      for I := 0 to High(RedirectURIs) do
        RespRedirectArr.Add(RedirectURIs[I]);
      RespObj.AddPair('redirect_uris', RespRedirectArr);

      RespGrantArr := TJSONArray.Create;
      RespGrantArr.Add('authorization_code');
      RespGrantArr.Add('refresh_token');
      RespObj.AddPair('grant_types', RespGrantArr);

      RespRespArr := TJSONArray.Create;
      RespRespArr.Add('code');
      RespObj.AddPair('response_types', RespRespArr);

      WriteJSON(AResponse, RespObj.ToJSON, 201);
    finally
      RespObj.Free;
    end;
  finally
    ReqJSON.Free;
  end;
end;

procedure TAuthServerHandlers.HandleAuthorize(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
var
  Params: TDictionary<string, string>;
  ClientId, RedirectURI, ResponseType, CodeChallenge, CodeChallengeMethod, State, Scope, Resource: string;
  Client: TRegisteredClient;
  RedirectValid: Boolean;
  Req: TPendingAuthRequest;
  RequestId: string;
  Html: TStringBuilder;
  I: Integer;
  ScopeName: string;
begin
  Params := ParseFormEncoded(ARequest.QueryParams);
  try
    ClientId := GetOrDefault(Params, 'client_id');
    RedirectURI := GetOrDefault(Params, 'redirect_uri');
    ResponseType := GetOrDefault(Params, 'response_type');
    CodeChallenge := GetOrDefault(Params, 'code_challenge');
    CodeChallengeMethod := GetOrDefault(Params, 'code_challenge_method');
    State := GetOrDefault(Params, 'state');
    Scope := GetOrDefault(Params, 'scope');
    Resource := GetOrDefault(Params, 'resource');

    if not FClients.TryGetValue(ClientId, Client) then
    begin
      AResponse.ResponseCode := 400;
      AResponse.Headers.AddValue('Content-Type', 'text/html');
      AResponse.ContentText := '<h3>Authorization error</h3><p>Unknown client_id.</p>';
      Exit;
    end;

    RedirectValid := False;
    for I := 0 to High(Client.RedirectURIs) do
      if Client.RedirectURIs[I] = RedirectURI then
      begin
        RedirectValid := True;
        Break;
      end;

    if not RedirectValid then
    begin
      // Never redirect on an unvalidated redirect_uri - show an in-page error instead.
      AResponse.ResponseCode := 400;
      AResponse.Headers.AddValue('Content-Type', 'text/html');
      AResponse.ContentText := '<h3>Authorization error</h3><p>redirect_uri does not match a registered value for this client.</p>';
      Exit;
    end;

    if ResponseType <> 'code' then
    begin
      AResponse.Redirect(BuildRedirect(RedirectURI, [
        TPair<string, string>.Create('error', 'unsupported_response_type'),
        TPair<string, string>.Create('state', State)]));
      Exit;
    end;

    if (CodeChallenge = '') or (CodeChallengeMethod <> 'S256') then
    begin
      AResponse.Redirect(BuildRedirect(RedirectURI, [
        TPair<string, string>.Create('error', 'invalid_request'),
        TPair<string, string>.Create('error_description', 'PKCE with S256 is required'),
        TPair<string, string>.Create('state', State)]));
      Exit;
    end;

    Req.ClientId := ClientId;
    Req.RedirectURI := RedirectURI;
    Req.CodeChallenge := CodeChallenge;
    Req.State := State;
    Req.Resource := Resource;
    if Trim(Scope) = '' then
      Req.RequestedScopes := StringToScopes(ScopesToString(AllScopes))
    else
      Req.RequestedScopes := StringToScopes(Scope);

    RequestId := NewId;
    FPendingRequests.AddOrSetValue(RequestId, Req);

    Html := TStringBuilder.Create;
    try
      Html.Append('<html><head><title>Demo Authorization Server</title></head><body style="font-family:sans-serif;max-width:480px;margin:40px auto;">');
      Html.Append('<h2>Demo Authorization Server</h2>');
      Html.Append(Format('<p><b>%s</b> is requesting access, signed in as <b>demo-user</b>.</p>', [Client.ClientName]));
      // Path-relative (not root-relative): resolves correctly whether this
      // server is mounted at the domain root or reverse-proxied under a
      // subpath (e.g. /mcp/auth/authorize -> /mcp/auth/authorize/approve).
      Html.Append('<form method="POST" action="authorize/approve">');
      Html.Append(Format('<input type="hidden" name="request_id" value="%s">', [RequestId]));
      Html.Append(Format('<input type="hidden" name="scope_count" value="%d">', [Length(Req.RequestedScopes)]));
      Html.Append('<p>Requested permissions:</p>');
      for I := 0 to High(Req.RequestedScopes) do
      begin
        ScopeName := Req.RequestedScopes[I];
        Html.Append(Format('<input type="hidden" name="scope_name_%d" value="%s">', [I, ScopeName]));
        Html.Append(Format('<label><input type="checkbox" name="scope_grant_%d" value="1" checked> %s</label><br>', [I, ScopeName]));
      end;
      Html.Append('<p><button type="submit" name="action" value="approve">Approve</button> ');
      Html.Append('<button type="submit" name="action" value="deny">Deny</button></p>');
      Html.Append('</form></body></html>');

      AResponse.ResponseCode := 200;
      AResponse.Headers.AddValue('Content-Type', 'text/html');
      AResponse.ContentText := Html.ToString;
    finally
      Html.Free;
    end;
  finally
    Params.Free;
  end;
end;

procedure TAuthServerHandlers.HandleApprove(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
var
  Form: TDictionary<string, string>;
  RequestId, Action: string;
  Req: TPendingAuthRequest;
  ScopeCount, I: Integer;
  Granted: TStringArray;
  GrantedCount: Integer;
  Code: TAuthCode;
  CodeId: string;
begin
  Form := ParseFormEncoded(ReadBody(ARequest));
  try
    RequestId := GetOrDefault(Form, 'request_id');
    Action := GetOrDefault(Form, 'action');

    if not FPendingRequests.TryGetValue(RequestId, Req) then
    begin
      AResponse.ResponseCode := 400;
      AResponse.Headers.AddValue('Content-Type', 'text/html');
      AResponse.ContentText := '<h3>Authorization error</h3><p>This authorization request has expired or was already used.</p>';
      Exit;
    end;
    FPendingRequests.Remove(RequestId);

    if Action <> 'approve' then
    begin
      LogMessage(Format('Access denied by user for client %s', [Req.ClientId]));
      AResponse.Redirect(BuildRedirect(Req.RedirectURI, [
        TPair<string, string>.Create('error', 'access_denied'),
        TPair<string, string>.Create('state', Req.State)]));
      Exit;
    end;

    ScopeCount := StrToIntDef(GetOrDefault(Form, 'scope_count', '0'), 0);
    SetLength(Granted, ScopeCount);
    GrantedCount := 0;
    for I := 0 to ScopeCount - 1 do
      if GetOrDefault(Form, 'scope_grant_' + IntToStr(I)) = '1' then
      begin
        Granted[GrantedCount] := GetOrDefault(Form, 'scope_name_' + IntToStr(I));
        Inc(GrantedCount);
      end;
    SetLength(Granted, GrantedCount);

    Code.ClientId := Req.ClientId;
    Code.RedirectURI := Req.RedirectURI;
    Code.CodeChallenge := Req.CodeChallenge;
    Code.Resource := Req.Resource;
    Code.Subject := 'demo-user';
    Code.Scopes := Granted;
    Code.Used := False;
    Code.ExpiresAt := Now + (AuthCodeLifetimeSeconds / 86400);

    CodeId := NewId;
    FAuthCodes.AddOrSetValue(CodeId, Code);

    LogMessage(Format('Access approved for client %s, granted scopes: [%s]', [Req.ClientId, ScopesToString(Granted)]));

    AResponse.Redirect(BuildRedirect(Req.RedirectURI, [
      TPair<string, string>.Create('code', CodeId),
      TPair<string, string>.Create('state', Req.State)]));
  finally
    Form.Free;
  end;
end;

procedure TAuthServerHandlers.IssueGrant(const AGrant: TIssuedGrant; out AAccessToken, ARefreshToken: string);
begin
  AAccessToken := NewId;
  ARefreshToken := NewId;
  FAccessTokens.AddOrSetValue(AAccessToken, AGrant);
  FRefreshTokens.AddOrSetValue(ARefreshToken, AGrant);
end;

procedure TAuthServerHandlers.HandleToken(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
var
  Form: TDictionary<string, string>;
  GrantType: string;
  Code: TAuthCode;
  Grant: TIssuedGrant;
  AccessToken, RefreshToken: string;
  RespObj: TJSONObject;
begin
  Form := ParseFormEncoded(ReadBody(ARequest));
  try
    GrantType := GetOrDefault(Form, 'grant_type');

    if GrantType = 'authorization_code' then
    begin
      if not FAuthCodes.TryGetValue(GetOrDefault(Form, 'code'), Code) then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'Unknown authorization code');
        Exit;
      end;
      if Code.Used or (Code.ExpiresAt < Now) then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'Authorization code already used or expired');
        Exit;
      end;
      if Code.ClientId <> GetOrDefault(Form, 'client_id') then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'client_id does not match the authorization request');
        Exit;
      end;
      if Code.RedirectURI <> GetOrDefault(Form, 'redirect_uri') then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'redirect_uri does not match the authorization request');
        Exit;
      end;
      if not PKCEChallengeMatches(GetOrDefault(Form, 'code_verifier'), Code.CodeChallenge) then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'PKCE code_verifier does not match code_challenge');
        Exit;
      end;

      Code.Used := True;
      FAuthCodes.AddOrSetValue(GetOrDefault(Form, 'code'), Code);

      Grant.ClientId := Code.ClientId;
      Grant.Subject := Code.Subject;
      Grant.Resource := Code.Resource;
      Grant.Scopes := Code.Scopes;
      Grant.ExpiresAt := Now + (AccessTokenLifetimeSeconds / 86400);
      IssueGrant(Grant, AccessToken, RefreshToken);

      LogMessage(Format('Issued access token for client %s, subject %s, scopes [%s]',
        [Grant.ClientId, Grant.Subject, ScopesToString(Grant.Scopes)]));
    end
    else if GrantType = 'refresh_token' then
    begin
      if not FRefreshTokens.TryGetValue(GetOrDefault(Form, 'refresh_token'), Grant) then
      begin
        WriteOAuthError(AResponse, 400, 'invalid_grant', 'Unknown refresh token');
        Exit;
      end;
      // Rotate: the old refresh token is single-use.
      FRefreshTokens.Remove(GetOrDefault(Form, 'refresh_token'));
      Grant.ExpiresAt := Now + (AccessTokenLifetimeSeconds / 86400);
      IssueGrant(Grant, AccessToken, RefreshToken);

      LogMessage(Format('Refreshed access token for client %s, subject %s', [Grant.ClientId, Grant.Subject]));
    end
    else
    begin
      WriteOAuthError(AResponse, 400, 'unsupported_grant_type', 'Only authorization_code and refresh_token are supported');
      Exit;
    end;

    RespObj := TJSONObject.Create;
    try
      RespObj.AddPair('access_token', AccessToken);
      RespObj.AddPair('token_type', 'Bearer');
      RespObj.AddPair('expires_in', TJSONNumber.Create(AccessTokenLifetimeSeconds));
      RespObj.AddPair('refresh_token', RefreshToken);
      RespObj.AddPair('scope', ScopesToString(Grant.Scopes));
      WriteJSON(AResponse, RespObj.ToJSON);
    finally
      RespObj.Free;
    end;
  finally
    Form.Free;
  end;
end;

procedure TAuthServerHandlers.HandleIntrospect(ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
var
  Form: TDictionary<string, string>;
  Token: string;
  Grant: TIssuedGrant;
  RespObj: TJSONObject;
begin
  Form := ParseFormEncoded(ReadBody(ARequest));
  try
    Token := GetOrDefault(Form, 'token');
    RespObj := TJSONObject.Create;
    try
      if FAccessTokens.TryGetValue(Token, Grant) and (Grant.ExpiresAt > Now) then
      begin
        RespObj.AddPair('active', TJSONBool.Create(True));
        RespObj.AddPair('sub', Grant.Subject);
        RespObj.AddPair('client_id', Grant.ClientId);
        RespObj.AddPair('scope', ScopesToString(Grant.Scopes));
        RespObj.AddPair('aud', Grant.Resource);
        RespObj.AddPair('exp', TJSONNumber.Create(UnixTimestamp(Grant.ExpiresAt)));
      end
      else
        RespObj.AddPair('active', TJSONBool.Create(False));
      WriteJSON(AResponse, RespObj.ToJSON);
    finally
      RespObj.Free;
    end;
  finally
    Form.Free;
  end;
end;

procedure TAuthServerHandlers.HandleServerRequest(AConnection: TTMSMCPHTTPServerConnection;
  ARequest: TTMSMCPHTTPServerRequest; AResponse: TTMSMCPHTTPServerResponse);
begin
  AResponse.Headers.AddValue('Access-Control-Allow-Origin', '*');
  AResponse.Headers.AddValue('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  AResponse.Headers.AddValue('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if ARequest.CommandType = hsmOPTION then
  begin
    AResponse.ResponseCode := 204;
    Exit;
  end;

  LogMessage(Format('%s %s', [ARequest.Command, ARequest.URI]));

  try
    if (ARequest.URI = '/.well-known/oauth-authorization-server') and (ARequest.CommandType = hsmGET) then
      HandleDiscovery(AResponse)
    else if (ARequest.URI = '/register') and (ARequest.CommandType = hsmPOST) then
      HandleRegister(ARequest, AResponse)
    else if (ARequest.URI = '/authorize') and (ARequest.CommandType = hsmGET) then
      HandleAuthorize(ARequest, AResponse)
    else if (ARequest.URI = '/authorize/approve') and (ARequest.CommandType = hsmPOST) then
      HandleApprove(ARequest, AResponse)
    else if (ARequest.URI = '/token') and (ARequest.CommandType = hsmPOST) then
      HandleToken(ARequest, AResponse)
    else if (ARequest.URI = '/introspect') and (ARequest.CommandType = hsmPOST) then
      HandleIntrospect(ARequest, AResponse)
    else
    begin
      AResponse.ResponseCode := 404;
      AResponse.Headers.AddValue('Content-Type', 'application/json');
      AResponse.ContentText := '{"error":"not_found"}';
    end;
  except
    on E: Exception do
    begin
      LogMessage('Error: ' + E.Message);
      WriteOAuthError(AResponse, 500, 'server_error', E.Message);
    end;
  end;
end;

var
  HttpServer: TTMSMCPHTTPServer;
  Handlers: TAuthServerHandlers;

begin
  HttpServer := nil;
  Handlers := TAuthServerHandlers.Create;
  try
    Handlers.LogMessage('Starting Demo OAuth Authorization Server...');

    HttpServer := TTMSMCPHTTPServer.Create(nil);
    HttpServer.OnCommandGet := Handlers.HandleServerRequest;
    HttpServer.OnCommandOther := Handlers.HandleServerRequest;
    HttpServer.Port := Port;
    HttpServer.Active := True;

    Handlers.LogMessage(Format('Listening on %s', [Issuer]));
    Handlers.LogMessage('Discovery:    ' + Issuer + '/.well-known/oauth-authorization-server');
    Handlers.LogMessage('Register:     POST ' + Issuer + '/register');
    Handlers.LogMessage('Authorize:    GET  ' + Issuer + '/authorize');
    Handlers.LogMessage('Token:        POST ' + Issuer + '/token');
    Handlers.LogMessage('Introspect:   POST ' + Issuer + '/introspect');
    Handlers.LogMessage('Ready. Press Ctrl+C to stop.');

    while True do
      Sleep(1000);
  except
    on E: Exception do
    begin
      Handlers.LogMessage(Format('Fatal error: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;

  FreeAndNil(HttpServer);
  Handlers.Free;
end.
