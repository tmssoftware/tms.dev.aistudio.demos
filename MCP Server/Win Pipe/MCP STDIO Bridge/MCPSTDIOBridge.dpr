program MCPSTDIOBridge;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  TMS.MCP.transport.pipes,
  Winapi.Windows;

function BuildFullPipeName(const APipeName, AServerName: string): string;
begin
  if AServerName = '' then
    Result := Format('\\.\pipe\%s', [APipeName])
  else
    Result := Format('\\%s\pipe\%s', [AServerName, APipeName]);
end;

function IsNotification(const JsonStr: string): Boolean;
var
  JsonValue: TJSONValue;
begin
  Result := False;
  JsonValue := TJSONObject.ParseJSONValue(JsonStr);
  if Assigned(JsonValue) then
  try
    if JsonValue is TJSONObject then
    begin
      // Check if it's a JSON-RPC notification (no 'id' field)
      Result := TJSONObject(JsonValue).Values['id'] = nil;
    end;
  finally
    JsonValue.Free;
  end;
end;

function SendNotificationAsync(const PipeName, Message: string): Boolean;
var
  PipeHandle: THandle;
  BytesWritten: DWORD;
  AnsiMessage: AnsiString;
begin
  Result := False;

  // Try to connect to the pipe with a short timeout
  if not WaitNamedPipe(PChar(PipeName), 1000) then
    Exit;

  PipeHandle := CreateFile(
    PChar(PipeName),
    GENERIC_WRITE,
    0, nil, OPEN_EXISTING, 0, 0);

  if PipeHandle = INVALID_HANDLE_VALUE then
    Exit;

  try
    AnsiMessage := AnsiString(Message);
    Result := WriteFile(PipeHandle, AnsiMessage[1], Length(AnsiMessage), BytesWritten, nil);
  finally
    CloseHandle(PipeHandle);
  end;
end;

function SendRequestSync(const PipeName, Message: string; Timeout: DWORD): string;
begin
  // Use the existing SendPipeRequest for requests that need responses
  Result := SendPipeRequest(PipeName, Message, Timeout);
end;

var
  PipeName, ServerName: string;
  FullPipeName: string;
  Line: string;

begin
  try
    // Parse command line arguments
    if ParamCount > 0 then
      PipeName := ParamStr(1)
    else
      PipeName := 'MCPServer';

    if ParamCount > 1 then
      ServerName := ParamStr(2)
    else
      ServerName := '';

    FullPipeName := BuildFullPipeName(PipeName, ServerName);
    WriteLn(ErrOutput, Format('Connecting to pipe: %s', [FullPipeName]));

    // Main loop - process STDIN line by line
    while not Eof(Input) do
    begin
      ReadLn(Line);
      if Line.Trim.IsEmpty then
        Continue;

      try
        if IsNotification(Line) then
        begin
          // Send notification without waiting for response
          if not SendNotificationAsync(FullPipeName, Line) then
            WriteLn(ErrOutput, 'Warning: Failed to send notification');
        end
        else
        begin
          // Send request and wait for response
          try
            WriteLn(SendRequestSync(FullPipeName, Line, 30000));
            Flush(Output);
          except
            on E: Exception do
              WriteLn(ErrOutput, Format('Error: %s', [E.Message]));
          end;
        end;
      except
        on E: Exception do
          WriteLn(ErrOutput, Format('Error processing message: %s', [E.Message]));
      end;
    end;

  except
    on E: Exception do
      WriteLn(ErrOutput, E.ClassName, ': ', E.Message);
  end;
end.
