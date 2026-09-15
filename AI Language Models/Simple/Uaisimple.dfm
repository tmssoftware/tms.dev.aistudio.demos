object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'AI LLM with function calling demo'
  ClientHeight = 461
  ClientWidth = 852
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 21
  object Memo2: TMemo
    Left = 0
    Top = 137
    Width = 852
    Height = 324
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 852
    Height = 137
    Align = alTop
    TabOrder = 1
    object ComboBox1: TComboBox
      Left = 8
      Top = 11
      Width = 145
      Height = 29
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboBox1Change
    end
    object Memo1: TMemo
      AlignWithMargins = True
      Left = 4
      Top = 44
      Width = 844
      Height = 89
      Align = alBottom
      Lines.Strings = (
        
          'What is a good RAD native Windows software development tool and ' +
          'language?')
      TabOrder = 1
    end
    object Button1: TButton
      Left = 172
      Top = 9
      Width = 92
      Height = 31
      Caption = 'Execute '
      TabOrder = 2
      OnClick = Button1Click
    end
    object ProgressBar1: TProgressBar
      Left = 288
      Top = 15
      Width = 281
      Height = 17
      Smooth = True
      Style = pbstMarquee
      SmoothReverse = True
      State = pbsPaused
      TabOrder = 3
    end
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
    OnExecuted = TMSMCPCloudAI1Executed
    Left = 752
    Top = 12
  end
end
