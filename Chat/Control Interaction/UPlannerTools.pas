unit UPlannerTools;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  TMS.MCP.CloudAI, FMX.TMSFNCPlanner, FMX.TMSFNCPlannerData;

type
  TPlannerToolLogEvent = procedure(Sender: TObject; const AName, AArguments, AResult: string) of object;
  TPlacement = record
    Item: TTMSFNCPlannerItem;
    Resource: Integer;
    StartTime, EndTime: TDateTime;
  end;

  TPlannerTools = class(TComponent)
  private
    FPlanner: TTMSFNCPlanner;
    FDay: TDateTime;
    FNextID: Integer;
    FOnToolLog: TPlannerToolLogEvent;
    FOnChanged: TNotifyEvent;
    function ResourceIndex(const AID: string): Integer;
    function FindItem(const AID: string): TTMSFNCPlannerItem;
    function PlacementError(const P: TPlacement): string;
    function ReadPlacement(Args: TJSONObject; AItem: TTMSFNCPlannerItem; out P: TPlacement): string;
    function ItemJSON(Item: TTMSFNCPlannerItem): TJSONObject;
    function ScheduleJSON: TJSONObject;
    function FindSlots(Args, Reply: TJSONObject): string;
    function CreateAppointment(Args, Reply: TJSONObject): string;
    function Reschedule(Args, Reply: TJSONObject): string;
    function RunTool(const Name: string; Args: TJSONObject): string;
  public
    procedure ExecuteTool(Sender: TObject; Args: TJSONObject; var Result: string);
    function NewItem(const Title, Notes: string): TTMSFNCPlannerItem;
    function CanPlace(AItem: TTMSFNCPlannerItem; AStart, AEnd: TDateTime; AResource: Integer; out AReason: string): Boolean;
    property Planner: TTMSFNCPlanner read FPlanner write FPlanner;
    property Day: TDateTime read FDay write FDay;
    property OnToolLog: TPlannerToolLogEvent read FOnToolLog write FOnToolLog;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

uses
  System.DateUtils, System.NetEncoding, System.Generics.Collections, FMX.TMSFNCUtils;

function Text(Args: TJSONObject; const Name: string): string;
var
  Value: TJSONValue;
begin
  Result := '';
  Value := Args.GetValue(Name);
  if Value is TJSONString then
    Result := Trim(Value.Value);
end;

function ReadTime(const S: string; Day: TDateTime; out Value: TDateTime): Boolean;
begin
  Result := TryStrToTime(S, Value, TFormatSettings.Invariant);
  if Result then
    Value := Day + Value;
end;

function PlacementOf(Item: TTMSFNCPlannerItem): TPlacement;
begin
  Result.Item := Item;
  Result.Resource := Item.Resource;
  Result.StartTime := Item.StartTime;
  Result.EndTime := Item.EndTime;
end;

function Overlap(const A, B: TPlacement): Boolean;
begin
  Result := (A.Resource = B.Resource) and (A.StartTime < B.EndTime) and (A.EndTime > B.StartTime);
end;

procedure Place(const P: TPlacement);
begin
  P.Item.Resource := P.Resource;
  P.Item.StartTime := P.StartTime;
  P.Item.EndTime := P.EndTime;
end;

