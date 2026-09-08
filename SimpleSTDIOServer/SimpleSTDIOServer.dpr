program SimpleSTDIOServer;

{$APPTYPE CONSOLE}

(*
  ============================================================
  Simple MCP STDIO Server Example
  ============================================================

  This example shows two ways to register tools on an MCP server
  that communicates over standard input/output (stdio).

  WHAT IS AN MCP SERVER?
  ----------------------
  An MCP (Model Context Protocol) server exposes "tools" that an
  AI assistant (e.g. Claude) can call during a conversation.

  The AI sees each tool's name and description, decides when to
  call it, supplies the required arguments, and the server runs
  your Delphi code and returns the result.

  HOW THE TRANSPORT WORKS (stdio)
  --------------------------------
  1. An MCP client (Claude Desktop, Claude Code, etc.) launches
     this executable as a subprocess.
  2. The client sends JSON-RPC requests over stdin.
  3. The server dispatches each request to the matching tool and
     writes the JSON result back to stdout.
  4. The server exits when stdin is closed (client disconnects).
  5. Anything written to stderr is debug/diagnostic output that
     does NOT affect the JSON-RPC stream.

  THE TWO REGISTRATION STYLES
  ----------------------------
  Both styles produce identical results — choose whichever reads
  more clearly for your use case.

  STYLE 1 — Manual / explicit  (see "greet" and "add" below)
    Create a TTMSMCPTool, set properties one by one, then call
    Server.Tools.Add(Tool).
    Best when you need full control or want to store the tool
    reference for later (e.g. to attach an OnGenerateInputSchema).

  STYLE 2 — Fluent builder  (see "word_count" and "current_time")
    Chain TTMSMCPTool.CreateBuilder calls and finish with .Build.
    Best for concise, read-at-a-glance registrations.

  TOOLS IN THIS SAMPLE
  --------------------
    greet        - Returns a personalised greeting.     (Style 1)
    add          - Adds two integers together.           (Style 1)
    word_count   - Counts words in a piece of text.     (Style 2)
    current_time - Returns the current date/time.       (Style 2)
*)

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  TMS.MCP.Server,
  TMS.MCP.Tools,
  TMS.MCP.Helpers,         // TTMSMCPMethod, TTMSMCPBase, etc.
  TMS.MCP.Transport.STDIO; // stdio transport (reads stdin, writes stdout)

// ---------------------------------------------------------------------------
// Tool callback functions
//
// Every tool callback has this signature:
//   function(const Args: array of TValue): TValue
//
// Args[] are positional — index 0 is the FIRST parameter you registered,
// index 1 is the second, and so on.
//
// TValue is Delphi's generic value container:
//   read  : Args[0].AsString, Args[0].AsInteger, Args[0].AsBoolean ...
//   write : TValue.From<string>('hello'), TValue.From<Integer>(42) ...
// ---------------------------------------------------------------------------

// "greet" — registered with Style 1
// Parameters: name (string, required), formal (boolean, optional)
function HandleGreet(const Args: array of TValue): TValue;
var
  Name: string;
  Formal: Boolean;
begin
  Name   := Args[0].AsString;

  // Args[1] is optional — only read it when it was actually supplied.
  // The server passes exactly as many args as the caller provided.
  Formal := (Length(Args) > 1) and Args[1].AsBoolean;

  if Formal then
    Result := TValue.From<string>('Good day, ' + Name + '. How may I assist you?')
  else
    Result := TValue.From<string>('Hey ' + Name + '! Nice to meet you!');
end;

// "add" — registered with Style 1
// Parameters: a (integer, required), b (integer, required)
function HandleAdd(const Args: array of TValue): TValue;
begin
  Result := TValue.From<Integer>(Args[0].AsInteger + Args[1].AsInteger);
end;

// "word_count" — registered with Style 2 (builder)
// Parameters: text (string, required)
function HandleWordCount(const Args: array of TValue): TValue;
var
  Words: TStringDynArray;
