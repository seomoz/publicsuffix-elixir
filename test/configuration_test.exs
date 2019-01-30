defmodule PublicSuffix.ConfigurationTest do
  use ExUnit.Case
  @data_file_name "public_suffix_list.dat"
  @cached_data_dir Path.expand("../data", __DIR__)

  setup do
    temp_dir = "tmp/#{:test_server.temp_name('public_suffix-test')}"
    File.mkdir_p!(temp_dir)

    cached_file_name = Path.join(@cached_data_dir, @data_file_name)
    backup_file_name = Path.join(temp_dir, @data_file_name)

    File.cp!(cached_file_name, backup_file_name)

    modified_rules =
      cached_file_name
      |> File.read!
      |> Kernel.<>("\npublicsuffix.elixir")

    File.write!(cached_file_name, modified_rules)

    on_exit fn ->
      # restore things...
      recompile_lib()
      File.cp!(backup_file_name, cached_file_name)
      File.rm_rf!(temp_dir)
    end
  end

  test "compiles using a newly fetched copy of the rules file if so configured" do
    recompile_lib()
    assert get_public_suffix("foo.publicsuffix.elixir") == "publicsuffix.elixir"
    recompile_lib [{"PUBLIC_SUFFIX_DOWNLOAD_DATA_ON_COMPILE", "true"}]
    assert get_public_suffix("foo.publicsuffix.elixir") == "elixir"
  end

  defp get_public_suffix(domain) do
    expression = "#{inspect domain} |> PublicSuffix.public_suffix |> IO.puts"
    assert {result, 0} = System.cmd "mix", ["run", "-e", expression]
    result |> String.trim() |> String.split("\n") |> List.last
  end

  defp recompile_lib(env \\ []) do
    assert {_output, 0} = System.cmd "mix", ["compile", "--force"], env: env
  end
end
