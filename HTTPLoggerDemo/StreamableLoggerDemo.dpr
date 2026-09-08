program StreamableLoggerDemo;
{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Rtti,
  System.DateUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Param,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Pool,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait,
  FireDAC.DApt,
  Generics.Collections,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Helpers,
  TMS.MCP.Transport.StreamableHTTP;

type
  TMCPLoggingServer = class
  private
    FConnection: TFDConnection;
    FMCPServer: TTMSMCPServer;
    FHTTPTransport: TTMSMCPStreamableHTTPTransport;
    FPort: Integer;
    FDatabasePath: string;

    procedure InitializeDatabase;
    procedure CreateLoggingTables;
    procedure LogRequest(const AMethod, AParams, AResponse: string; ASuccess: Boolean; AExecutionTime: Integer);

    // Demo tools that generate logs
    function GetDailyLogs(const Args: array of TValue): TValue;
    function GetLogsByMethod(const Args: array of TValue): TValue;
    function GetLogStats(const Args: array of TValue): TValue;
    function SimulateWork(const Args: array of TValue): TValue;
    function TestTool(const Args: array of TValue): TValue;

    // Server events
    procedure OnServerLog(Sender: TObject; const LogMessage: string);
    procedure OnListTools(Sender: TObject; const ToolList: TTMSMCPTools);

  public
    constructor Create(APort: Integer = 8080; const ADatabasePath: string = 'server_logs.db');
    destructor Destroy; override;

    procedure SetupServer;
    procedure Run;
    procedure PopulateSampleData;
  end;

procedure ShowHelp;
begin
  WriteLn('MCP Logging Server');
  WriteLn('=================');
  WriteLn('HTTP-based MCP server that logs all requests to a SQLite database');
  WriteLn('');
  WriteLn('Usage: MCPLoggingServer [options]');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  -p, --port <port>     HTTP port (default: 8080)');
  WriteLn('  -d, --database <path> Database file (default: server_logs.db)');
  WriteLn('  -s, --sample          Create sample log data');
  WriteLn('  -h, --help           Show this help');
  WriteLn('');
  WriteLn('Available at: http://localhost:<port>/mcp');
end;

{ TMCPLoggingServer }

constructor TMCPLoggingServer.Create(APort: Integer; const ADatabasePath: string);
begin
  inherited Create;
  FPort := APort;
  FDatabasePath := ADatabasePath;

  // Initialize database
  FConnection := TFDConnection.Create(nil);
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := FDatabasePath;
  FConnection.LoginPrompt := False;

  InitializeDatabase;

  // Create MCP server
  FMCPServer := TTMSMCPServer.Create(nil);
  FMCPServer.ServerName := 'MCPLoggingServer';
  FMCPServer.ServerVersion := '1.0.0';
  FMCPServer.OnLog := OnServerLog;
  FMCPServer.OnListTools := OnListTools;

  // Create HTTP transport
  FHTTPTransport := TTMSMCPStreamableHTTPTransport.Create(nil, FPort, '/mcp');
  FMCPServer.Transport := FHTTPTransport;
end;

destructor TMCPLoggingServer.Destroy;
begin
  FHTTPTransport.Free;
  FMCPServer.Free;
  FConnection.Free;
  inherited;
end;

procedure TMCPLoggingServer.InitializeDatabase;
begin
  try
    FConnection.Connected := True;
    CreateLoggingTables;
    WriteLn(Format('Database ready: %s', [FDatabasePath]));
  except
    on E: Exception do
    begin
      WriteLn(Format('Database error: %s', [E.Message]));
      raise;
    end;
  end;
end;

procedure TMCPLoggingServer.CreateLoggingTables;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    // Create main logs table
    Query.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS mcp_logs (' +
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      '  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,' +
      '  method TEXT NOT NULL,' +
      '  params TEXT,' +
      '  response TEXT,' +
      '  success BOOLEAN NOT NULL,' +
      '  execution_time_ms INTEGER,' +
      '  request_size INTEGER,' +
      '  response_size INTEGER' +
      ')';
    Query.ExecSQL;

    // Create indexes
    Query.SQL.Text := 'CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON mcp_logs(timestamp)';
    Query.ExecSQL;

    Query.SQL.Text := 'CREATE INDEX IF NOT EXISTS idx_logs_method ON mcp_logs(method)';
    Query.ExecSQL;

  finally
    Query.Free;
  end;
end;

procedure TMCPLoggingServer.LogRequest(const AMethod, AParams, AResponse: string; ASuccess: Boolean; AExecutionTime: Integer);
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;

    Query.SQL.Text :=
      'INSERT INTO mcp_logs (method, params, response, success, execution_time_ms, request_size, response_size) ' +
      'VALUES (:method, :params, :response, :success, :execution_time, :request_size, :response_size)';

    Query.ParamByName('method').AsString := AMethod;
    Query.ParamByName('params').AsString := AParams;
    Query.ParamByName('response').AsString := AResponse;
    Query.ParamByName('success').AsBoolean := ASuccess;
    Query.ParamByName('execution_time').AsInteger := AExecutionTime;
    Query.ParamByName('request_size').AsInteger := Length(AParams);
    Query.ParamByName('response_size').AsInteger := Length(AResponse);

    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TMCPLoggingServer.GetDailyLogs(const Args: array of TValue): TValue;
var
  Query: TFDQuery;
  JsonResult: TJSONObject;
  LogsArray: TJSONArray;
  LogObj: TJSONObject;
  TargetDate: string;
  ArgsObj: TJSONObject;
  StartTime: TDateTime;
begin
  StartTime := Now;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    JsonResult := TJSONObject.Create;
    LogsArray := TJSONArray.Create;

    // Get target date from args
    TargetDate := FormatDateTime('yyyy-mm-dd', Date);
    if Length(Args) > 0 then
    begin
      if not Args[0].IsEmpty then
      begin
        ArgsObj := Args[0].AsType<TJSONObject>;
        if Assigned(ArgsObj) And (Assigned(ArgsObj.GetValue('date'))) then
          TargetDate := ArgsObj.GetValue<string>('date');
      end;
    end;

    Query.SQL.Text :=
      'SELECT * FROM mcp_logs ' +
      'WHERE date(timestamp) = :target_date ' +
      'ORDER BY timestamp DESC ' +
      'LIMIT 50';

    Query.ParamByName('target_date').AsString := TargetDate;
    Query.Open;

    while not Query.Eof do
    begin
      LogObj := TJSONObject.Create;
      LogObj.AddPair('id', TJSONNumber.Create(Query.FieldByName('id').AsInteger));
      LogObj.AddPair('timestamp', TJSONString.Create(Query.FieldByName('timestamp').AsString));
      LogObj.AddPair('method', TJSONString.Create(Query.FieldByName('method').AsString));
      LogObj.AddPair('success', TJSONBool.Create(Query.FieldByName('success').AsBoolean));
      LogObj.AddPair('execution_time_ms', TJSONNumber.Create(Query.FieldByName('execution_time_ms').AsInteger));

      LogsArray.AddElement(LogObj);
      Query.Next;
    end;

    JsonResult.AddPair('date', TJSONString.Create(TargetDate));
    JsonResult.AddPair('logs', LogsArray);
    JsonResult.AddPair('total_count', TJSONNumber.Create(LogsArray.Count));

    // Log this request
    LogRequest('get-daily-logs', Format('{"date":"%s"}', [TargetDate]),
      JsonResult.ToString, True, MilliSecondsBetween(Now, StartTime));

    Result := TValue.From<TJSONObject>(JsonResult);
  finally
    Query.Free;
  end;
end;

function TMCPLoggingServer.GetLogsByMethod(const Args: array of TValue): TValue;
var
  Query: TFDQuery;
  JsonResult: TJSONObject;
  MethodsArray: TJSONArray;
  MethodObj: TJSONObject;
  StartTime: TDateTime;
begin
  StartTime := Now;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    JsonResult := TJSONObject.Create;
    MethodsArray := TJSONArray.Create;

    Query.SQL.Text :=
      'SELECT ' +
      '  method,' +
      '  COUNT(*) as call_count,' +
      '  COUNT(CASE WHEN success = 1 THEN 1 END) as success_count,' +
      '  COUNT(CASE WHEN success = 0 THEN 1 END) as error_count,' +
      '  AVG(execution_time_ms) as avg_time,' +
      '  MAX(execution_time_ms) as max_time,' +
      '  MIN(execution_time_ms) as min_time ' +
      'FROM mcp_logs ' +
      'GROUP BY method ' +
      'ORDER BY call_count DESC';

    Query.Open;

    while not Query.Eof do
    begin
      MethodObj := TJSONObject.Create;
      MethodObj.AddPair('method', TJSONString.Create(Query.FieldByName('method').AsString));
      MethodObj.AddPair('call_count', TJSONNumber.Create(Query.FieldByName('call_count').AsInteger));
      MethodObj.AddPair('success_count', TJSONNumber.Create(Query.FieldByName('success_count').AsInteger));
      MethodObj.AddPair('error_count', TJSONNumber.Create(Query.FieldByName('error_count').AsInteger));
      MethodObj.AddPair('avg_time_ms', TJSONNumber.Create(Query.FieldByName('avg_time').AsFloat));
      MethodObj.AddPair('max_time_ms', TJSONNumber.Create(Query.FieldByName('max_time').AsInteger));
      MethodObj.AddPair('min_time_ms', TJSONNumber.Create(Query.FieldByName('min_time').AsInteger));

      MethodsArray.AddElement(MethodObj);
      Query.Next;
    end;

    JsonResult.AddPair('methods', MethodsArray);

    // Log this request
    LogRequest('get-logs-by-method', '{}', JsonResult.ToString, True, MilliSecondsBetween(Now, StartTime));

    Result := TValue.From<TJSONObject>(JsonResult);
  finally
    Query.Free;
  end;
end;

function TMCPLoggingServer.GetLogStats(const Args: array of TValue): TValue;
var
  Query: TFDQuery;
  JsonResult: TJSONObject;
  StartTime: TDateTime;
begin
  StartTime := Now;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    JsonResult := TJSONObject.Create;

    Query.SQL.Text :=
      'SELECT ' +
      '  COUNT(*) as total_requests,' +
      '  COUNT(CASE WHEN success = 1 THEN 1 END) as successful_requests,' +
      '  COUNT(CASE WHEN success = 0 THEN 1 END) as failed_requests,' +
      '  AVG(execution_time_ms) as avg_execution_time,' +
      '  MAX(execution_time_ms) as max_execution_time,' +
      '  MIN(execution_time_ms) as min_execution_time,' +
      '  AVG(request_size) as avg_request_size,' +
      '  AVG(response_size) as avg_response_size,' +
      '  MIN(timestamp) as first_request,' +
      '  MAX(timestamp) as last_request,' +
      '  COUNT(DISTINCT date(timestamp)) as active_days ' +
      'FROM mcp_logs';

    Query.Open;

    if not Query.Eof then
    begin
      JsonResult.AddPair('total_requests', TJSONNumber.Create(Query.FieldByName('total_requests').AsInteger));
      JsonResult.AddPair('successful_requests', TJSONNumber.Create(Query.FieldByName('successful_requests').AsInteger));
      JsonResult.AddPair('failed_requests', TJSONNumber.Create(Query.FieldByName('failed_requests').AsInteger));
      JsonResult.AddPair('avg_execution_time_ms', TJSONNumber.Create(Query.FieldByName('avg_execution_time').AsFloat));
      JsonResult.AddPair('max_execution_time_ms', TJSONNumber.Create(Query.FieldByName('max_execution_time').AsInteger));
      JsonResult.AddPair('min_execution_time_ms', TJSONNumber.Create(Query.FieldByName('min_execution_time').AsInteger));
      JsonResult.AddPair('avg_request_size', TJSONNumber.Create(Query.FieldByName('avg_request_size').AsFloat));
      JsonResult.AddPair('avg_response_size', TJSONNumber.Create(Query.FieldByName('avg_response_size').AsFloat));
      JsonResult.AddPair('first_request', TJSONString.Create(Query.FieldByName('first_request').AsString));
      JsonResult.AddPair('last_request', TJSONString.Create(Query.FieldByName('last_request').AsString));
      JsonResult.AddPair('active_days', TJSONNumber.Create(Query.FieldByName('active_days').AsInteger));
    end;

    // Log this request
    LogRequest('get-log-stats', '{}', JsonResult.ToString, True, MilliSecondsBetween(Now, StartTime));

    Result := TValue.From<TJSONObject>(JsonResult);
  finally
    Query.Free;
  end;
end;

function TMCPLoggingServer.SimulateWork(const Args: array of TValue): TValue;
var
  JsonResult: TJSONObject;
  ArgsObj: TJSONObject;
  WorkType: string;
  Duration: Integer;
  StartTime: TDateTime;
begin
  StartTime := Now;
  JsonResult := TJSONObject.Create;

  WorkType := 'standard';
  Duration := 100;

  if Length(Args) > 0 then
  begin
    ArgsObj := Args[0].AsType<TJSONObject>;
    if Assigned(ArgsObj.GetValue('work_type')) then
      WorkType := ArgsObj.GetValue<string>('work_type');
    if Assigned(ArgsObj.GetValue('duration')) then
      Duration := ArgsObj.GetValue<Integer>('duration');
  end;

  // Simulate work
  Sleep(Duration);

  JsonResult.AddPair('work_type', TJSONString.Create(WorkType));
  JsonResult.AddPair('duration_ms', TJSONNumber.Create(Duration));
  JsonResult.AddPair('status', TJSONString.Create('completed'));
  JsonResult.AddPair('timestamp', TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)));

  // Log this request
  LogRequest('simulate-work', Format('{"work_type":"%s","duration":%d}', [WorkType, Duration]),
    JsonResult.ToString, True, MilliSecondsBetween(Now, StartTime));

  Result := TValue.From<TJSONObject>(JsonResult);
