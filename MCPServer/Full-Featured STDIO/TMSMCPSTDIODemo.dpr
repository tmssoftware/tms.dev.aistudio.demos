program TMSMCPSTDIODemo;

{$APPTYPE CONSOLE}

{
  TMS MCP Full-Featured STDIO Server
  ===================================
  Demonstrates Tools, Resources, Prompts and Sampling over STDIO transport.

  HOW TO CONNECT
  --------------
  1. Build this project in Release or Debug configuration (Win32).
     Output: Demos\MCPServer\Full-Featured STDIO Server\Win32\Debug\TMSMCPSTDIODemo.exe

  2. Claude Desktop  (claude_desktop_config.json)
     Add to the "mcpServers" section:
       "tms-stdio-demo": }{
         "command": "C:\\...\\Demos\\MCPServer\\Full-Featured STDIO Server\\Win32\\Debug\\TMSMCPSTDIODemo.exe"
       } {
     Restart Claude Desktop and the server will appear in the tools/resources list.

  3. mcp-inspector  (npx)
       npx @modelcontextprotocol/inspector \
         "C:\...\TMSMCPSTDIODemo.exe"
     This opens a browser UI where you can call each tool/resource/prompt.

  4. Any MCP-compliant client
     Pass the executable path as the STDIO command. The server declares
     protocolVersion 2025-11-25 but negotiates down to what the client supports.
}

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.JSON,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Resources,
  TMS.MCP.Prompts,
  TMS.MCP.Sampling,
  TMS.MCP.Helpers,
  TMS.MCP.Transport.STDIO;

{ ── Tool handlers ─────────────────────────────────────────────────────────── }

function HandleGreet(const Args: array of TValue): TValue;
var
  Name  : string;
  Formal: Boolean;
begin
  Name   := Args[0].AsString;
  Formal := (Length(Args) > 1) and Args[1].AsBoolean;
  if Formal then
    Result := TValue.From<string>('Good day, ' + Name + '. How may I assist you?')
  else
    Result := TValue.From<string>('Hey ' + Name + '!');
end;

function HandleAdd(const Args: array of TValue): TValue;
begin
  Result := TValue.From<Integer>(Args[0].AsInteger + Args[1].AsInteger);
end;

function HandleIsPalindrome(const Args: array of TValue): TValue;
var
  S, Rev: string;
  I     : Integer;
begin
  S   := Args[0].AsString.ToLower;
  Rev := '';
  for I := Length(S) downto 1 do
    Rev := Rev + S[I];
  Result := TValue.From<Boolean>(S = Rev);
end;

function HandleWordCount(const Args: array of TValue): TValue;
var
  Words: TArray<string>;
