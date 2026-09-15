object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'AI FileSystem ToolSet demo'
  ClientHeight = 778
  ClientWidth = 999
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 999
    Height = 145
    Align = alTop
    TabOrder = 0
    object ComboBox1: TComboBox
      Left = 16
      Top = 19
      Width = 145
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboBox1Change
    end
    object Button1: TButton
      Left = 167
      Top = 17
      Width = 75
      Height = 25
      Caption = 'Execute'
      TabOrder = 1
      OnClick = Button1Click
    end
    object Memo1: TMemo
      Left = 248
      Top = 19
      Width = 742
      Height = 120
      Lines.Strings = (
        
          'List all files in the current folder with details such as file s' +
          'ize, file date and create in this folder a text file named FILEL' +
          'IST.TXT with this list of the '
        'details '
        'of the files ')
      TabOrder = 2
    end
    object ProgressBar1: TProgressBar
      Left = 16
      Top = 64
      Width = 226
      Height = 17
      Style = pbstMarquee
      State = pbsPaused
      TabOrder = 3
    end
  end
  object Memo2: TMemo
    Left = 8
    Top = 151
    Width = 982
    Height = 609
    ScrollBars = ssBoth
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
    OnExecuted = TMSMCPCloudAI1Executed
    Left = 728
    Top = 192
  end
end
