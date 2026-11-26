program PlannerToolsTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.DateUtils,
  System.Generics.Collections,
  FMX.Forms, FMX.Graphics, FMX.TMSFNCPlanner, FMX.TMSFNCPlannerData,
  TMS.MCP.ChatView, TMS.MCP.CloudAI,
  UPlannerTools in '..\UPlannerTools.pas', Umain in '..\Umain.pas';

type
  TPromptRecorder = class
    Prompts: TStringList;
    Accept: Boolean;
    procedure CaptureSend(Sender: TObject; const ADraft: string; var AAccepted: Boolean);
  end;

  TOpenAIRecorder = class
    Tools: TStringList;
    Failed: Boolean;
    LastCommonResult: string;
    procedure CaptureTool(Sender: TObject; const AName, AArguments, AResult: string);
    procedure CaptureError(Sender: TObject; const AError: string);
  end;

var
  Form: TForm3;
  Planner: TTMSFNCPlanner;
  ToolSet: TPlannerTools;
  Checks: Integer;

procedure TPromptRecorder.CaptureSend(Sender: TObject; const ADraft: string; var AAccepted: Boolean);
begin
  Prompts.Add(Trim(ADraft));
  AAccepted := Accept;
  if Accept then
    (Sender as TTMSMCPChatView).AddMessage(ADraft, cvrOutgoing);
end;

procedure TOpenAIRecorder.CaptureTool(Sender: TObject; const AName, AArguments, AResult: string);
begin
  Tools.Add(AName);
  if AName = 'find_free_slots' then
    LastCommonResult := AResult;
end;

procedure TOpenAIRecorder.CaptureError(Sender: TObject; const AError: string);
begin
  // Do not print provider errors: they can contain credential fragments.
  Failed := True;
end;

procedure Check(Condition: Boolean; const Message: string);
begin
  if not Condition then
    raise Exception.Create(Message);
  Inc(Checks);
end;

function Call(const Name, Arguments: string; ExpectedOK: Boolean = True): TJSONObject;
var
  Args: TJSONObject;
  Response: string;
begin
  Args := TJSONObject.ParseJSONValue(Arguments) as TJSONObject;
  try
    Form.TMSMCPCloudAI1.Tools.Execute(Name, Args, Response);
  finally
    Args.Free;
  end;
  Result := TJSONObject.ParseJSONValue(Response) as TJSONObject;
  Check(Assigned(Result), Name + ' returned invalid JSON');
  Check(Result.GetValue<Boolean>('ok') = ExpectedOK, Name + ': ' + Response);
end;

function ByTitle(const Title: string; Resource: Integer = -1): TTMSFNCPlannerItem;
var
  I: Integer;
begin
  for I := 0 to Planner.Items.Count - 1 do
    if (Planner.Items[I].Title = Title) and ((Resource < 0) or (Planner.Items[I].Resource = Resource)) then
      Exit(Planner.Items[I]);
  raise Exception.Create('Missing sample appointment: ' + Title);
end;

function Snapshot: string;
var
  Reply: TJSONObject;
begin
  Reply := Call('get_schedule', '{}');
  try
    Result := Reply.ToJSON;
  finally
    Reply.Free;
  end;
end;

function MoveJSON(Item: TTMSFNCPlannerItem; const Resource, StartTime, EndTime: string): string;
begin
  Result := '{"appointment_id":"' + Item.DBKey + '","resource_id":"' + Resource
    + '","start_time":"' + StartTime + '","end_time":"' + EndTime + '"}';
end;

procedure Run;
var
  Reply: TJSONObject;
  Before, CreatedID, OriginalID, Reason: string;
  Debugging, Review, Deployment, Item, Lunch: TTMSFNCPlannerItem;
  Resource: TTMSFNCPlannerResource;
  Bitmap: TBitmap;
  StartTime, EndTime: TDateTime;
  Position: Integer;
  Allowed: Boolean;
  Welcome: TTMSMCPChatViewMessage;
  Recorder: TPromptRecorder;
  Activation: TTMSMCPChatViewInteractionActivation;
  Tool: TTMSMCPCloudAITool;
  Handler: TTMSMCPCloudAIToolExecuteEvent;
  I, J: Integer;