end;

function TMCPLoggingServer.TestTool(const Args: array of TValue): TValue;
var
  JsonResult: TJSONObject;
  ArgsObj: TJSONObject;
  TestName: string;
  ShouldFail: Boolean;
  StartTime: TDateTime;
  Success: Boolean;
begin
  StartTime := Now;
  JsonResult := TJSONObject.Create;
  Success := True;

  TestName := 'basic_test';
  ShouldFail := False;

  if Length(Args) > 0 then
  begin
    ArgsObj := Args[0].AsType<TJSONObject>;
    if Assigned(ArgsObj.GetValue('test_name')) then
      TestName := ArgsObj.GetValue<string>('test_name');
    if Assigned(ArgsObj.GetValue('should_fail')) then
      ShouldFail := ArgsObj.GetValue<Boolean>('should_fail');
  end;

  JsonResult.AddPair('test_name', TJSONString.Create(TestName));

  if ShouldFail then
  begin
    Success := False;
    JsonResult.AddPair('status', TJSONString.Create('failed'));
    JsonResult.AddPair('error', TJSONString.Create('Intentional test failure'));
  end
  else
  begin
    JsonResult.AddPair('status', TJSONString.Create('passed'));
    JsonResult.AddPair('result', TJSONString.Create('Test completed successfully'));
  end;

  JsonResult.AddPair('execution_time', TJSONNumber.Create(MilliSecondsBetween(Now, StartTime)));

  // Log this request
  LogRequest('test-tool', Format('{"test_name":"%s","should_fail":%s}', [TestName, BoolToStr(ShouldFail, True)]),
    JsonResult.ToString, Success, MilliSecondsBetween(Now, StartTime));

  Result := TValue.From<TJSONObject>(JsonResult);
