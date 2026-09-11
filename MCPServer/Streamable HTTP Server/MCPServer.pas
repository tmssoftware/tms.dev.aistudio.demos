unit MCPServer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  Data.DB,
  Data.SqlExpr,
  Data.DbxSqlite,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Resources;

type
  TDatabaseMCPServer = class(TTMSMCPServer)
  private
    FConnection: TSQLConnection;
    FDatabaseFile: string;
    procedure SetDatabaseFile(const Value: string);
    procedure InitializeDatabase;
    procedure SetupTools;
    procedure SetupResources;
    function ExecuteQuery(const SQL: string; const Params: TJSONObject = nil): TJSONObject;
    function GetTableSchema(const TableName: string): TJSONObject;
    function ListTables: TJSONArray;
  protected
    procedure DoListTools(Sender: TObject; const ToolList: TTMSMCPToolsCollection); override;
    procedure DoListResources(Sender: TObject; const ResourceList: TTMSMCPResourceCollection); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Start; override;
    property DatabaseFile: string read FDatabaseFile write SetDatabaseFile;
  end;

implementation

{ TDatabaseMCPServer }

constructor TDatabaseMCPServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FConnection := TSQLConnection.Create(nil);
  FConnection.DriverName := 'Sqlite';
  FConnection.LoginPrompt := False;

  // Enable logging
  EnableToolNotifications := True;
  EnableResourceNotifications := True;
end;

destructor TDatabaseMCPServer.Destroy;
begin
  if FConnection.Connected then
    FConnection.Close;
  FConnection.Free;
  inherited;
end;

procedure TDatabaseMCPServer.SetDatabaseFile(const Value: string);
begin
  FDatabaseFile := Value;
  if Assigned(FConnection) then
  begin
    FConnection.Params.Values['Database'] := FDatabaseFile;
  end;
end;

procedure TDatabaseMCPServer.InitializeDatabase;
begin
  try
    if not FileExists(FDatabaseFile) then
    begin
      LogMessage('Creating demo database...');

      // Create demo tables
      ExecuteQuery('CREATE TABLE IF NOT EXISTS customers (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'name TEXT NOT NULL, ' +
                  'email TEXT UNIQUE, ' +
                  'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)');

      ExecuteQuery('CREATE TABLE IF NOT EXISTS orders (' +
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                  'customer_id INTEGER, ' +
                  'total DECIMAL(10,2), ' +
                  'status TEXT, ' +
                  'created_at DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
                  'FOREIGN KEY (customer_id) REFERENCES customers(id))');

      // Insert sample data
      ExecuteQuery('INSERT INTO customers (name, email) VALUES ' +
                  '("John Doe", "john@example.com"), ' +
                  '("Jane Smith", "jane@example.com"), ' +
                  '("Bob Johnson", "bob@example.com")');

      ExecuteQuery('INSERT INTO orders (customer_id, total, status) VALUES ' +
                  '(1, 99.99, "completed"), ' +
                  '(2, 149.50, "pending"), ' +
                  '(1, 75.25, "completed"), ' +
                  '(3, 200.00, "shipped")');

      LogMessage('Demo database created with sample data');
    end;
  except
    on E: Exception do
      LogMessage('Database initialization error: ' + E.Message);
  end;
end;

procedure TDatabaseMCPServer.SetupTools;
var
  QueryTool: TTMSMCPTool;
  ListTablesTool: TTMSMCPTool;
  SchemaTool: TTMSMCPTool;
