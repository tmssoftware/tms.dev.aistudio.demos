unit TMSMCPStellarDS;

interface

uses
  System.SysUtils, System.Classes, System.JSON, DB,
  TMS.MCP.CloudBase, TMS.MCP.Types, TMS.MCP.Utils, TMS.MCP.Attributes;

type
   TTMSMCPCloudMode = (moAsync, moSync);

  TTMSMCPStellarDS = class(TTMSMCPCloudBase)
  private
    FBasePath: string;
    FAccessToken: string;
    FMode: TTMSMCPCloudMode;

    // Handler methods
    procedure HandleGetTableData(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleCreateRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleUpdateRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleDeleteRecord(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleDeleteRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleClearTable(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleGetFields(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleCreateField(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleUpdateField(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleDeleteField(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleGetTables(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleCreateTable(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleUpdateTable(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleDeleteTable(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleGetProjects(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure HandleUpdateProject(const ARequestResult: TTMSMCPCloudBaseRequestResult); virtual;
    procedure SetAccessToken(const Value: string);
    procedure SetMode(const Value: TTMSMCPCloudMode);
  public
    constructor Create(AOwner: TComponent); override;

    // Data Endpoints
    [TTMSMCPTool]
    function GetTableData(const AProjectId: string; ATableId: Int64;
      [TTMSMCPOptional(-1)]AOffset: Int64 = -1; [TTMSMCPOptional(-1)]ATake: Int64 = -1;
      [TTMSMCPOptional('')]
      [TTMSMCPDescription('URL encoded string with the following form: TABLE;FOREIGN_KEY_ID=TABLE_TO_JOIN;ID. Enables you to join 2 tables and fetching the data in 1 request.')]
      const AJoinQuery: string = '';
      [TTMSMCPOptional('')]
      [TTMSMCPDescription('	URL encoded string with the following form: FIELD_NAME;OPERATIONAL_PARAMETER;VALUE. Filters the data you want to query. operators are: equal, like, in, largerthan, smallerthan, or, and, smallerthan_equal, largerthan_equal, not_equal')]
      const AWhereQuery: string = '';
      [TTMSMCPOptional('')]
      [TTMSMCPDescription('URL encoded string with the following form: FIELD_NAME;asc / FIELD_NAME;desc. You can sort on multiple fields by separating the query with "&" (FIELD_A;asc&FIELD_B;desc). There is no limit on the amount of fields you can sort on, but every field can only be used once.')]
      const ASortQuery: string = '';
      [TTMSMCPOptional(false)]ADistinct: Boolean = False;
      [TTMSMCPOptional('')]
      [TTMSMCPDescription('URL encoded string of required fields you need from table separated by ";"')]
      const ASelect: string = ''): TJSONValue;
    [TTMSMCPTool]
    function CreateRecords(const AProjectId: string; ATableId: Int64;
      const ARecords: TJSONArray): TJSONValue;
    [TTMSMCPTool]
    function UpdateRecords(const AProjectId: string; ATableId: Int64;
      const ARecord: TJSONObject; const AIdList: TJSONArray = nil;
      AForce: Boolean = False): TJSONValue;
    [TTMSMCPTool]
    function DeleteRecord(const AProjectId: string; ATableId: Int64;
      ARecordId: Integer): TJSONValue;
    [TTMSMCPTool]
    function DeleteRecords(const AProjectId: string; ATableId: Integer;
      const AIdList: TJSONArray): TJSONValue;
    [TTMSMCPTool]
    function ClearTable(const AProjectId: string; ATableId: Int64): TJSONValue;

    // Field (Metadata) Endpoints
    [TTMSMCPTool]
    function GetFields(const AProjectId: string; ATableId: Integer;
     [TTMSMCPOptional(-1)] AFieldId: Integer = -1): TJSONValue;
    [TTMSMCPTool]
    function CreateField(const AProjectId: string; ATableId: Integer;
      const AFieldName, AFieldType: string): TJSONValue;
    [TTMSMCPTool]
    function UpdateField(const AProjectId: string; ATableId, AFieldId: Integer;
      const AFieldName, AFieldType: string): TJSONValue;
    [TTMSMCPTool]
    function DeleteField(const AProjectId: string; ATableId, AFieldId: Integer): TJSONValue;

    // Table Endpoints
    [TTMSMCPTool]
    function GetTables(const AProjectId: string; [TTMSMCPOptional('')]const ATable: string = ''): TJSONValue;
    [TTMSMCPTool]
    function CreateTable(const AProjectId, ATableName: string;
      [TTMSMCPOptional('')]const ADescription: string = ''; [TTMSMCPOptional(False)]AIsMultitenant: Boolean = False): TJSONValue;
    [TTMSMCPTool]
    function UpdateTable(const AProjectId: string; ATableId: Integer;
      const ATableName: string; [TTMSMCPOptional('')]const ADescription: string = '';
      [TTMSMCPOptional(False)]AIsMultitenant: Boolean = False): TJSONValue;
    [TTMSMCPTool]
    function DeleteTable(const AProjectId: string; ATableId: Integer): TJSONValue;

    // Project Endpoints
    [TTMSMCPTool]
    function GetProjects([TTMSMCPOptional('')]const AProjectId: string = ''): TJSONValue;
    [TTMSMCPTool]
    function UpdateProject(const AProjectId, AName: string;
      [TTMSMCPOptional('')] const ADescription: string = ''; [TTMSMCPOptional(False)]AIsMultitenant: Boolean = False;
      [TTMSMCPOptional(False)]AAllowNewUsers: Boolean = False): TJSONValue;
  published
    Property Mode: TTMSMCPCloudMode read FMode write SetMode;
    Property AccessToken: string read FAccessToken write SetAccessToken;
  end;

implementation

{ TTMSMCPStellarDS }

constructor TTMSMCPStellarDS.Create(AOwner: TComponent);
begin
  inherited;
  FBasePath := '/v1/';
  Service.BaseURL := 'https://api.stellards.io';
end;

{ Data Endpoints }

function TTMSMCPStellarDS.GetTableData(const AProjectId: string;
  ATableId: Int64; AOffset, ATake: Int64; const AJoinQuery, AWhereQuery,
  ASortQuery: string; ADistinct: Boolean; const ASelect: string): TJSONValue;
begin
  Result := nil;
  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'data/table';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);

  if AOffset >= 0 then
    Request.Query := Request.Query + '&Offset=' + IntToStr(AOffset);
  if ATake >= 0 then
    Request.Query := Request.Query + '&Take=' + IntToStr(ATake);
  if AJoinQuery <> '' then
    Request.Query := Request.Query + '&JoinQuery=' + TTMSMCPUtils.URLEncode(AJoinQuery);
  if AWhereQuery <> '' then
    Request.Query := Request.Query + '&WhereQuery=' + TTMSMCPUtils.URLEncode(AWhereQuery);
  if ASortQuery <> '' then
    Request.Query := Request.Query + '&SortQuery=' + TTMSMCPUtils.URLEncode(ASortQuery);
  if ADistinct then
    Request.Query := Request.Query + '&distinct=true';
  if ASelect <> '' then
    Request.Query := Request.Query + '&select=' + TTMSMCPUtils.URLEncode(ASelect);

  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmGET;
  Request.Name := 'GET TABLE DATA';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleGetTableData, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
    if RequestResult.Success and (RequestResult.ResultString <> '') then
      Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleGetTableData(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.CreateRecords(const AProjectId: string;
  ATableId: Int64; const ARecords: TJSONArray): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('records', ARecords.Clone as TJSONArray);

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'data/table';
    Request.Query := 'project=' + AProjectId;
    Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPOST;
    Request.PostData := LBody.ToString;
    Request.Name := 'CREATE RECORDS';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleCreateRecords, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleCreateRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.UpdateRecords(const AProjectId: string;
  ATableId: Int64; const ARecord: TJSONObject; const AIdList: TJSONArray;
  AForce: Boolean): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    if Assigned(AIdList) then
      LBody.AddPair('idList', AIdList.Clone as TJSONArray);
    LBody.AddPair('record', ARecord.Clone as TJSONObject);

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'data/table';
    Request.Query := 'project=' + AProjectId;
    Request.Query := Request.Query + '&table=' + IntToStr(ATableId);

    if AForce then
      Request.Query := Request.Query + '&force=true';

    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPUT;
    Request.PostData := LBody.ToString;
    Request.Name := 'UPDATE RECORDS';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleUpdateRecords, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleUpdateRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.DeleteRecord(const AProjectId: string;
  ATableId: Int64; ARecordId: Integer): TJSONValue;
begin
   Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'data/table';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
  Request.Query := Request.Query + '&record=' + IntToStr(ARecordId);
  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmDELETE;
  Request.Name := 'DELETE RECORD';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleDeleteRecord, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
     if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleDeleteRecord(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.DeleteRecords(const AProjectId: string;
  ATableId: Integer; const AIdList: TJSONArray): TJSONValue;
begin
   Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'data/table/delete';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.AddHeader('Content-Type', 'application/json');
  Request.Method := rmPOST;
  Request.PostData := AIdList.ToString;
  Request.Name := 'DELETE RECORDS';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleDeleteRecords, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
     if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleDeleteRecords(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.ClearTable(const AProjectId: string;
  ATableId: Int64): TJSONValue;
begin
   Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'data/table/clear';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmDELETE;
  Request.Name := 'CLEAR TABLE';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleClearTable, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
     if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleClearTable(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

{ Field Endpoints }

function TTMSMCPStellarDS.GetFields(const AProjectId: string;
  ATableId, AFieldId: Integer): TJSONValue;
begin
  Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'schema/table/field';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);

  if AFieldId >= 0 then
    Request.Query := Request.Query + '&field=' + IntToStr(AFieldId);

  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmGET;
  Request.Name := 'GET FIELDS';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleGetFields, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
    if RequestResult.Success and (RequestResult.ResultString <> '') then
      Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleGetFields(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.CreateField(const AProjectId: string;
  ATableId: Integer; const AFieldName, AFieldType: string): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', AFieldName);
    LBody.AddPair('type', AFieldType);

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'schema/table/field';
    Request.Query := 'project=' + AProjectId;
    Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPOST;
    Request.PostData := LBody.ToString;
    Request.Name := 'CREATE FIELD';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleCreateField, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleCreateField(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.UpdateField(const AProjectId: string;
  ATableId, AFieldId: Integer; const AFieldName, AFieldType: string): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', AFieldName);
    LBody.AddPair('type', AFieldType);

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'schema/table/field';
    Request.Query := 'project=' + AProjectId;
    Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
    Request.Query := Request.Query + '&field=' + IntToStr(AFieldId);
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPUT;
    Request.PostData := LBody.ToString;
    Request.Name := 'UPDATE FIELD';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleUpdateField, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleUpdateField(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.DeleteField(const AProjectId: string;
  ATableId, AFieldId: Integer): TJSONValue;
begin
   Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'schema/table/field';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
  Request.Query := Request.Query + '&field=' + IntToStr(AFieldId);
  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmDELETE;
  Request.Name := 'DELETE FIELD';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleDeleteField, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
     if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleDeleteField(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

{ Table Endpoints }

function TTMSMCPStellarDS.GetTables(const AProjectId, ATable: string): TJSONValue;
begin
  Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'schema/table';
  Request.Query := 'project=' + AProjectId;

  if ATable <> '' then
    Request.Query := Request.Query + '&table=' + ATable;

  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmGET;
  Request.Name := 'GET TABLES';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleGetTables, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
    if RequestResult.Success and (RequestResult.ResultString <> '') then
      Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleGetTables(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.CreateTable(const AProjectId, ATableName,
  ADescription: string; AIsMultitenant: Boolean): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', ATableName);
    LBody.AddPair('description', ADescription);
    LBody.AddPair('isMultitenant', TJSONBool.Create(AIsMultitenant));

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'schema/table';
    Request.Query := 'project=' + AProjectId;
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPOST;
    Request.PostData := LBody.ToString;
    Request.Name := 'CREATE TABLE';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleCreateTable, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleCreateTable(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.UpdateTable(const AProjectId: string;
  ATableId: Integer; const ATableName, ADescription: string;
  AIsMultitenant: Boolean): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', ATableName);
    LBody.AddPair('description', ADescription);
    LBody.AddPair('isMultitenant', TJSONBool.Create(AIsMultitenant));

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'schema/table';
    Request.Query := 'project=' + AProjectId;
    Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPUT;
    Request.PostData := LBody.ToString;
    Request.Name := 'UPDATE TABLE';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleUpdateTable, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleUpdateTable(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

procedure TTMSMCPStellarDS.SetAccessToken(const Value: string);
begin
  FAccessToken := Value;
end;

procedure TTMSMCPStellarDS.SetMode(const Value: TTMSMCPCloudMode);
begin
  FMode := Value;
end;

function TTMSMCPStellarDS.DeleteTable(const AProjectId: string;
  ATableId: Integer): TJSONValue;
begin
   Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'schema/table';
  Request.Query := 'project=' + AProjectId;
  Request.Query := Request.Query + '&table=' + IntToStr(ATableId);
  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmDELETE;
  Request.Name := 'DELETE TABLE';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleDeleteTable, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
     if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleDeleteTable(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

{ Project Endpoints }

function TTMSMCPStellarDS.GetProjects(const AProjectId: string): TJSONValue;
begin
  Result := nil;

  Request.Clear;
  Request.Host := Service.BaseURL;
  Request.Path := FBasePath + 'schema/project';

  if AProjectId <> '' then
    Request.Query := 'project=' + AProjectId;

  Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
  Request.Method := rmGET;
  Request.Name := 'GET PROJECTS';

  if Mode = moAsync then
    ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleGetProjects, nil, True)
  else
  begin
    ExecuteRequest(nil, nil, False);
    if RequestResult.Success and (RequestResult.ResultString <> '') then
      Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
  end;
end;

procedure TTMSMCPStellarDS.HandleGetProjects(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

function TTMSMCPStellarDS.UpdateProject(const AProjectId, AName,
  ADescription: string; AIsMultitenant, AAllowNewUsers: Boolean): TJSONValue;
var
  LBody: TJSONObject;
begin
  Result := nil;

  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', AName);
    LBody.AddPair('description', ADescription);
    LBody.AddPair('isMultitenant', TJSONBool.Create(AIsMultitenant));
    LBody.AddPair('allowNewUsers', TJSONBool.Create(AAllowNewUsers));

    Request.Clear;
    Request.Host := Service.BaseURL;
    Request.Path := FBasePath + 'schema/project';
    Request.Query := 'project=' + AProjectId;
    Request.AddHeader('Authorization', 'Bearer ' + FAccessToken);
    Request.AddHeader('Content-Type', 'application/json');
    Request.Method := rmPUT;
    Request.PostData := LBody.ToString;
    Request.Name := 'UPDATE PROJECT';

    if Mode = moAsync then
      ExecuteRequest({$IFDEF LCLWEBLIB}@{$ENDIF}HandleUpdateProject, nil, True)
    else
    begin
      ExecuteRequest(nil, nil, False);
      if RequestResult.Success and (RequestResult.ResultString <> '') then
        Result := TJSONObject.ParseJSONValue(RequestResult.ResultString);
    end;
  finally
    LBody.Free;
  end;
end;

procedure TTMSMCPStellarDS.HandleUpdateProject(const ARequestResult: TTMSMCPCloudBaseRequestResult);
begin
  // Override in descendant or use event
end;

end.
