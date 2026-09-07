defmodule Medcamp.ArtificialIntelligence.VoiceDictation do
  @moduledoc """
  Transcribes clinical dictation in a selected source language and returns
  English text suitable for insertion into a doctor's note.
  """

  alias Medcamp.ArtificialIntelligence.OpenAI

  @kenyan_languages [
    {"en", "English (Kenya)"},
    {"sw", "Kiswahili"},
    {"sheng", "Sheng (experimental)"},
    {"ki", "Gikuyu (experimental)"},
    {"luo", "Dholuo (experimental)"},
    {"kam", "Kikamba (experimental)"},
    {"luy", "Luhya (experimental)"},
    {"kln", "Kalenjin (experimental)"},
    {"so", "Somali (experimental)"}
  ]

  # These languages are explicitly listed in OpenAI's speech-to-text
  # documentation. Kenyan languages without documented support are offered as
  # experimental options and rely on auto-detection plus a language prompt.
  @other_languages [
    {"af", "Afrikaans"},
    {"ar", "Arabic"},
    {"hy", "Armenian"},
    {"az", "Azerbaijani"},
    {"be", "Belarusian"},
    {"bs", "Bosnian"},
    {"bg", "Bulgarian"},
    {"ca", "Catalan"},
    {"zh", "Chinese"},
    {"hr", "Croatian"},
    {"cs", "Czech"},
    {"da", "Danish"},
    {"nl", "Dutch"},
    {"et", "Estonian"},
    {"fi", "Finnish"},
    {"fr", "French"},
    {"gl", "Galician"},
    {"de", "German"},
    {"el", "Greek"},
    {"he", "Hebrew"},
    {"hi", "Hindi"},
    {"hu", "Hungarian"},
    {"is", "Icelandic"},
    {"id", "Indonesian"},
    {"it", "Italian"},
    {"ja", "Japanese"},
    {"kn", "Kannada"},
    {"kk", "Kazakh"},
    {"ko", "Korean"},
    {"lv", "Latvian"},
    {"lt", "Lithuanian"},
    {"mk", "Macedonian"},
    {"ms", "Malay"},
    {"mr", "Marathi"},
    {"mi", "Maori"},
    {"ne", "Nepali"},
    {"no", "Norwegian"},
    {"fa", "Persian"},
    {"pl", "Polish"},
    {"pt", "Portuguese"},
    {"ro", "Romanian"},
    {"ru", "Russian"},
    {"sr", "Serbian"},
    {"sk", "Slovak"},
    {"sl", "Slovenian"},
    {"es", "Spanish"},
    {"sv", "Swedish"},
    {"tl", "Tagalog"},
    {"ta", "Tamil"},
    {"th", "Thai"},
    {"tr", "Turkish"},
    {"uk", "Ukrainian"},
    {"ur", "Urdu"},
    {"vi", "Vietnamese"},
    {"cy", "Welsh"}
  ]

  @languages @kenyan_languages ++ @other_languages

  @experimental_language_context %{
    "sheng" => "Sheng, which commonly mixes Kiswahili and English",
    "ki" => "Gikuyu (Kikuyu)",
    "luo" => "Dholuo",
    "kam" => "Kikamba (Kamba)",
    "luy" => "Luhya",
    "kln" => "Kalenjin",
    "so" => "Somali as used in Kenya"
  }

  @experimental_translation_model "gpt-5.6-terra"

  @translation_context """
  You are a precise medical translator. Translate the supplied clinical dictation into English.
  Preserve every clinical detail, negation, uncertainty, patient name, medication name, dose,
  unit, abbreviation, number, and formatting cue. Code-switching with Kiswahili or English may
  occur. Do not summarize, infer missing words, correct clinical facts, or add information. Mark
  genuinely unintelligible source text as [unclear]. Return only the English translation.
  """

  def languages, do: @languages
  def kenyan_languages, do: @kenyan_languages
  def other_languages, do: @other_languages

  def language_name(code) when is_binary(code) do
    case List.keyfind(@languages, code, 0) do
      {^code, name} -> {:ok, name}
      nil -> {:error, "Please select a supported dictation language."}
    end
  end

  def language_name(_code), do: {:error, "Please select a supported dictation language."}

  def transcribe_to_english(audio_path, language, upload_opts, ai_client \\ OpenAI) do
    with {:ok, language_name} <- language_name(language),
         {:ok, transcript} <-
           ai_client.transcribe_audio(
             audio_path,
             Keyword.merge(upload_opts, transcription_options(language))
           ),
         {:ok, english_text} <- translate(transcript, language, language_name, ai_client) do
      {:ok, english_text}
    end
  end

  defp transcription_options(language) do
    case Map.fetch(@experimental_language_context, language) do
      {:ok, language_context} ->
        [
          prompt: """
          Clinical dictation spoken in #{language_context}, possibly code-switching with Kiswahili
          or English. Transcribe only what is spoken. Preserve patient names, symptoms, clinical
          terms, negations, medication names, doses, units, abbreviations, and numbers exactly.
          Do not add missing details.
          """
        ]

      :error ->
        [language: language]
    end
  end

  defp translate(transcript, "en", _language_name, _ai_client), do: {:ok, transcript}

  defp translate(transcript, language, language_name, ai_client) do
    ai_client.request_to_gpt(
      @translation_context,
      "Source language: #{language_name}\n\nClinical dictation:\n#{transcript}",
      translation_options(language)
    )
  end

  defp translation_options(language) do
    if Map.has_key?(@experimental_language_context, language) do
      [
        model:
          System.get_env("OPENAI_DICTATION_TRANSLATION_MODEL") ||
            @experimental_translation_model,
        reasoning_effort: "none"
      ]
    else
      []
    end
  end
end