begin
  Tools.Clear;

  // Query execution tool
  QueryTool := Tools.Add;
  QueryTool.Name := 'execute_query';
  QueryTool.Description := 'Execute a readonly SQL query against the database';

  with QueryTool.InputSchema.Properties.Add do
  begin
    Name := 'sql';
    DataType := 'string';
    Description := 'The SQL query to execute (SELECT statements only)';
    Required := True;
  end;

  QueryTool.OnExecute := function(const Params: TJSONObject): TJSONObject
    var
      SQL: string;
    begin
      SQL := Params.GetValue<string>('sql');

      // Security check - only allow SELECT statements
      if not SQL.Trim.ToUpper.StartsWith('SELECT') then
        raise Exception.Create('Only SELECT queries are allowed');

      LogMessage(Format('Executing query: %s', [SQL]));
      Result := ExecuteQuery(SQL);
    end;

  // List tables tool
  ListTablesTool := Tools.Add;
  ListTablesTool.Name := 'list_tables';
  ListTablesTool.Description := 'List all tables in the database';

  ListTablesTool.OnExecute := function(const Params: TJSONObject): TJSONObject
    begin
      LogMessage('Listing database tables');
      Result := TJSONObject.Create;
      Result.AddPair('tables', ListTables);
    end;

  // Schema tool
  SchemaTool := Tools.Add;
  SchemaTool.Name := 'get_schema';
  SchemaTool.Description := 'Get the schema definition for a specific table';

  with SchemaTool.InputSchema.Properties.Add do
  begin
    Name := 'table_name';
    DataType := 'string';
    Description := 'Name of the table to get schema for';
    Required := True;
  end;

  SchemaTool.OnExecute := function(const Params: TJSONObject): TJSONObject
    var
      TableName: string;
    begin
      TableName := Params.GetValue<string>('table_name');
      LogMessage(Format('Getting schema for table: %s', [TableName]));
      Result := GetTableSchema(TableName);
    end;
end;

procedure TDatabaseMCPServer.SetupResources;
var
  TablesResource: TTMSMCPResource;
  DataResource: TTMSMCPResource;
begin
  Resources.Clear;

  // Tables resource
  TablesResource := Resources.Add;
  TablesResource.URI := 'database://tables';
  TablesResource.Name := 'Database Tables';
  TablesResource.Description := 'List of all database tables';
  TablesResource.MimeType := 'application/json';

  TablesResource.OnRead := function(const URI: string): TJSONObject
    begin
      Result := TJSONObject.Create;
      Result.AddPair('tables', ListTables);
    end;

  // Sample data resource
  DataResource := Resources.Add;
  DataResource.URI := 'database://sample-data';
  DataResource.Name := 'Sample Data';
  DataResource.Description := 'Sample customer and order data';
  DataResource.MimeType := 'application/json';

  DataResource.OnRead := function(const URI: string): TJSONObject
    begin
      Result := ExecuteQuery('SELECT c.name, c.email, COUNT(o.id) as order_count, ' +
                           'SUM(o.total) as total_spent FROM customers c ' +
                           'LEFT JOIN orders o ON c.id = o.customer_id ' +
                           'GROUP BY c.id, c.name, c.email');
    end;
end;

procedure TDatabaseMCPServer.Start;
begin
  LogMessage('Connecting to database...');

  if FDatabaseFile = '' then
    FDatabaseFile := 'demo.db';

  FConnection.Params.Values['Database'] := FDatabaseFile;

  try
    FConnection.Open;
    LogMessage('Database connected successfully');

    InitializeDatabase;
    SetupTools;
    SetupResources;

    inherited Start;

  except
    on E: Exception do
    begin
      LogMessage('Failed to start database server: ' + E.Message);
      raise;
    end;
  end;
end;

procedure TDatabaseMCPServer.DoListTools(Sender: TObject; const ToolList: TTMSMCPToolsCollection);
begin
  LogMessage(Format('Tools requested - %d tools available', [ToolList.Count]));
  inherited DoListTools(Sender, ToolList);
end;

procedure TDatabaseMCPServer.DoListResources(Sender: TObject; const ResourceList: TTMSMCPResourceCollection);
begin
  LogMessage(Format('Resources requested - %d resources available', [ResourceList.Count]));
  inherited DoListResources(Sender, ResourceList);
end;

function TDatabaseMCPServer.ExecuteQuery(const SQL: string; const Params: TJSONObject): TJSONObject;
var
  Query: TSQLQuery;
  ResultArray: TJSONArray;
  RowObject: TJSONObject;
  i: Integer;