const
  ToolNames: array[0..3] of string = ('get_schedule', 'find_free_slots',
    'create_appointment', 'reschedule_appointments');
  ParameterCounts: array[0..3] of Integer = (0, 4, 5, 1);
begin
  Application.Initialize;
  Form := TForm3.Create(nil);
  try
    Planner := Form.Planner1;
    ToolSet := Form.FindComponent('PlannerTools') as TPlannerTools;
    Check(Assigned(Planner) and (Planner = Form.FindComponent('Planner1')), 'Designer Planner field not connected');
    Check((Planner.Width > 600) and (Planner.Height > 400), 'Planner layout too small');
    Check(Planner.Resources.Count = 3, 'Expected three designer resources');
    Check(Planner.Items.Count = 15, 'Expected twelve appointments and three lunch blocks');
    Check(Form.TMSMCPCloudAI1.Tools.Count = 4, 'Expected four scheduling tools');
    Handler := Form.PlannerToolExecute;
    for I := 0 to High(ToolNames) do
    begin
      Tool := Form.TMSMCPCloudAI1.Tools[I];
      Check((Tool.Name = ToolNames[I]) and (Tool.Parameters.Count = ParameterCounts[I]),
        'Designer tool name or parameter count changed');
      Check(Tool.Enabled and not Tool.AutoCreated and (Tool.Description <> ''),
        'Expected an enabled designer tool with a description');
      Check((TMethod(Tool.OnExecute).Data = Form) and
        (TMethod(Tool.OnExecute).Code = TMethod(Handler).Code),
        'Designer tool event is not bound to the form handler');
      for J := 0 to Tool.Parameters.Count - 1 do
        Check(Tool.Parameters[J].Required and (Tool.Parameters[J].Description <> ''),
          'Designer parameter lost its required flag or description');
    end;
    Check((Form.TMSMCPCloudAI1.Tools[1].Parameters[0].&Type = ptArray) and
      (Form.TMSMCPCloudAI1.Tools[1].Parameters[0].ArrayType = ptString),
      'Common availability needs an array of resource IDs');
    Tool := Form.TMSMCPCloudAI1.Tools[3];
    Check((Tool.Parameters[0].&Type = ptArray) and
      (Tool.Parameters[0].ArrayType = ptObject) and
      (Tool.Parameters[0].ArrayProperties.Count = 4), 'Batch schema lost its nested object fields');
    Check(Form.TMSMCPChatView1.Messages.Count = 1, 'Welcome message missing');
    Reply := Call('get_schedule', '{}');
    try
      Check(Reply.GetValue<string>('schedule.date') = FormatDateTime('yyyy-mm-dd', Date), 'Wrong demo date');
      Check(Reply.GetValue<TJSONArray>('schedule.appointments').Count = 15, 'Incomplete schedule');
      for I := 0 to Planner.Items.Count - 1 do
        Check(Reply.GetValue<TJSONArray>('schedule.appointments').Items[I].GetValue<Integer>('duration_minutes') =
          MinutesBetween(Planner.Items[I].EndTime, Planner.Items[I].StartTime), 'Wrong appointment duration');
    finally
      Reply.Free;
    end;

    Before := Snapshot;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah"],'
      + '"duration_minutes":90.0,"earliest":"13:00","latest":"18:00"}');
    try
      Check(Reply.GetValue<string>('availability.earliest_slot.start_time') = '16:30',
        'A numeric integer duration should work for an individual');
    finally
      Reply.Free;
    end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],'
      + '"duration_minutes":60,"earliest":"09:00","latest":"18:00"}');
    try
      Check(Reply.GetValue<Boolean>('availability.found'), 'Missed a common hour');
      Check(Reply.GetValue<string>('availability.earliest_slot.start_time') = '17:00', 'Wrong earliest common hour');
      Check(Reply.GetValue<string>('availability.earliest_slot.end_time') = '18:00', 'Wrong common end time');
    finally Reply.Free; end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],'
      + '"duration_minutes":90,"earliest":"09:00","latest":"18:00"}');
    try
      Check(not Reply.GetValue<Boolean>('availability.found'), 'Invented a common 90-minute slot');
      Check(Reply.GetValue<TJSONObject>('availability').GetValue('earliest_slot') is TJSONNull, 'No-match result needs null earliest_slot');
      Check(Reply.GetValue<TJSONArray>('availability.slots').Count = 0, 'No-match result contains slots');
      Check(Reply.GetValue<Integer>('availability.longest_common_free_minutes') = 60, 'Wrong longest common window');
    finally Reply.Free; end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","tom"],'
      + '"duration_minutes":60,"earliest":"09:00","latest":"18:00"}');
    try
      Check(Reply.GetValue<string>('availability.earliest_slot.start_time') = '14:00', 'Subset search included a nonparticipant');
    finally Reply.Free; end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],'
      + '"duration_minutes":15,"earliest":"12:00","latest":"13:00"}');
    try
      Check(not Reply.GetValue<Boolean>('availability.found'), 'Lunch reported as free');
      Check(Reply.GetValue<Integer>('availability.longest_common_free_minutes') = 0, 'Lunch has a common free window');
    finally Reply.Free; end;
    Reply := Call('find_free_slots', '{"resource_ids":[],"duration_minutes":60,"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","unknown"],"duration_minutes":60,"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","sarah"],"duration_minutes":60,"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah"],"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Check(Snapshot = Before, 'Availability query changed the schedule');

    Reply := Call('find_free_slots', '{"resource_ids":["sarah"],"duration_minutes":90,"earliest":"13:00","latest":"18:00"}');
    try
      Check(Reply.GetValue<TJSONArray>('availability.slots').Count = 1, 'Expected one 90-minute afternoon window');
      Check(Reply.GetValue<string>('availability.slots[0].start_time') = '16:30', 'Wrong free slot');
    finally
      Reply.Free;
    end;
    Reply := Call('create_appointment', '{"title":"Workshop <test>","resource_id":"sarah",'
      + '"start_time":"16:30","end_time":"18:00","notes":"Client workshop"}');
    try
      CreatedID := Reply.GetValue<string>('appointment.id');
      Check(Reply.GetValue<Boolean>('appointment.selected'), 'Created appointment not selected');
      Check(Reply.GetValue<string>('appointment.title') = 'Workshop <test>', 'Title escaping changed returned text');
    finally
      Reply.Free;
    end;
    Before := Snapshot;
    Reply := Call('create_appointment', '{"title":"Overlap","resource_id":"sarah",'
      + '"start_time":"17:00","end_time":"18:00","notes":""}', False); Reply.Free;
    Check(Snapshot = Before, 'Rejected booking changed the schedule');
    Check(CreatedID <> '', 'New appointment ID missing');
    Form.ResetClick(nil);

    Before := Snapshot;
    Reply := Call('create_appointment', '{"title":"Lunch conflict","resource_id":"tom",'
      + '"start_time":"12:00","end_time":"13:00","notes":""}', False); Reply.Free;
    Reply := Call('create_appointment', '{"title":"Late","resource_id":"tom",'
      + '"start_time":"18:00","end_time":"19:00","notes":""}', False); Reply.Free;
    Reply := Call('create_appointment', '{"title":"Bad time","resource_id":"tom",'
      + '"start_time":"25:00","end_time":"26:00","notes":""}', False); Reply.Free;
    Reply := Call('create_appointment', '{"title":"Off grid","resource_id":"tom",'
      + '"start_time":"10:31","end_time":"11:00","notes":""}', False); Reply.Free;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],"duration_minutes":30.5,"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],"duration_minutes":-15,"earliest":"09:00","latest":"18:00"}', False); Reply.Free;
    Check(Snapshot = Before, 'Invalid arguments mutated the schedule');

    Debugging := ByTitle('Debugging');
    Review := ByTitle('Code review');
    Deployment := ByTitle('Deployment');
    OriginalID := Debugging.DBKey;
    Reply := Call('reschedule_appointments', '{"changes":['
      + MoveJSON(Debugging, 'alex', '13:00', '15:30') + ','
      + MoveJSON(Review, 'alex', '15:30', '16:30') + ','
      + MoveJSON(Deployment, 'alex', '16:30', '17:30') + ']}');
    try
      Check(Reply.GetValue<TJSONArray>('appointments').Count = 3, 'Incomplete batch result');
      Check(Reply.GetValue<Boolean>('appointments[0].selected'), 'Batch result selection differs from Planner');
      Check(FormatDateTime('hh:nn', Debugging.EndTime) = '15:30', 'Overrun not applied');
      Check(FormatDateTime('hh:nn', Review.StartTime) = '15:30', 'Review not moved');
      Check(MinutesBetween(Deployment.EndTime, Deployment.StartTime) = 60, 'Deployment duration changed');
      Check(Debugging.DBKey = OriginalID, 'Rescheduling changed stable ID');
    finally
      Reply.Free;
    end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],'
      + '"duration_minutes":60,"earliest":"09:00","latest":"18:00"}');
    try
      Check(not Reply.GetValue<Boolean>('availability.found'), 'Replanned day still claims a shared hour');
      Check(Reply.GetValue<TJSONObject>('availability').GetValue('earliest_slot') is TJSONNull, 'No-match result needs null earliest_slot');
      Check(Reply.GetValue<Integer>('availability.longest_common_free_minutes') = 30, 'Live replan was not reflected in shared search');
    finally Reply.Free; end;
    Reply := Call('find_free_slots', '{"resource_ids":["sarah","alex","tom"],'
      + '"duration_minutes":30,"earliest":"09:00","latest":"18:00"}');
    try
      Check(Reply.GetValue<string>('availability.earliest_slot.start_time') = '17:30', 'Common half hour should start at 17:30');
      Check(Reply.GetValue<string>('availability.earliest_slot.end_time') = '18:00', 'Common half hour should finish at 18:00');
    finally Reply.Free; end;
    Before := Snapshot;
    Reply := Call('reschedule_appointments', '{"changes":['
      + MoveJSON(Debugging, 'alex', '13:00', '16:00') + ','
      + MoveJSON(Review, 'alex', '16:00', '17:00') + ']}', False); Reply.Free;
    Check(Snapshot = Before, 'Conflicting batch was partially applied');
    Reply := Call('reschedule_appointments', '{"changes":['
      + MoveJSON(Debugging, 'alex', '13:00', '15:30') + ','
      + MoveJSON(Debugging, 'alex', '13:00', '15:30') + ']}', False); Reply.Free;
    Check(Snapshot = Before, 'Duplicate changes mutated the schedule');

    // A swap must validate the final schedule rather than reject intermediate overlap.
    Reply := Call('reschedule_appointments', '{"changes":['
      + MoveJSON(ByTitle('Project briefing'), 'sarah', '13:00', '14:00') + ','
      + MoveJSON(ByTitle('Client workshop'), 'sarah', '09:00', '10:00') + ']}'); Reply.Free;
    Check(FormatDateTime('hh:nn', ByTitle('Project briefing').StartTime) = '13:00', 'Atomic swap failed');

    Lunch := ByTitle('Lunch', 0);
    Reply := Call('reschedule_appointments', '{"changes":[' + MoveJSON(Lunch, 'sarah', '11:30', '12:30') + ']}', False); Reply.Free;
    Reply := Call('reschedule_appointments', '{"changes":[{"appointment_id":"unknown","resource_id":"sarah","start_time":"09:00","end_time":"10:00"}]}', False); Reply.Free;

    // Exercise the same guard and refresh handlers as a manual drag.
    Item := ByTitle('Test planning');
    StartTime := ToolSet.Day + EncodeTime(14, 0, 0, 0);
    EndTime := ToolSet.Day + EncodeTime(15, 0, 0, 0);
    Position := 2;
    Allowed := True;
    Form.PlannerBeforeChange(Planner, Item, StartTime, EndTime, Position, Allowed);
    Check(Allowed, 'Valid manual move rejected');
    Item.StartTime := StartTime;
    Item.EndTime := EndTime;
    Form.PlannerAfterChange(Planner, Item, StartTime, EndTime, Position);
    Reason := '';
    Form.PlannerGetItemText(Planner, Item, pgtmDrawing, Reason);
    Check(Reason = '14:00 - 15:00', 'Manual move display was stale');
    Check(Pos('14:00', Snapshot) > 0, 'Live read missed manual move');
    Check(not ToolSet.CanPlace(Item, StartTime + EncodeTime(0, 30, 0, 0),
      EndTime + EncodeTime(0, 30, 0, 0), 2, Reason), 'Manual overlap accepted');
    Check(not ToolSet.CanPlace(Item, StartTime + 1, EndTime + 1, 2, Reason), 'Manual move to another day accepted');
    Planner.ClearSelection;
    Planner.SelectItem(Item);
    Check(Pos('"selected":true', Snapshot) > 0, 'Live read missed manual selection');

    Resource := Planner.Resources[0];
    Resource.Hint := 'Designer customization';
    Form.ResetClick(nil);
    Check(Form.TMSMCPCloudAI1.Tools.Count = 4, 'Reset duplicated the designer tools');
    Check((Planner.Resources[0] = Resource) and (Resource.Hint = 'Designer customization'),
      'Reset replaced designer resources');
    Check(ByTitle('Debugging').DBKey <> OriginalID, 'Reset reused stale appointment ID');
    Check(Planner.Items.Count = 15, 'Reset did not restore sample appointments');
    Check(not Form.ToolActivityMemo.Visible, 'Tool log should start collapsed');
    Form.ToolActivityToggle.IsChecked := True;
    Check(Form.ToolActivityMemo.Visible and (Form.ToolActivityLayout.Height = 170), 'Tool log did not expand');
    Form.ToolActivityToggle.IsChecked := False;
    Check(not Form.ToolActivityMemo.Visible and (Form.ToolActivityLayout.Height = 34), 'Tool log did not collapse');

    // Exercise real option dispatch and SendDraft, replacing only the external AI
    // with a local send recorder so these checks make no model requests.
    Welcome := Form.TMSMCPChatView1.Messages[0];
    Check((Welcome.Options.Count = 6) and not Welcome.SingleUse,
      'Welcome must provide reusable example options');
    Check(Welcome.InteractionMode = cvimSingleChoice, 'Welcome should mark the latest selection');
    Check(Form.FindComponent('ExamplePrompts') = nil, 'Old prompt combobox remains');
    Recorder := TPromptRecorder.Create;
    Recorder.Prompts := TStringList.Create;
    Recorder.Accept := True;
    Form.TMSMCPChatView1.CloudAI := nil;
    Form.TMSMCPChatView1.OnSend := Recorder.CaptureSend;
    try
      Form.TMSMCPChatView1.Draft := 'My unfinished request';
      Check(Form.TMSMCPChatView1.ActivateMessageOption(Welcome.MessageID, 'replan'), 'Example click rejected');
      Check((Recorder.Prompts.Count = 1) and (Recorder.Prompts[0] = Welcome.Options[0].Value),
        'One click did not send the full example');
      Check(Trim(Form.TMSMCPChatView1.Draft) = 'My unfinished request', 'Example discarded an existing draft');
      Check((Welcome.InteractionState = cvisReady) and Welcome.Options[0].Selected,
        'Welcome option was locked after sending');
      Check(Form.TMSMCPChatView1.ActivateMessageOption(Welcome.MessageID, 'replan'), 'Same option cannot be retriggered');
      Check((Recorder.Prompts.Count = 2) and (Recorder.Prompts[1] = Recorder.Prompts[0]),
        'Repeated option did not resend its prompt');
      Check(Form.TMSMCPChatView1.ActivateMessageOption(Welcome.MessageID, 'workshop'), 'Another option cannot be selected');
      Check((Recorder.Prompts.Count = 3) and (Recorder.Prompts[2] = Welcome.Options[1].Value),
        'Different option sent the wrong prompt');
      Check(Welcome.Options[1].Selected and not Welcome.Options[0].Selected,
        'Latest selection was not updated');
      Recorder.Accept := False;
      Form.TMSMCPChatView1.ActivateMessageOption(Welcome.MessageID, 'availability');
      Check((Welcome.InteractionState = cvisReady) and not Welcome.Options[3].Selected,
        'Rejected send left the welcome interaction locked or selected');
      Recorder.Accept := True;
      Check(Form.TMSMCPChatView1.ActivateMessageOption(Welcome.MessageID, 'availability'),
        'Cannot retry a rejected example');
      Activation := Default(TTMSMCPChatViewInteractionActivation);
      Activation.MessageID := 'model-question';
      Allowed := True;
      Form.ChatMessageInteraction(Form.TMSMCPChatView1, Activation, Allowed);
      Check(Allowed, 'Welcome handler intercepted a model-generated question');
    finally
      Form.TMSMCPChatView1.OnSend := nil;
      Form.TMSMCPChatView1.CloudAI := Form.TMSMCPCloudAI1;
      Recorder.Prompts.Free;
      Recorder.Free;
    end;
    Form.ResetClick(nil);
    Check((Form.TMSMCPChatView1.Messages.Count = 1) and
      (Form.TMSMCPChatView1.Messages[0].Options.Count = 6), 'Reset did not restore the welcome options');
    if FindCmdLineSwitch('render') then
    begin
      Bitmap := TBitmap.Create(Form.ClientWidth, Form.ClientHeight);
      try
        if Bitmap.Canvas.BeginScene then
        try Form.PaintTo(Bitmap.Canvas); finally Bitmap.Canvas.EndScene; end;
        Bitmap.SaveToFile(TPath.Combine(ExtractFilePath(ParamStr(0)), 'PlannerPreview.png'));
      finally
        Bitmap.Free;
      end;
    end;
  finally
    Form.Free;
  end;