begin
  Words  := Args[0].AsString.Split([' ', #9, #10, #13], TStringSplitOptions.ExcludeEmpty);
  Result := TValue.From<Integer>(Length(Words));
end;

// "current_time" — registered with Style 2 (builder)
// No parameters needed.
function HandleCurrentTime(const Args: array of TValue): TValue;
begin
  Result := TValue.From<string>(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
end;

// ---------------------------------------------------------------------------
// Main program
// ---------------------------------------------------------------------------
var
  Server: TTMSMCPServer;

  // Style 1 helper variables
  Tool: TTMSMCPTool;
  Prop: TTMSMCPToolProperty;

begin
  try
    // Always force '.' as the decimal separator so floating-point values
    // serialise correctly inside JSON (e.g. 3.14, not 3,14).
    FormatSettings.DecimalSeparator := '.';

    // ----------------------------------------------------------------
    // Create the server
    // ----------------------------------------------------------------
    Server := TTMSMCPServer.Create(nil);
    Server.ServerName    := 'SimpleSTDIOServer';
    Server.ServerVersion := '1.0.0';
    // No transport assignment needed: Start() creates a stdio transport
    // automatically when none is set.

    // ================================================================
    // STYLE 1 — Manual / explicit registration
    // ================================================================
    // Step 1: create a bare tool object.
    // Step 2: set its name, description, return type, and callback.
    // Step 3: add each parameter by calling Tool.Properties.Add,
    //         then set that property's fields.
    // Step 4: hand the finished tool to the server.
    //
    // TTMSMCPToolProperty fields:
    //   Name         — the JSON key the AI must supply
    //   Description  — shown to the AI so it knows what to pass
    //   PropertyType — ptString | ptInteger | ptFloat | ptBoolean | ptJSON
    //   Required     — True  = AI MUST provide this argument
    //                  False = optional; check Length(Args) before reading
    // ================================================================

    // --- Tool: greet ---
    Tool             := TTMSMCPTool.Create;
    Tool.Name        := 'greet';
    Tool.Description := 'Returns a personalised greeting. ' +
                        'Set formal=true for a polite tone, false (default) for casual.';
    Tool.ReturnType  := ptString;
    Tool.Method      := HandleGreet; // assign the callback

    // First parameter: name
    Prop             := Tool.Properties.Add;
    Prop.Name        := 'name';
    Prop.Description := 'The name of the person to greet';
    Prop.PropertyType := ptString;
    Prop.Required    := True;

    // Second parameter: formal (optional — callback checks Length(Args))
    Prop             := Tool.Properties.Add;
    Prop.Name        := 'formal';
    Prop.Description := 'Use a formal greeting (true) or casual (false)';
    Prop.PropertyType := ptBoolean;
    Prop.Required    := False;

    Server.Tools.Add(Tool); // register with the server

    // --- Tool: add ---
    Tool             := TTMSMCPTool.Create;
    Tool.Name        := 'add';
    Tool.Description := 'Adds two integers and returns their sum.';
    Tool.ReturnType  := ptInteger;
    Tool.Method      := HandleAdd;

    Prop             := Tool.Properties.Add;
    Prop.Name        := 'a';
    Prop.Description := 'First integer';
    Prop.PropertyType := ptInteger;
    Prop.Required    := True;

    Prop             := Tool.Properties.Add;
    Prop.Name        := 'b';
    Prop.Description := 'Second integer';
    Prop.PropertyType := ptInteger;
    Prop.Required    := True;

    Server.Tools.Add(Tool);

    // ================================================================
    // STYLE 2 — Fluent builder registration
    // ================================================================
    // Start with TTMSMCPTool.CreateBuilder, chain every setting, and
    // finish with .Build which returns a ready TTMSMCPTool.
    //
    // .AddProperty opens a parameter sub-builder; call .&End to close
    // it and return to the tool builder.
    //
    // The result of .Build is passed directly to Server.Tools.Add.
    // ================================================================

    // --- Tool: word_count ---
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
          .&End        // close the parameter, return to the tool builder
        .Build         // finalise and return the TTMSMCPTool
    );

    // --- Tool: current_time (no parameters) ---
    // When a tool needs no parameters simply skip .AddProperty entirely.
    Server.Tools.Add(
      TTMSMCPTool.CreateBuilder
        .Name('current_time')
        .Description('Returns the current server date and time ' +
                     'formatted as YYYY-MM-DD HH:MM:SS.')
        .ExecuteCallback(HandleCurrentTime)
        .ReturnType(ptString)
        .Build
    );

    // ----------------------------------------------------------------
    // Start and run the server
    //
    // Start() — initialises the transport (creates a stdio transport
    //           automatically if none was assigned).
    // Run()   — enters the JSON-RPC read loop; blocks until stdin is
    //           closed by the MCP client.
    // ----------------------------------------------------------------
    Server.Start;
    Server.Run;

  except
    on E: Exception do
    begin
      // Write to stderr so the error message does NOT corrupt the
      // JSON-RPC stream on stdout that the MCP client is reading.
      WriteLn(ErrOutput, 'Fatal: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
