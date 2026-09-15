# TTMSMCPClient demo

This README explains how to set up and use the `ClientDemo` with servers using STDIO transport.

## Overview

The ClientDemo is a simple Model Context Protocol (MCP) host implementation that is capable of connecting to MCP servers utilizing the STDIO transport, and supports function calling with 9 LLM services: OpenAI, Claude, Gemini, Grok, Mistral, DeepSeek OpenRouter, Ollama and llama.cpp

## Requirements

- Delphi 11.1 or later
- TMS AI Studio
- TMS FNC UI Pack (TTMSFNCChat)

## Building the Demo

1. Open the `ClientDemo.dproj` project in your Delphi IDE.
2. Build the project (Shift+F9 or Run → Build).
3. The compiled executable will be available in the `bin` folder.
4. When running the demo application, configure the API keys and servers via the `Settings` button.

## Setting Up a Server

You can use any MCP server that supports STDIO transport to connect with this client. Click the `Modify` button to modify the command/args/environment variables for each server. Once finished, click the `Ok` button, then `Start` the server if it was not running before modification.

### TTMSMCPServer based servers

- `Command`: The path to the executable
- `Args`: Any arguments the server expects

### 3rd party servers

Follow the server config for each 3rd party server, it should correspond with `Commands`/`Args`/`EnvironmentVariables`. 

**For example**: https://mcp.so/server/playwright-mcp/microsoft

- `Command`: npx
- `Args`: @playwright/mcp@latest