end;

procedure RunOpenAI;
type
  TBaseline = record
    ID: string;
    Resource: Integer;
    StartTime, EndTime: TDateTime;
  end;
var
  Recorder: TOpenAIRecorder;
  Baseline: TArray<TBaseline>;
  CaseIndex, I, J: Integer;
  Item, Other: TTMSFNCPlannerItem;
  Started: UInt64;
  DebuggingID: string;
begin
  Form := TForm3.Create(nil);
  Recorder := TOpenAIRecorder.Create;
  Recorder.Tools := TStringList.Create;
  try
    Planner := Form.Planner1;
    ToolSet := Form.FindComponent('PlannerTools') as TPlannerTools;
    if Form.TMSMCPCloudAI1.APIKeys.OpenAI = '' then
      raise Exception.Create('OpenAI live check requires the configured shared OpenAI API key');
    Form.TMSMCPCloudAI1.Request.ConnectTimeout := 15000;
    Form.TMSMCPCloudAI1.Request.ReadTimeout := 60000;
    Form.TMSMCPChatView1.OnError := Recorder.CaptureError;
    ToolSet.OnToolLog := Recorder.CaptureTool;
    Writeln('OpenAI live model: ', Form.TMSMCPCloudAI1.Settings.OpenAIModel);
    for CaseIndex := 0 to 1 do
    begin
      Form.ResetClick(nil);
      Recorder.Failed := False;
      Recorder.Tools.Clear;
      DebuggingID := ByTitle('Debugging').DBKey;
      SetLength(Baseline, Planner.Items.Count);
      for I := 0 to Planner.Items.Count - 1 do
      begin
        Baseline[I].ID := Planner.Items[I].DBKey;
        Baseline[I].Resource := Planner.Items[I].Resource;
        Baseline[I].StartTime := Planner.Items[I].StartTime;
        Baseline[I].EndTime := Planner.Items[I].EndTime;
      end;
      if CaseIndex = 0 then
      begin
        Writeln('Checking the original natural-language rearrangement request...');
        Form.TMSMCPChatView1.Draft := 'Alex needs another hour for debugging. '
          + 'Rearrange his afternoon, keeping the other durations.';
        Form.TMSMCPChatView1.SendDraft;
      end
      else
      begin
        Writeln('Checking the updated welcome option...');
        Form.TMSMCPChatView1.ActivateMessageOption('planner-welcome', 'replan');
      end;
      Started := TThread.GetTickCount64;
      repeat
        Application.ProcessMessages;
        CheckSynchronize(10);
        if Recorder.Failed then
          raise Exception.Create('OpenAI request failed; check the configured model and API access');
        for I := 2 to Form.TMSMCPChatView1.Messages.Count - 1 do
          if Form.TMSMCPChatView1.Messages[I].Options.Count > 0 then
            raise Exception.Create('Model asked a follow-up instead of carrying out the authorized rearrangement');
        if not Form.TMSMCPCloudAI1.Busy and (Form.TMSMCPChatView1.Messages.Count >= 3) then
          Break;
        if TThread.GetTickCount64 - Started > 90000 then
          raise Exception.Create('OpenAI live check timed out');
        TThread.Sleep(10);
      until False;
      Check(Recorder.Tools.IndexOf('get_schedule') >= 0, 'Model did not read the live schedule');
      Check(Recorder.Tools.IndexOf('reschedule_appointments') >= 0, 'Model did not apply the rearrangement');
      Check(Planner.Items.Count = Length(Baseline), 'Model removed or created work while replanning');
      for I := 0 to High(Baseline) do
      begin
        Item := nil;
        for J := 0 to Planner.Items.Count - 1 do
          if Planner.Items[J].DBKey = Baseline[I].ID then
            Item := Planner.Items[J];
        Check(Assigned(Item), 'Model replaced an existing appointment');
        Check(Item.Resource = Baseline[I].Resource, 'Model changed an assignee');
        if Item.DBKey = DebuggingID then
        begin
          Check(SecondsBetween(Item.StartTime, Baseline[I].StartTime) = 0, 'Debugging start changed');
          Check(MinutesBetween(Item.EndTime, Baseline[I].EndTime) = 60, 'Debugging was not extended by one hour');
        end
        else
        begin
          Check(MinutesBetween(Item.EndTime, Item.StartTime) =
            MinutesBetween(Baseline[I].EndTime, Baseline[I].StartTime), 'Another appointment duration changed');
          if (Item.Resource <> 1) or (Frac(Baseline[I].StartTime) < EncodeTime(13, 0, 0, 0)) then
            Check(SecondsBetween(Item.StartTime, Baseline[I].StartTime) = 0, 'Model moved work outside Alex''s afternoon');
        end;
        for J := Item.Index + 1 to Planner.Items.Count - 1 do
        begin
          Other := Planner.Items[J];
          Check((Item.Resource <> Other.Resource) or (Item.StartTime >= Other.EndTime)
            or (Item.EndTime <= Other.StartTime), 'Live rearrangement contains an overlap');
        end;
      end;
      Writeln('PASS OpenAI: debugging ', FormatDateTime('hh:nn', ByTitle('Debugging').StartTime),
        '-', FormatDateTime('hh:nn', ByTitle('Debugging').EndTime), '; code review ',
        FormatDateTime('hh:nn', ByTitle('Code review').StartTime), '-',
        FormatDateTime('hh:nn', ByTitle('Code review').EndTime), '; deployment ',
        FormatDateTime('hh:nn', ByTitle('Deployment').StartTime), '-',
        FormatDateTime('hh:nn', ByTitle('Deployment').EndTime));
    end;
  finally
    Form.TMSMCPCloudAI1.CancelRequests;
    Form.Free;
    Recorder.Tools.Free;
    Recorder.Free;
  end;