begin
  Result := TJSONObject.Create;
  ResultArray := TJSONArray.Create;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FConnection;
    Query.SQL.Text := SQL;

    try
      Query.Open;

      while not Query.Eof do
      begin
        RowObject := TJSONObject.Create;

        for i := 0 to Query.FieldCount - 1 do
        begin
          case Query.Fields[i].DataType of
            ftString, ftWideString, ftMemo, ftWideMemo:
              RowObject.AddPair(Query.Fields[i].FieldName, Query.Fields[i].AsString);
            ftInteger, ftSmallint, ftWord, ftLargeint:
              RowObject.AddPair(Query.Fields[i].FieldName, TJSONNumber.Create(Query.Fields[i].AsInteger));
            ftFloat, ftCurrency, ftBCD:
              RowObject.AddPair(Query.Fields[i].FieldName, TJSONNumber.Create(Query.Fields[i].AsFloat));
            ftBoolean:
              RowObject.AddPair(Query.Fields[i].FieldName, TJSONBool.Create(Query.Fields[i].AsBoolean));
            ftDateTime, ftDate, ftTime:
              RowObject.AddPair(Query.Fields[i].FieldName, Query.Fields[i].AsString);
          else
            RowObject.AddPair(Query.Fields[i].FieldName, Query.Fields[i].AsString);
          end;
        end;

        ResultArray.AddElement(RowObject);
        Query.Next;
      end;

      Result.AddPair('success', TJSONBool.Create(True));
      Result.AddPair('data', ResultArray);
      Result.AddPair('rowCount', TJSONNumber.Create(ResultArray.Count));

    except
      on E: Exception do
      begin
        ResultArray.Free;
        Result.AddPair('success', TJSONBool.Create(False));
        Result.AddPair('error', E.Message);
        LogMessage('Query error: ' + E.Message);
      end;
    end;

  finally
    Query.Free;
  end;
end;

function TDatabaseMCPServer.GetTableSchema(const TableName: string): TJSONObject;
var
  Query: TSQLQuery;
  ColumnsArray: TJSONArray;
  ColumnObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  ColumnsArray := TJSONArray.Create;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FConnection;
    Query.SQL.Text := Format('PRAGMA table_info(%s)', [TableName]);

    try
      Query.Open;

      while not Query.Eof do
      begin
        ColumnObject := TJSONObject.Create;
        ColumnObject.AddPair('name', Query.FieldByName('name').AsString);
        ColumnObject.AddPair('type', Query.FieldByName('type').AsString);
        ColumnObject.AddPair('notnull', TJSONBool.Create(Query.FieldByName('notnull').AsBoolean));
        ColumnObject.AddPair('pk', TJSONBool.Create(Query.FieldByName('pk').AsBoolean));

        if not Query.FieldByName('dflt_value').IsNull then
          ColumnObject.AddPair('default', Query.FieldByName('dflt_value').AsString);

        ColumnsArray.AddElement(ColumnObject);
        Query.Next;
      end;

      Result.AddPair('table', TableName);
      Result.AddPair('columns', ColumnsArray);

    except
      on E: Exception do
      begin
        ColumnsArray.Free;
        Result.AddPair('error', E.Message);
      end;
    end;

  finally
    Query.Free;
  end;
end;

function TDatabaseMCPServer.ListTables: TJSONArray;
var
  Query: TSQLQuery;
begin
  Result := TJSONArray.Create;

  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := FConnection;
    Query.SQL.Text := 'SELECT name FROM sqlite_master WHERE type="table" AND name NOT LIKE "sqlite_%"';

    try
      Query.Open;

      while not Query.Eof do
      begin
        Result.Add(Query.FieldByName('name').AsString);
        Query.Next;
      end;

    except
      on E: Exception do
      begin
        LogMessage('Error listing tables: ' + E.Message);
      end;
    end;

  finally
    Query.Free;
  end;
end;

end.