end;

procedure TMCPLoggingServer.OnServerLog(Sender: TObject; const LogMessage: string);
begin
  WriteLn(Format('[SERVER] %s', [LogMessage]));
end;

procedure TMCPLoggingServer.OnListTools(Sender: TObject; const ToolList: TTMSMCPTools);
begin
  LogRequest('tools/list', '{}', Format('{"tool_count":%d}', [ToolList.Count]), True, 5);
end;

procedure TMCPLoggingServer.SetupServer;
var
  Tool: TTMSMCPTool;
  Prop: TTMSMCPToolProperty;
begin
  // Register logging query tools
  FMCPServer.Tools.RegisterTool('get-daily-logs', 'Get logs for a specific date', GetDailyLogs);

  Tool := FMCPServer.Tools.FindByName('get-daily-logs');
  Prop := Tool.Properties.Add;
  Prop.Name := 'date';
  Prop.Description := 'Date in YYYY-MM-DD format (default: today)';
  Prop.PropertyType := TTMSMCPToolPropertyType.ptString;
  Prop.Required := False;

  FMCPServer.Tools.RegisterTool('get-logs-by-method', 'Get statistics grouped by method', GetLogsByMethod);

  FMCPServer.Tools.RegisterTool('get-log-stats', 'Get overall logging statistics', GetLogStats);

  // Register demo tools that generate activity
  FMCPServer.Tools.RegisterTool('simulate-work', 'Simulate work with configurable duration', SimulateWork);

  Tool := FMCPServer.Tools.FindByName('simulate-work');
  Prop := Tool.Properties.Add;
  Prop.Name := 'work_type';
  Prop.Description := 'Type of work to simulate';
  Prop.PropertyType := TTMSMCPToolPropertyType.ptString;
  Prop.Required := False;

  Prop := Tool.Properties.Add;
  Prop.Name := 'duration';
  Prop.Description := 'Duration in milliseconds';
  Prop.PropertyType := TTMSMCPToolPropertyType.ptInteger;
  Prop.Required := False;

  FMCPServer.Tools.RegisterTool('test-tool', 'Test tool with success/failure modes', TestTool);

  Tool := FMCPServer.Tools.FindByName('test-tool');
  Prop := Tool.Properties.Add;
  Prop.Name := 'test_name';
  Prop.Description := 'Name of the test';
  Prop.PropertyType := TTMSMCPToolPropertyType.ptString;
  Prop.Required := False;

  Prop := Tool.Properties.Add;
  Prop.Name := 'should_fail';
  Prop.Description := 'Whether the test should fail';
  Prop.PropertyType := TTMSMCPToolPropertyType.ptBoolean;
  Prop.Required := False;

  WriteLn(Format('Server configured with %d tools', [FMCPServer.Tools.Count]));
