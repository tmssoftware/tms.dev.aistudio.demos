# Weather API

A minimal MCP server exposing a single `get_weather` tool, built with `TMS.MCP.Server`. Two variants of the same tool are included, one per transport: STDIO (`WeatherApiSTDIODemo`) and SSE (`WeatherApiSSEDemo`). Start here if you're new to the TMS MCP SDK.

## Overview

The server exposes a weather tool to retrieve current weather information for specified cities. It uses the OpenStreetMap API to geocode city names into coordinates and the Open-Meteo API to fetch current weather data.

## Requirements

- Delphi 11.1 or later
- TMS AI Studio

## Building the STDIO Server

1. Open the `WeatherApiSTDIODemo.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder, depending on your configuration.

## Building the SSE Server

1. Open the `WeatherApiSSEDemo.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `Win32\Debug` or `Win32\Release` folder, depending on your configuration.

## Setting Up a Client with STDIO

You can use any MCP client that supports STDIO transport to connect to this server. Here are two common options:

### Option 1: Using Claude for Desktop

1. Install [Claude for Desktop](https://claude.ai/download).
2. Edit or create the Claude Desktop configuration file located at:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
3. Add the Weather API (STDIO) Demo server to the `mcpServers` section:

```json
{
  "mcpServers": {
    "weather": {
      "command": "PATH_TO_EXE\\WeatherApiDemo.exe",
      "args": []
    }
  }
}
```

Replace `PATH_TO_EXE` with the absolute path to your compiled executable.

4. Restart Claude for Desktop.
5. Ask Claude about the weather in a city, e.g., "What's the current weather in Paris?"

### Option 2: Using MCP Inspector

1. Install the MCP Inspector tool:
   ```bash
   npm install -g @modelcontextprotocol/inspector
   ```

2. Run the Inspector with your server:
   ```bash
   npx @modelcontextprotocol/inspector PATH_TO_EXE\WeatherApiSTDIODemo.exe
   ```

3. Use the Inspector UI to test the `get_weather` tool functionality.

## Setting Up a Client with SSE

The steps are almost identical as above. You'll need an SSE capable client and instead of the path to the executable you'll need to use the URL of your server (for example: `http://localhost:8934/sse`).