end;

procedure RunOpenAICommon;
var
  Recorder: TOpenAIRecorder;
  CaseIndex, I: Integer;
  Started: UInt64;
  Before, ResponseText: string;
  Reply: TJSONObject;
begin
  Form := TForm3.Create(nil);
  Recorder := TOpenAIRecorder.Create;
  Recorder.Tools := TStringList.Create;
  try
    Planner := Form.Planner1;
    ToolSet := Form.FindComponent('PlannerTools') as TPlannerTools;
    if Form.TMSMCPCloudAI1.APIKeys.OpenAI = '' then
      raise Exception.Create('OpenAI live check requires the configured shared OpenAI API key');
    Form.TMSMCPCloudAI1.Request.ConnectTimeout := 15000;
    Form.TMSMCPCloudAI1.Request.ReadTimeout := 60000;
    Form.TMSMCPChatView1.OnError := Recorder.CaptureError;
    ToolSet.OnToolLog := Recorder.CaptureTool;
    for CaseIndex := 0 to 1 do
    begin
      Form.ResetClick(nil);
      if CaseIndex = 1 then
      begin
        // Reproduce the day after Alex's overrun: only a shared half hour remains.
        Reply := Call('reschedule_appointments', '{"changes":['
          + MoveJSON(ByTitle('Debugging'), 'alex', '13:00', '15:30') + ','
          + MoveJSON(ByTitle('Code review'), 'alex', '15:30', '16:30') + ','
          + MoveJSON(ByTitle('Deployment'), 'alex', '16:30', '17:30') + ']}');
        Reply.Free;
      end;
      Before := Snapshot;
      Recorder.Failed := False;
      Recorder.Tools.Clear;
      Recorder.LastCommonResult := '';
      Writeln('Checking OpenAI shared availability; matching hour expected: ', CaseIndex = 0);
      Form.TMSMCPChatView1.Draft := 'Return the first available 60-minute timeslot '
        + 'today for a meeting with Sarah, Alex and Tom together. '
        + 'Keep all existing appointments unchanged and do not book anything.';
      Form.TMSMCPChatView1.SendDraft;
      Started := TThread.GetTickCount64;
      repeat
        Application.ProcessMessages;
        CheckSynchronize(10);
        if Recorder.Failed then
          raise Exception.Create('OpenAI shared-availability request failed');
        for I := 2 to Form.TMSMCPChatView1.Messages.Count - 1 do
          if Form.TMSMCPChatView1.Messages[I].Options.Count > 0 then
            raise Exception.Create('Model asked an unexpected question for a fully specified availability request');
        if not Form.TMSMCPCloudAI1.Busy and (Form.TMSMCPChatView1.Messages.Count >= 3) then
          Break;
        if TThread.GetTickCount64 - Started > 90000 then
          raise Exception.Create('OpenAI shared-availability check timed out');
        TThread.Sleep(10);
      until False;
      Check(Recorder.LastCommonResult <> '', 'Model did not use the common-availability tool');
      Check(Recorder.Tools.IndexOf('reschedule_appointments') < 0, 'Model rearranged work to answer availability');
      Check(Snapshot = Before, 'Model changed the schedule during an availability query');
      Reply := TJSONObject.ParseJSONValue(Recorder.LastCommonResult) as TJSONObject;
      try
        Check(Reply.GetValue<Boolean>('ok'), 'Common-availability tool failed');
        Check(Reply.GetValue<Boolean>('availability.found') = (CaseIndex = 0), 'Unexpected shared-availability result');
        ResponseText := Form.TMSMCPChatView1.Messages[Form.TMSMCPChatView1.Messages.Count - 1].Text;
        if CaseIndex = 0 then
        begin
          Check(Reply.GetValue<string>('availability.earliest_slot.start_time') = '17:00', 'Wrong shared hour');
          Check(Pos('17:00', ResponseText) > 0, 'Model did not report the returned common slot');
        end
        else
        begin
          Check(Reply.GetValue<TJSONObject>('availability').GetValue('earliest_slot') is TJSONNull, 'No-match result contains an earliest slot');
          Check(Reply.GetValue<Integer>('availability.longest_common_free_minutes') = 30, 'No-match diagnostic is wrong');
          Check((Pos('no ', LowerCase(ResponseText)) > 0) or
            (Pos('not ', LowerCase(ResponseText)) > 0) or (Pos('none', LowerCase(ResponseText)) > 0),
            'Model did not acknowledge the no-availability result');
        end;
        Writeln('PASS OpenAI: ', Copy(StringReplace(ResponseText, sLineBreak, ' ', [rfReplaceAll]), 1, 1000));
      finally
        Reply.Free;
      end;
    end;
  finally
    Form.TMSMCPCloudAI1.CancelRequests;
    Form.Free;
    Recorder.Tools.Free;
    Recorder.Free;
  end;
end;

begin
  try
    Run;
    Writeln('PASS: ', Checks, ' checks; no model requests made.');
    if FindCmdLineSwitch('openai') then
      RunOpenAI;
    if FindCmdLineSwitch('openai-common') then
      RunOpenAICommon;
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