end;

procedure TMCPLoggingServer.PopulateSampleData;
var
  i: Integer;
  Methods: array[0..4] of string;
  WorkTypes: array[0..2] of string;
  TestNames: array[0..2] of string;
  BaseTime: TDateTime;
  Query: TFDQuery;
begin
  WriteLn('Populating sample data...');

  // Initialize arrays
  Methods[0] := 'tools/list';
  Methods[1] := 'simulate-work';
  Methods[2] := 'test-tool';
  Methods[3] := 'get-log-stats';
  Methods[4] := 'get-daily-logs';

  WorkTypes[0] := 'cpu_intensive';
  WorkTypes[1] := 'io_bound';
  WorkTypes[2] := 'network_call';

  TestNames[0] := 'unit_test';
  TestNames[1] := 'integration_test';
  TestNames[2] := 'performance_test';

  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    BaseTime := Now - 7; // Start 7 days ago

    for i := 1 to 1000 do
    begin
      case Random(5) of
        0: // tools/list
          begin
            Query.SQL.Text :=
              'INSERT INTO mcp_logs (timestamp, method, params, response, success, execution_time_ms, request_size, response_size) ' +
              'VALUES (:ts, :method, :params, :response, :success, :exec_time, :req_size, :resp_size)';
            Query.ParamByName('ts').AsDateTime := BaseTime + Random(7) + (Random(24) / 24) + (Random(60) / 1440);
            Query.ParamByName('method').AsString := 'tools/list';
            Query.ParamByName('params').AsString := '{}';
            Query.ParamByName('response').AsString := '{"tool_count":5}';
            Query.ParamByName('success').AsBoolean := True;
            Query.ParamByName('exec_time').AsInteger := Random(20) + 5;
            Query.ParamByName('req_size').AsInteger := 2;
            Query.ParamByName('resp_size').AsInteger := 18;
          end;
        1: // simulate-work
          begin
            var WorkType := WorkTypes[Random(3)];
            var Duration := Random(500) + 100;
            Query.SQL.Text :=
              'INSERT INTO mcp_logs (timestamp, method, params, response, success, execution_time_ms, request_size, response_size) ' +
              'VALUES (:ts, :method, :params, :response, :success, :exec_time, :req_size, :resp_size)';
            Query.ParamByName('ts').AsDateTime := BaseTime + Random(7) + (Random(24) / 24) + (Random(60) / 1440);
            Query.ParamByName('method').AsString := 'simulate-work';
            Query.ParamByName('params').AsString := Format('{"work_type":"%s","duration":%d}', [WorkType, Duration]);
            Query.ParamByName('response').AsString := Format('{"work_type":"%s","duration_ms":%d,"status":"completed"}', [WorkType, Duration]);
            Query.ParamByName('success').AsBoolean := True;
            Query.ParamByName('exec_time').AsInteger := Duration + Random(50);
            Query.ParamByName('req_size').AsInteger := Length(Query.ParamByName('params').AsString);
            Query.ParamByName('resp_size').AsInteger := Length(Query.ParamByName('response').AsString);
          end;
        2: // test-tool
          begin
            var TestName := TestNames[Random(3)];
            var ShouldFail := Random(10) = 0; // 10% failure rate
            Query.SQL.Text :=
              'INSERT INTO mcp_logs (timestamp, method, params, response, success, execution_time_ms, request_size, response_size) ' +
              'VALUES (:ts, :method, :params, :response, :success, :exec_time, :req_size, :resp_size)';
            Query.ParamByName('ts').AsDateTime := BaseTime + Random(7) + (Random(24) / 24) + (Random(60) / 1440);
            Query.ParamByName('method').AsString := 'test-tool';
            Query.ParamByName('params').AsString := Format('{"test_name":"%s","should_fail":%s}', [TestName, BoolToStr(ShouldFail, True)]);
            if ShouldFail then
              Query.ParamByName('response').AsString := Format('{"test_name":"%s","status":"failed","error":"Intentional test failure"}', [TestName])
            else
              Query.ParamByName('response').AsString := Format('{"test_name":"%s","status":"passed","result":"Test completed successfully"}', [TestName]);
            Query.ParamByName('success').AsBoolean := not ShouldFail;
            Query.ParamByName('exec_time').AsInteger := Random(100) + 10;
            Query.ParamByName('req_size').AsInteger := Length(Query.ParamByName('params').AsString);
            Query.ParamByName('resp_size').AsInteger := Length(Query.ParamByName('response').AsString);
          end;
        3, 4: // get-log-stats, get-daily-logs
          begin
            var Method := Methods[Random(2) + 3];
            Query.SQL.Text :=
              'INSERT INTO mcp_logs (timestamp, method, params, response, success, execution_time_ms, request_size, response_size) ' +
              'VALUES (:ts, :method, :params, :response, :success, :exec_time, :req_size, :resp_size)';
            Query.ParamByName('ts').AsDateTime := BaseTime + Random(7) + (Random(24) / 24) + (Random(60) / 1440);
            Query.ParamByName('method').AsString := Method;
            Query.ParamByName('params').AsString := '{}';
            Query.ParamByName('response').AsString := '{"status":"data_returned"}';
            Query.ParamByName('success').AsBoolean := True;
            Query.ParamByName('exec_time').AsInteger := Random(50) + 15;
            Query.ParamByName('req_size').AsInteger := 2;
            Query.ParamByName('resp_size').AsInteger := 25;
          end;
      end;
      Query.ExecSQL;
    end;
  finally
    Query.Free;
  end;

  WriteLn('Created 100 sample log entries');
