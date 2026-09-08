object Form3: TForm3
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = 'AI automatic voice translation'
  ClientHeight = 653
  ClientWidth = 932
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 144
  TextHeight = 21
  object PaintBox1: TPaintBox
    Left = 36
    Top = 36
    Width = 170
    Height = 158
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    OnClick = PaintBox1Click
    OnPaint = PaintBox1Paint
  end
  object Label1: TLabel
    Left = 252
    Top = 36
    Width = 614
    Height = 158
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    AutoSize = False
    Caption = 'AI based automatic voice translator'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -65
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    WordWrap = True
  end
  object Label2: TLabel
    Left = 36
    Top = 233
    Width = 177
    Height = 21
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Result of speech to text'
  end
  object Label3: TLabel
    Left = 36
    Top = 428
    Width = 150
    Height = 21
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Result of translation'
  end
  object Memo1: TMemo
    Left = 36
    Top = 261
    Width = 614
    Height = 158
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 0
    OnChange = Memo1Change
  end
  object Memo2: TMemo
    Left = 36
    Top = 456
    Width = 614
    Height = 168
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 3
  end
  object ComboBox1: TComboBox
    Left = 671
    Top = 261
    Width = 217
    Height = 29
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 1
    Text = 'German'
    Items.Strings = (
      'French'
      'German'
      'English'
      'Italian'
      'Portuguese'
      'Spanish')
  end
  object btnTranslate: TButton
    Left = 671
    Top = 321
    Width = 217
    Height = 38
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    Caption = 'Translate'
    Enabled = False
    TabOrder = 2
    OnClick = btnTranslateClick
  end
  object TMSMCPCloudAI1: TTMSMCPCloudAI
    Service = aiOpenAI
    Settings.GeminiModel = 'gemini-1.5-flash-latest'
    Settings.OpenAIModel = 'gpt-4o'
    Settings.OpenAISoundModel = 'gpt-4o-mini-tts'
    Settings.OpenAITranscribeModel = 'whisper-1'
    Settings.GrokModel = 'grok-3'
    Settings.ClaudeModel = 'claude-3-5-sonnet-20241022'
    Settings.OllamaModel = 'llama3.2:latest'
    Settings.DeepSeekModel = 'deepseek-chat'
    Settings.PerplexityModel = 'sonar-pro'
    Settings.OllamaHost = 'localhost'
    Settings.OllamaPath = '/api/chat'
    Settings.MistralModel = 'mistral-large-latest'
    Settings.MistralTranscribeModel = 'voxtral-mini-2507'
    Tools = <>
    OnExecuted = TMSMCPCloudAI1Executed
    OnSpeechAudio = TMSMCPCloudAI1SpeechAudio
    OnTranscribeAudio = TMSMCPCloudAI1TranscribeAudio
    Left = 816
    Top = 156
  end
end
