object DM: TDM
  Height = 227
  Width = 326
  PixelsPerInch = 144
  object MCPClient: TTMSMCPClient
    Settings.GeminiModel = 'gemini-1.5-flash-latest'
    Settings.OpenAIModel = 'gpt-4o'
    Settings.OpenAISoundModel = 'gpt-4o-mini-tts'
    Settings.OpenAITranscribeModel = 'whisper-1'
    Settings.GrokModel = 'grok-beta'
    Settings.ClaudeModel = 'claude-3-5-sonnet-20241022'
    Settings.OllamaModel = 'llama3.2:latest'
    Settings.DeepSeekModel = 'deepseek-chat'
    Settings.PerplexityModel = 'llama-3.1-sonar-small-128k-online'
    Settings.OllamaHost = 'localhost'
    Settings.OllamaPath = '/api/chat'
    Settings.LlamaCppHost = 'localhost'
    Settings.LlamaCppPath = '/v1/chat/completions'
    Settings.MistralModel = 'mistral-large-latest'
    Settings.MistralTranscribeModel = 'voxtral-mini-2507'
    Service = aiOpenAI
    Servers = <>
    ToolCallMode = tcmAllow
    Tools = <>
    Left = 48
    Top = 24
  end
  object SettingsDialog: TTMSMCPClientSettingsDialog
    Client = MCPClient
    OnAPIKeysChanged = SettingsDialogAPIKeysChanged
    OnServersChanged = SettingsDialogServersChanged
    Left = 160
    Top = 88
  end
end