end;

procedure TMCPLoggingServer.Run;
begin
  try
    FMCPServer.Start;
    WriteLn(Format('Server running at: http://localhost:%d/mcp', [FPort]));
    WriteLn('Press Enter to stop...');
    ReadLn;
  finally
    FMCPServer.Stop;
  end;
end;

// Main program
var
  Server: TMCPLoggingServer;
  Port: Integer;
  DatabasePath: string;
  CreateSample: Boolean;
  i: Integer;
  Param: string;

begin
  try
    Randomize;

    // Defaults
    Port := 8934;
    DatabasePath := 'server_logs.db';
    CreateSample := False;

    // Parse command line
    i := 1;
    while i <= ParamCount do
    begin
      Param := ParamStr(i);

      if (Param = '-h') or (Param = '--help') then
      begin
        ShowHelp;
        Exit;
      end
      else if (Param = '-p') or (Param = '--port') then
      begin
        Inc(i);
        if i <= ParamCount then
          Port := StrToIntDef(ParamStr(i), 8080);
      end
      else if (Param = '-d') or (Param = '--database') then
      begin
        Inc(i);
        if i <= ParamCount then
          DatabasePath := ParamStr(i);
      end
      else if (Param = '-s') or (Param = '--sample') then
      begin
        CreateSample := True;
      end;

      Inc(i);
    end;

    WriteLn('MCP Logging Server Starting...');
    WriteLn(Format('Port: %d', [Port]));
    WriteLn(Format('Database: %s', [DatabasePath]));
    WriteLn('');

    Server := TMCPLoggingServer.Create(Port, DatabasePath);
    try
      Server.SetupServer;

      if CreateSample then
        Server.PopulateSampleData;

      Server.Run;
    finally
      Server.Free;
    end;

  except
    on E: Exception do
    begin
      WriteLn(Format('Error: %s', [E.Message]));
      ExitCode := 1;
    end;
  end;
end.