function TPlannerTools.ResourceIndex(const AID: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FPlanner.Resources.Count - 1 do
  begin
    if FPlanner.Resources[I].Name = AID then
      Exit(I);
  end;
end;

function TPlannerTools.FindItem(const AID: string): TTMSFNCPlannerItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPlanner.Items.Count - 1 do
  begin
    if FPlanner.Items[I].DBKey = AID then
      Exit(FPlanner.Items[I]);
  end;
end;

function TPlannerTools.CanPlace(AItem: TTMSFNCPlannerItem; AStart, AEnd: TDateTime;
  AResource: Integer; out AReason: string): Boolean;
var
  P: TPlacement;
  I: Integer;
begin
  P.Item := AItem;
  P.Resource := AResource;
  P.StartTime := AStart;
  P.EndTime := AEnd;
  AReason := PlacementError(P);
  if AReason = '' then
  begin
    for I := 0 to FPlanner.Items.Count - 1 do
    begin
      if (FPlanner.Items[I] <> AItem) and Overlap(P, PlacementOf(FPlanner.Items[I])) then
      begin
        AReason := 'Overlaps ' + FPlanner.Items[I].DBKey;
        Break;
      end;
    end;
  end;
  Result := AReason = '';
end;

function TPlannerTools.PlacementError(const P: TPlacement): string;
begin
  Result := '';
  if Assigned(P.Item) and P.Item.DataBoolean then
    Exit('Lunch is reserved');

  if (P.Resource < 0) or (P.Resource >= FPlanner.Resources.Count) then
    Exit('Unknown resource');

  if (P.StartTime < FDay + 9 / 24) or (P.EndTime > FDay + 18 / 24) or (P.StartTime >= P.EndTime) then
    Exit('Use times within 09:00-18:00 on the demo day, with end after start');

  if (MinuteOfTheHour(P.StartTime) mod 15 <> 0) or (MinuteOfTheHour(P.EndTime) mod 15 <> 0) or (SecondOfTheMinute(P.StartTime) <> 0) or (SecondOfTheMinute(P.EndTime) <> 0) then
    Exit('Use 15-minute boundaries');
end;

function TPlannerTools.ReadPlacement(Args: TJSONObject; AItem: TTMSFNCPlannerItem; out P: TPlacement): string;
begin
  P.Item := AItem;
  P.Resource := ResourceIndex(Text(Args, 'resource_id'));
  Result := 'Use a known resource and HH:MM start_time/end_time';
  if (P.Resource < 0) or not ReadTime(Text(Args, 'start_time'), FDay, P.StartTime) or not ReadTime(Text(Args, 'end_time'), FDay, P.EndTime) then
    Exit;

  Result := PlacementError(P);
end;

function TPlannerTools.ItemJSON(Item: TTMSFNCPlannerItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', Item.DBKey);
  Result.AddPair('title', TNetEncoding.HTML.Decode(TTMSFNCUtils.HTMLStrip(Item.Title)));
  Result.AddPair('notes', Item.DataString);
  Result.AddPair('resource_id', FPlanner.Resources[Item.Resource].Name);
  Result.AddPair('start_time', FormatDateTime('hh:nn', Item.StartTime));
  Result.AddPair('end_time', FormatDateTime('hh:nn', Item.EndTime));
  Result.AddPair('duration_minutes', TJSONNumber.Create(MinutesBetween(Item.EndTime, Item.StartTime)));
  Result.AddPair('locked', TJSONBool.Create(Item.DataBoolean));
  Result.AddPair('selected', TJSONBool.Create(FPlanner.SelectedItems.IndexOf(Item) >= 0));
end;

function TPlannerTools.ScheduleJSON: TJSONObject;
var
  Resources, Items: TJSONArray;
  Resource: TJSONObject;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('date', FormatDateTime('yyyy-mm-dd', FDay));
  Result.AddPair('working_hours', '09:00-18:00; lunch 12:00-13:00; 15-minute slots');
  Resources := TJSONArray.Create;
  Result.AddPair('resources', Resources);
  for I := 0 to FPlanner.Resources.Count - 1 do
  begin
    Resource := TJSONObject.Create;
    Resource.AddPair('id', FPlanner.Resources[I].Name);
    Resource.AddPair('role', FPlanner.Resources[I].Hint);
    Resources.AddElement(Resource);
  end;
  Items := TJSONArray.Create;
  Result.AddPair('appointments', Items);
  for I := 0 to FPlanner.Items.Count - 1 do
    Items.AddElement(ItemJSON(FPlanner.Items[I]));
end;

function TPlannerTools.FindSlots(Args, Reply: TJSONObject): string;
var
  IDs, Slots: TJSONArray;
  Resources: TArray<Integer>;
  I, J, Duration, Longest, Length: Integer;
  Number: Double;
  Start, Finish, Cursor, WindowStart: TDateTime;
  Free: Boolean;
  Reason: string;
  Availability, Slot: TJSONObject;
begin
  Result := 'Supply unique resource_ids, an integer duration_minutes (15-480), and HH:MM earliest/latest';
  if not (Args.GetValue('resource_ids') is TJSONArray) then
    Exit;

  IDs := Args.GetValue<TJSONArray>('resource_ids');
  if (IDs.Count = 0) or not (Args.GetValue('duration_minutes') is TJSONNumber) or not TryStrToFloat(Args.GetValue('duration_minutes').Value, Number, TFormatSettings.Invariant) then
    Exit;

  if not ((Number >= 15) and (Number <= 480) and (Frac(Number) = 0)) then
    Exit;

  Duration := Round(Number);
  if (Duration < 15) or (Duration > 480) or (Duration mod 15 <> 0) or not ReadTime(Text(Args, 'earliest'), FDay, Start) or not ReadTime(Text(Args, 'latest'), FDay, Finish) then
    Exit;

  if (Start < FDay + 9 / 24) or (Finish > FDay + 18 / 24) or (Start >= Finish) or (MinuteOfTheHour(Start) mod 15 <> 0) or (MinuteOfTheHour(Finish) mod 15 <> 0) then
    Exit;

  SetLength(Resources, IDs.Count);
  for I := 0 to IDs.Count - 1 do
  begin
    Resources[I] := ResourceIndex(IDs.Items[I].Value);
    if not (IDs.Items[I] is TJSONString) or (Resources[I] < 0) then
      Exit;

    for J := 0 to I - 1 do
    begin
      if Resources[I] = Resources[J] then
        Exit;
    end;
  end;
  Availability := TJSONObject.Create;
  Reply.AddPair('availability', Availability);
  Availability.AddPair('resource_ids', IDs.Clone as TJSONArray);
  Availability.AddPair('duration_minutes', TJSONNumber.Create(Duration));
  Slots := TJSONArray.Create;
  Availability.AddPair('slots', Slots);
  WindowStart := 0;
  Longest := 0;
  for I := 0 to MinutesBetween(Finish, Start) div 15 do
  begin
    Cursor := IncMinute(Start, I * 15);
    Free := Cursor < Finish;
    for J in Resources do
      Free := Free and CanPlace(nil, Cursor, IncMinute(Cursor, 15), J, Reason);

    if Free and (WindowStart = 0) then
      WindowStart := Cursor;

    if not Free and (WindowStart <> 0) then
    begin
      Length := MinutesBetween(Cursor, WindowStart);
      if Length > Longest then
        Longest := Length;

      if Length >= Duration then
      begin
        Slot := TJSONObject.Create;
        Slot.AddPair('start_time', FormatDateTime('hh:nn', WindowStart));
        Slot.AddPair('end_time', FormatDateTime('hh:nn', IncMinute(WindowStart, Duration)));
        Slot.AddPair('available_until', FormatDateTime('hh:nn', Cursor));
        Slots.AddElement(Slot);
      end;
      WindowStart := 0;
    end;
  end;
  Availability.AddPair('found', TJSONBool.Create(Slots.Count > 0));
  Availability.AddPair('longest_common_free_minutes', TJSONNumber.Create(Longest));
  if Slots.Count > 0 then
    Availability.AddPair('earliest_slot', Slots.Items[0].Clone as TJSONObject)
  else
    Availability.AddPair('earliest_slot', TJSONNull.Create);
  Result := '';
end;

function TPlannerTools.NewItem(const Title, Notes: string): TTMSFNCPlannerItem;
begin
  Inc(FNextID);
  Result := FPlanner.Items.Add;
  Result.DBKey := Format('APT-%.3d', [FNextID]);
  Result.Title := TNetEncoding.HTML.Encode(Title);
  Result.DataString := Notes;
  Result.UseDefaultAppearance := True;
end;

function TPlannerTools.CreateAppointment(Args, Reply: TJSONObject): string;
var
  P: TPlacement;
  Reason: string;
begin
  Result := ReadPlacement(Args, nil, P);
  if Result <> '' then
    Exit;

  if (Text(Args, 'title') = '') or (Length(Text(Args, 'title')) > 120) or not (Args.GetValue('notes') is TJSONString) or (Length(Text(Args, 'notes')) > 1000) then
    Exit('Supply a title (1-120 characters) and notes (up to 1000 characters; empty is allowed)');

  if not CanPlace(nil, P.StartTime, P.EndTime, P.Resource, Reason) then
    Exit(Reason);

  P.Item := NewItem(Text(Args, 'title'), Text(Args, 'notes'));
  Place(P);
  FPlanner.ClearSelection;
  FPlanner.SelectItem(P.Item);
  Reply.AddPair('appointment', ItemJSON(P.Item));
end;

function TPlannerTools.Reschedule(Args, Reply: TJSONObject): string;
var
  Changes, Items: TJSONArray;
  Plan: TArray<TPlacement>;
  Changed: TArray<Boolean>;
  Value: TJSONValue;
  Item: TTMSFNCPlannerItem;
  I, J, First: Integer;
begin
  Result := 'Supply a nonempty changes array with each existing appointment listed once';
  if not (Args.GetValue('changes') is TJSONArray) then
    Exit;

  Changes := Args.GetValue<TJSONArray>('changes');
  if (Changes.Count = 0) or (Changes.Count > FPlanner.Items.Count) then
    Exit;

  SetLength(Plan, FPlanner.Items.Count);
  SetLength(Changed, FPlanner.Items.Count);
  for I := 0 to High(Plan) do
    Plan[I] := PlacementOf(FPlanner.Items[I]);

  First := -1;
  for Value in Changes do
  begin
    if not (Value is TJSONObject) then
      Exit('Each change must be an object');

    Item := FindItem(Text(TJSONObject(Value), 'appointment_id'));
    if not Assigned(Item) then
      Exit('Unknown appointment_id; read get_schedule for current IDs');

    if Changed[Item.Index] then
      Exit('Duplicate appointment in changes');

    Result := ReadPlacement(TJSONObject(Value), Item, Plan[Item.Index]);
    if Result <> '' then
      Exit;

    Changed[Item.Index] := True;
    if First < 0 then
      First := Item.Index;
  end;
  for I := 0 to High(Plan) do
  begin
    for J := I + 1 to High(Plan) do
    begin
      if Overlap(Plan[I], Plan[J]) then
        Exit('Final schedule overlaps ' + Plan[I].Item.DBKey + ' and ' + Plan[J].Item.DBKey + '; nothing changed');
    end;
  end;
  Items := TJSONArray.Create;
  Reply.AddPair('appointments', Items);
  FPlanner.BeginUpdate;
  try
    for I := 0 to High(Plan) do
    begin
      if Changed[I] then
        Place(Plan[I]);
    end;

    FPlanner.ClearSelection;
    FPlanner.SelectItem(Plan[First].Item);
    for I := 0 to High(Plan) do
    begin
      if Changed[I] then
        Items.AddElement(ItemJSON(Plan[I].Item));
    end;
  finally
    FPlanner.EndUpdate;
  end;
end;

function TPlannerTools.RunTool(const Name: string; Args: TJSONObject): string;
var
  Reply: TJSONObject;
  Error: string;
begin
  Reply := TJSONObject.Create;
  try
    try
      Error := '';
      if not Assigned(Args) then
        Error := 'Arguments must be a JSON object'
      else if Name = 'get_schedule' then
        Reply.AddPair('schedule', ScheduleJSON)
      else if Name = 'find_free_slots' then
        Error := FindSlots(Args, Reply)
      else if Name = 'create_appointment' then
        Error := CreateAppointment(Args, Reply)
      else if Name = 'reschedule_appointments' then
        Error := Reschedule(Args, Reply)
      else
        Error := 'Unknown tool: ' + Name;
    except
      on E: Exception do
        Error := 'Unexpected tool failure: ' + E.Message;
    end;
    Reply.AddPair('ok', TJSONBool.Create(Error = ''));
    if Error <> '' then
      Reply.AddPair('error', Error)
    else if Assigned(FOnChanged) then
      FOnChanged(Self);
    Result := Reply.ToJSON;
  finally
    Reply.Free;
  end;
end;

procedure TPlannerTools.ExecuteTool(Sender: TObject; Args: TJSONObject; var Result: string);
var
  Name, Arguments: string;
begin
  Name := (Sender as TTMSMCPCloudAITool).Name;
  Arguments := '{}';
  if Assigned(Args) then
    Arguments := Args.ToJSON;
  Result := RunTool(Name, Args);
  if Assigned(FOnToolLog) then
    FOnToolLog(Self, Name, Arguments, Result);
end;

end.
