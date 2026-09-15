object Form5: TForm5
  Left = 0
  Top = 0
  Caption = 'Show list of available LLM models'
  ClientHeight = 443
  ClientWidth = 625
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 21
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 41
    Align = alTop
    TabOrder = 0
    object ComboBox1: TComboBox
      Left = 7
      Top = 8
      Width = 162
      Height = 29
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboBox1Change
    end
    object Button1: TButton
      Left = 192
      Top = 9
      Width = 129
      Height = 26
      Caption = 'Show models'
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object ListBox1: TListBox
    AlignWithMargins = True
    Left = 7
    Top = 48
    Width = 611
    Height = 388
    Margins.Left = 7
    Margins.Top = 7
    Margins.Right = 7
    Margins.Bottom = 7
    Align = alClient
    ItemHeight = 21
    PopupMenu = PopupMenu1
    TabOrder = 1
  end
  object TMSMCPCloudAI1: TTMSMCPCloudAI
    Service = aiOpenAI
    Settings.GeminiModel = 'gemini-2.5-flash'
    Settings.OpenAIModel = 'gpt-5.4-mini-2026-03-17'
    Settings.OpenAISoundModel = 'gpt-4o-mini-tts'
    Settings.OpenAITranscribeModel = 'whisper-1'
    Settings.GrokModel = 'grok-4-1-fast-reasoning'
    Settings.ClaudeModel = 'claude-sonnet-4-6'
    Settings.OllamaModel = 'llama3.2:latest'
    Settings.DeepSeekModel = 'deepseek-chat'
    Settings.PerplexityModel = 'sonar-pro'
    Settings.OllamaHost = 'localhost'
    Settings.OllamaPath = '/api/chat'
    Settings.LlamaCppHost = 'localhost'
    Settings.LlamaCppPath = '/v1/chat/completions'
    Settings.MistralModel = 'mistral-large-latest'
    Settings.MistralTranscribeModel = 'voxtral-mini-2507'
    Tools = <>
    OnGetModels = TMSMCPCloudAI1GetModels
    Left = 780
    Top = 18
  end
  object PopupMenu1: TPopupMenu
    Left = 464
    Top = 336
    object Copytoclipboard1: TMenuItem
      Caption = 'Copy to clipboard'
      OnClick = Copytoclipboard1Click
    end
  end
end