begin
  Words  := Args[0].AsString.Split([' ', #9, #10, #13], TStringSplitOptions.ExcludeEmpty);
  Result := TValue.From<Integer>(Length(Words));
end;

function HandleCurrentTime(const Args: array of TValue): TValue;
begin
  Result := TValue.From<string>(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
end;

function HandleSystemInfo(const Args: array of TValue): TValue;
var
  Info: TJSONObject;
begin
  Info := TJSONObject.Create;
  try
    Info.AddPair('platform', 'Windows');
    Info.AddPair('executable', ParamStr(0));
    Info.AddPair('pid', TJSONNumber.Create(0));
    Info.AddPair('time', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Result := TValue.From<string>(Info.Format);
  finally
    Info.Free;
  end;
end;

{ ── Resource readers ──────────────────────────────────────────────────────── }

function ReadReadme(const URI: string): TTMSMCPResourceContent;
begin
  Result := TTMSMCPResourceContent.FromText(
    URI,
    'text/plain',
    'TMS MCP STDIO Demo' + sLineBreak +
    'This server demonstrates tools, resources, prompts and sampling.' + sLineBreak +
    'Protocol: MCP 2025-11-25'
  );
end;

function ReadConfig(const URI: string): TTMSMCPResourceContent;
var
  Cfg: TJSONObject;
begin
  Cfg := TJSONObject.Create;
  Cfg.AddPair('server', 'TMSMCPSTDIODemo');
  Cfg.AddPair('version', '1.0.0');
  Cfg.AddPair('transport', 'stdio');
  Result := TTMSMCPResourceContent.FromText(URI, 'application/json', Cfg.Format);
  Cfg.Free;
end;

function ReadUserProfile(const URI: string): TTMSMCPResourceContent;
var
  UserId  : string;
  Parts   : TArray<string>;
  Profile : TJSONObject;
begin
  // URI pattern: users://{user_id}/profile  →  e.g. users://alice/profile
  Parts  := URI.Split(['/']);
  UserId := '';
  if Length(Parts) >= 3 then
    UserId := Parts[2];

  Profile := TJSONObject.Create;
  Profile.AddPair('userId', UserId);
  Profile.AddPair('displayName', UserId.ToUpper);
  Profile.AddPair('email', UserId + '@example.com');
  Profile.AddPair('createdAt', '2025-01-01T00:00:00Z');
  Result := TTMSMCPResourceContent.FromText(URI, 'application/json', Profile.Format);
  Profile.Free;
end;

{ ── Prompt handlers ───────────────────────────────────────────────────────── }

function HandleCodeReviewPrompt(const Args: array of TValue): TTMSMCPPromptMessages;
var
  Code    : string;
  Language: string;
begin
  Code     := Args[0].AsString;
  Language := 'code';
  if Length(Args) > 1 then
    Language := Args[1].AsString;

  Result := TTMSMCPPromptMessages.Create(nil);
  Result.AddUserMessage(
    'Please review the following ' + Language + ' code and provide feedback ' +
    'on correctness, style, and potential improvements:' + sLineBreak + sLineBreak +
    '```' + Language + sLineBreak + Code + sLineBreak + '```'
  );
end;

function HandleSummarisePrompt(const Args: array of TValue): TTMSMCPPromptMessages;
var
  Text  : string;
  Style : string;
begin
  Text  := Args[0].AsString;
  Style := 'concise';
  if Length(Args) > 1 then
    Style := Args[1].AsString;

  Result := TTMSMCPPromptMessages.Create(nil);
  Result.AddUserMessage(
    'Please provide a ' + Style + ' summary of the following text:' +
    sLineBreak + sLineBreak + Text
  );
end;

{ ── Sampling callback ─────────────────────────────────────────────────────── }

procedure OnSamplingRequest(Sender: TObject;
  const SamplingRequest: TTMSMCPSamplingRequest;
  var AResult: TTMSMCPSamplingResult);
var
  FirstMsg: string;
begin
  // In a real server you would call an AI API here.
  // This mock returns a canned response so the demo works without an API key.
  FirstMsg := '';
  if SamplingRequest.Messages.Count > 0 then
    FirstMsg := SamplingRequest.Messages[0].Content.Text;

  AResult := TTMSMCPSamplingResult.Create;
  AResult.Model    := 'demo-model-1.0';
  AResult.Role     := smrAssistant;
  AResult.Content.ContentType := smctText;
  AResult.Content.Text :=
    '[Demo mock response] You asked: "' + FirstMsg + '". ' +
    'Replace this callback with a real AI API call.';
  AResult.StopReason := ssrEndTurn;
end;

{ ── Main ──────────────────────────────────────────────────────────────────── }

var
  Server: TTMSMCPServer;
  Tool  : TTMSMCPTool;
  Prop  : TTMSMCPToolProperty;

begin
  try
    FormatSettings.DecimalSeparator := '.';

    Server := TTMSMCPServer.Create(nil);
    Server.ServerName        := 'TMSMCPSTDIODemo';
    Server.ServerVersion     := '1.0.0';
    Server.ServerDescription := 'TMS MCP full-feature demo: tools, resources, prompts, sampling';

    // ── Tools ─────────────────────────────────────────────────────────────

    // Style 1: manual construction
    Tool             := TTMSMCPTool.Create;
    Tool.Name        := 'greet';
    Tool.Description := 'Returns a personalised greeting. Set formal=true for polite, false for casual.';
    Tool.ReturnType  := ptString;
    Tool.Method      := HandleGreet;

    Prop              := Tool.Properties.Add;
    Prop.Name         := 'name';
    Prop.Description  := 'The name of the person to greet';
    Prop.PropertyType := ptString;
    Prop.Required     := True;

    Prop              := Tool.Properties.Add;
    Prop.Name         := 'formal';
    Prop.Description  := 'Use a formal greeting (true) or casual (false)';
    Prop.PropertyType := ptBoolean;
    Prop.Required     := False;

    Server.Tools.Add(Tool);

    Tool             := TTMSMCPTool.Create;
    Tool.Name        := 'add';
    Tool.Description := 'Adds two integers and returns their sum.';
    Tool.ReturnType  := ptInteger;
    Tool.Method      := HandleAdd;

    Prop              := Tool.Properties.Add;
    Prop.Name         := 'a';
    Prop.Description  := 'First integer';
    Prop.PropertyType := ptInteger;
    Prop.Required     := True;

    Prop              := Tool.Properties.Add;
    Prop.Name         := 'b';
    Prop.Description  := 'Second integer';
    Prop.PropertyType := ptInteger;
    Prop.Required     := True;

    Server.Tools.Add(Tool);

    // Style 2: fluent builder
    Server.Tools.Add(
      TTMSMCPTool.CreateBuilder
        .Name('is_palindrome')
        .Description('Returns true if the input text reads the same forwards and backwards (case-insensitive).')
        .ExecuteCallback(HandleIsPalindrome)
        .ReturnType(ptBoolean)
        .AddProperty
          .Name('text')
          .Description('The text to check')
          .PropertyType(ptString)
          .Required(True)
          .&End
        .Build
    );

    Server.Tools.Add(
      TTMSMCPTool.CreateBuilder
        .Name('word_count')
        .Description('Counts the number of words in the supplied text.')
        .ExecuteCallback(HandleWordCount)
        .ReturnType(ptInteger)
        .AddProperty
          .Name('text')
          .Description('The text whose words should be counted')
          .PropertyType(ptString)
          .Required(True)
          .&End
        .Build
    );

    Server.Tools.Add(
      TTMSMCPTool.CreateBuilder
        .Name('current_time')
        .Description('Returns the current server date and time formatted as YYYY-MM-DD HH:MM:SS.')
        .ExecuteCallback(HandleCurrentTime)
        .ReturnType(ptString)
        .Build
    );

    Server.Tools.Add(
      TTMSMCPTool.CreateBuilder
        .Name('system_info')
        .Description('Returns server system information as a JSON string (platform, executable, PID, time).')
        .ExecuteCallback(HandleSystemInfo)
        .ReturnType(ptString)
        .Build
    );

    // ── Resources ─────────────────────────────────────────────────────────

    // Direct resource: static text file
    Server.Resources.RegisterDirectResource(
      'readme',
      'demo://readme',
      'Server README with a brief description of this demo',
      'text/plain',
      ReadReadme
    );

    // Direct resource: dynamic JSON (re-evaluated on each read)
    Server.Resources.RegisterDirectResource(
      'config',
      'demo://config',
      'Server configuration as JSON',
      'application/json',
      ReadConfig
    );

    // URI template resource: users://{user_id}/profile
    Server.Resources.RegisterTemplateResource(
      'user_profile',
      'users://{user_id}/profile',
      'Returns a mock user profile for any user ID. Example: users://alice/profile',
      'application/json',
      ReadUserProfile
    );

    // ── Prompts ───────────────────────────────────────────────────────────

    Server.Prompts.AddPrompt(
      TTMSMCPPrompt.CreateBuilder()
        .Name('code_review')
        .Description('Generates a code-review prompt for a given snippet')
        .Handler(HandleCodeReviewPrompt)
        .AddArgument
          .Name('code')
          .Description('The source code to review')
          .&End
        .AddArgument
          .Name('language')
          .Description('Programming language (e.g. Delphi, Python, TypeScript). Optional.')
          .&End
        .Build
    );

    Server.Prompts.AddPrompt(TTMSMCPPrompt.CreateBuilder()
        .Name('summarise')
        .Description('Generates a summarisation prompt for a block of text')
        .Handler(HandleSummarisePrompt)
        .AddArgument
          .Name('text')
          .Description('The text to summarise')
          .&End
        .AddArgument
          .Name('style')
          .Description('Summary style: concise, bullet_points, or detailed. Optional, default concise.')
          .&End
        .Build()

    );

    // ── Sampling ──────────────────────────────────────────────────────────

    Server.EnableSampling    := True;
    //Server.OnSamplingRequest := OnSamplingRequest;

    // ── Start ─────────────────────────────────────────────────────────────

    Server.Start;
    Server.Run;

  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'Fatal: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
