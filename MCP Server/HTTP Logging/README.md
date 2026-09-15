# HTTP Logging

An MCP server, built with `TMS.MCP.Server` over the Streamable HTTP transport, that logs every request it handles to a local SQLite database. Useful as a starting point for auditing, analytics, or debugging MCP traffic.

## Overview

Every call is recorded in a `mcp_logs` table (method, params, response, success, execution time, request/response size). The server exposes tools to query that log data (`get-daily-logs`, `get-logs-by-method`, `get-log-stats`), plus two tools purely to generate sample traffic (`simulate-work`, `test-tool`).

## Requirements

- Delphi 11.1 or later
- TMS AI Studio
- FireDAC with the SQLite driver

## Building

1. Open `StreamableLoggerDemo.dproj` in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in `Win32\Debug` or `Win32\Release`.

## Running

```
StreamableLoggerDemo [options]
```

**Options:**

- `-p, --port <port>`      HTTP port (default: 8080)
- `-d, --database <path>`  SQLite database file (default: `server_logs.db`)
- `-s, --sample`           Populate the database with 1000 sample log entries on startup
- `-h, --help`             Show help

The server listens at `http://localhost:<port>/mcp`.

## Setting up a client

Any MCP client that supports Streamable HTTP transport can connect directly to `http://localhost:<port>/mcp`.

### Using MCP Inspector

```bash
npx @modelcontextprotocol/inspector
```

Then connect it to `http://localhost:8080/mcp` (Streamable HTTP transport) and call `get-daily-logs`, `get-log-stats`, or `simulate-work` to see logging in action.

## Available tools

- `get-daily-logs` — logs for a given date (default: today)
- `get-logs-by-method` — call counts and timing statistics grouped by method
- `get-log-stats` — overall statistics across all logged requests
- `simulate-work` — generates a log entry after sleeping for a configurable duration
- `test-tool` — generates a log entry that can be made to succeed or fail on demand
