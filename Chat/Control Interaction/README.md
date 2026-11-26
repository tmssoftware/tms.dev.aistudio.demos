# Planner control interaction

An FMX demo that lets an AI model read and change a Delphi Planner through
CloudAI tools: find free time, book appointments, and rearrange a schedule.

## Requirements

- TMS AI Studio
- **TMS FNC UI Pack** for `TTMSFNCPlanner`
- TMS FNC Core
- An AI service and model with tool calling support

## Run

Open `Demo.dproj`, adjust the FNC search paths for your installation, then build
and run. Select a service and enter an API key if one was not loaded automatically.

Click an example in the welcome message, or type a request such as:

> Give Alex another hour for debugging and rearrange his afternoon.

You can also drag or resize appointments yourself. **Show tool activity** displays
the calls and results. **Reset demo** restores the sample schedule.

The demo covers one day, 09:00-18:00, with lunch reserved from 12:00-13:00.
Shared availability checks all participants together. Changes stay in memory;
no external calendars are updated.

## Code and tests

The Planner and four tool definitions are in `Umain.fmx`. Edit tools through
`TMSMCPCloudAI1.Tools` in the Object Inspector. `UPlannerTools.pas` handles reading,
availability, booking and batch rescheduling. Availability checks all listed
resource IDs together; pass one ID for an individual.

Build and run `Tests\PlannerToolsTests.dpr` for local checks. Add `-render` for a form preview.
The optional `-openai` and `-openai-common` checks make paid OpenAI requests.
