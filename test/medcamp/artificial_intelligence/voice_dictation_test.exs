defmodule Medcamp.ArtificialIntelligence.VoiceDictationTest do
  use ExUnit.Case, async: true

  alias Medcamp.ArtificialIntelligence.VoiceDictation

  defmodule FakeAIClient do
    def transcribe_audio(_path, opts) do
      send(self(), {:transcription_opts, opts})
      Process.get(:transcription_result, {:ok, "Habari, mgonjwa ana homa."})
    end

    def request_to_gpt(context, prompt, opts) do
      send(self(), {:translation_request, context, prompt, opts})
      Process.get(:translation_result, {:ok, "The patient has a fever."})
    end
  end

  test "passes the selected language to transcription and translates non-English text" do
    assert {:ok, "The patient has a fever."} =
             VoiceDictation.transcribe_to_english(
               "/tmp/recording.webm",
               "sw",
               [filename: "recording.webm"],
               FakeAIClient
             )

    assert_received {:transcription_opts, opts}
    assert opts[:language] == "sw"

    assert_received {:translation_request, context, prompt, opts}
    assert context =~ "Preserve every clinical detail"
    assert prompt =~ "Source language: Kiswahili"
    assert prompt =~ "Habari, mgonjwa ana homa."
    assert opts == []
  end

  test "returns English transcription without a translation request" do
    Process.put(:transcription_result, {:ok, "The patient has a fever."})

    assert {:ok, "The patient has a fever."} =
             VoiceDictation.transcribe_to_english("/tmp/recording.webm", "en", [], FakeAIClient)

    refute_received {:translation_request, _, _, _}
  end

  test "uses auto-detection and a language prompt for experimental Kenyan languages" do
    assert {:ok, "The patient has a fever."} =
             VoiceDictation.transcribe_to_english(
               "/tmp/recording.webm",
               "ki",
               [filename: "recording.webm"],
               FakeAIClient
             )

    assert_received {:transcription_opts, opts}
    refute Keyword.has_key?(opts, :language)
    assert opts[:prompt] =~ "Gikuyu"
    assert opts[:prompt] =~ "code-switching with Kiswahili"
    assert opts[:prompt] =~ "medication names"

    assert_received {:translation_request, context, prompt, translation_opts}
    assert context =~ "genuinely unintelligible source text as [unclear]"
    assert prompt =~ "Source language: Gikuyu (experimental)"
    assert translation_opts[:model] == "gpt-5.6-terra"
    assert translation_opts[:reasoning_effort] == "none"
  end

  test "rejects a language that is not offered by the modal" do
    assert {:error, "Please select a supported dictation language."} =
             VoiceDictation.transcribe_to_english(
               "/tmp/recording.webm",
               "unsupported",
               [],
               FakeAIClient
             )

    refute_received {:transcription_opts, _}
  end
end
