unit MCP_STDIO;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  MCP.Transport.Pipes,
  SyncObjs;

type
  TMCP_STDIO_Bridge = class
  private
    PipeClient: TPipeClient;
    PipeName, ServerName: string;
    Running: Boolean;
    Connected: Boolean;
    StdinThread, ConnectThread: TThread;
    ConnectionLock: TCriticalSection;
    procedure HandlePipeMessage(Sender: TObject; Pipe: HPIPE; Stream: TStream);
    procedure HandlePipeDisconnect(Sender: TObject; Pipe: HPIPE);
    procedure HandlePipeError(Sender: TObject; Pipe: HPIPE; PipeContext: TPipeContext; ErrorCode: Integer);
    procedure StdinThreadProc;
    procedure ReconnectThreadProc;
  public
    ExitEvent: TEvent;
    constructor Create(const APipeName, AServerName: string);
    destructor Destroy; override;
    procedure Start;
  end;

implementation

var
  GlobalBridge: TMCP_STDIO_Bridge;

procedure Log(const Message: string);
begin
  WriteLn('[Bridge] ', Message);
end;

function CtrlHandlerRoutine(dwCtrlType: DWORD): BOOL; stdcall;
begin
  Result := False;
  if Assigned(GlobalBridge) then
  begin
    case dwCtrlType of
      CTRL_C_EVENT, CTRL_BREAK_EVENT, CTRL_CLOSE_EVENT:
      begin
        Result := True;
        GlobalBridge.ExitEvent.SetEvent;
      end;
    end;
  end;
end;

{ TMCP_STDIO_Bridge }

constructor TMCP_STDIO_Bridge.Create(const APipeName, AServerName: string);
begin
  inherited Create;
  PipeName := APipeName;
  ServerName := AServerName;
  Running := False;
  Connected := False;
  ExitEvent := TEvent.Create(nil, True, False, '');
  ConnectionLock := TCriticalSection.Create;

  PipeClient := TPipeClient.Create;
  PipeClient.PipeName := PipeName;
  PipeClient.ServerName := ServerName;
  PipeClient.OnPipeMessage := HandlePipeMessage;
  PipeClient.OnPipeDisconnect := HandlePipeDisconnect;
  PipeClient.OnPipeError := HandlePipeError;

  // Register global handler
  GlobalBridge := Self;
  SetConsoleCtrlHandler(@CtrlHandlerRoutine, True);

  // Stdin Thread
  StdinThread := TThread.CreateAnonymousThread(
    procedure
    begin
      StdinThreadProc;
    end
  );
  StdinThread.FreeOnTerminate := False;

  // Reconnect Thread
  ConnectThread := TThread.CreateAnonymousThread(
    procedure
    begin
      ReconnectThreadProc;
    end
  );
  ConnectThread.FreeOnTerminate := False;
end;

destructor TMCP_STDIO_Bridge.Destroy;
begin
  GlobalBridge := nil;
  PipeClient.Free;
  ExitEvent.Free;
  ConnectionLock.Free;
  inherited;
end;

procedure TMCP_STDIO_Bridge.HandlePipeMessage(Sender: TObject; Pipe: HPIPE; Stream: TStream);
var
  Message: AnsiString;
  Size: Integer;
begin
  if Assigned(Stream) and (Stream.Size > 0) then
  begin
    Size := Stream.Size;
    SetLength(Message, Size);
    Stream.Position := 0;
    Stream.Read(Message[1], Size);
    WriteLn(Message);
  end;
end;

procedure TMCP_STDIO_Bridge.HandlePipeDisconnect(Sender: TObject; Pipe: HPIPE);
begin
  ConnectionLock.Enter;
  try
    Connected := False;
    Log('Pipe disconnected.');
  finally
    ConnectionLock.Leave;
  end;
end;

procedure TMCP_STDIO_Bridge.HandlePipeError(Sender: TObject; Pipe: HPIPE; PipeContext: TPipeContext; ErrorCode: Integer);
begin
  Log(Format('Pipe error: %d', [ErrorCode]));
end;

procedure TMCP_STDIO_Bridge.StdinThreadProc;
var
  InputBuffer: array[0..1023] of AnsiChar;
  BytesRead: DWORD;
  StdIn: THandle;
  PendingLine: AnsiString;
  i, LineStart: Integer;
begin
  StdIn := GetStdHandle(STD_INPUT_HANDLE);
  PendingLine := '';

  while Running do
  begin
    try
      if ReadFile(StdIn, InputBuffer, SizeOf(InputBuffer), BytesRead, nil) and (BytesRead > 0) then
      begin
        SetLength(PendingLine, Length(PendingLine) + BytesRead);
        Move(InputBuffer[0], PendingLine[Length(PendingLine) - BytesRead + 1], BytesRead);

        LineStart := 1;
        for i := 1 to Length(PendingLine) do
        begin
          if (PendingLine[i] = #10) or (PendingLine[i] = #13) then
          begin
            if i > LineStart then
            begin
              var Line := Copy(PendingLine, LineStart, i - LineStart);
              ConnectionLock.Enter;
              try
                if Connected then
                  PipeClient.Write(Line[1], Length(Line))
                else
                  Log('Not connected, message not sent');
              finally
                ConnectionLock.Leave;
              end;
            end;
            if (PendingLine[i] = #13) and (i < Length(PendingLine)) and (PendingLine[i + 1] = #10) then
              LineStart := i + 2
            else
              LineStart := i + 1;
          end;
        end;

        if LineStart <= Length(PendingLine) then
          PendingLine := Copy(PendingLine, LineStart, Length(PendingLine))
        else
          PendingLine := '';
      end
      else
        Sleep(50);
    except
      on E: Exception do
        Log('Error in stdin thread: ' + E.Message);
    end;
  end;
end;

procedure TMCP_STDIO_Bridge.ReconnectThreadProc;
begin
  while Running do
  begin
    ConnectionLock.Enter;
    try
      if not Connected then
      begin
        try
          Log('Attempting to connect to pipe...');
          Connected := PipeClient.Connect(5000);
          if Connected then
            Log('Connected to pipe: ' + PipeName)
          else
            Log('Failed to connect, will retry in 5 seconds');
        except
          on E: Exception do
            Log('Connection error: ' + E.Message);
        end;
      end;
    finally
      ConnectionLock.Leave;
    end;
    Sleep(5000);
  end;
end;

procedure TMCP_STDIO_Bridge.Start;
begin
  Running := True;
  Log('Bridge started. Press Ctrl+C to exit.');
  StdinThread.Start;
  ConnectThread.Start;
  ExitEvent.WaitFor(INFINITE);

  // Shutdown
  Log('Shutting down...');
  Running := False;

  StdinThread.WaitFor;
  ConnectThread.WaitFor;

  ConnectionLock.Enter;
  try
    if Connected then
      PipeClient.Disconnect(True);
  finally
    ConnectionLock.Leave;
  end;

  StdinThread.Free;
  ConnectThread.Free;
end;

end.

