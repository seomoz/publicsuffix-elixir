defmodule Mix.Tasks.Compile.PublicSuffix do
  use Mix.Task

  @shortdoc "Syncs data and tests from publicsuffix.org."
  @data_dir Path.expand("../../../data", __DIR__)

  def run(_) do
    File.mkdir_p!(@data_dir)
    sync_file "https://publicsuffix.org/list/public_suffix_list.dat", "public_suffix_list.dat"
    sync_file "https://raw.githubusercontent.com/publicsuffix/list/master/tests/tests.txt", "tests.txt"
  end

  defp sync_file(remote_url, local_path) do
    local_path = Path.join(@data_dir, local_path)

    [
      "curl",
      "-s",
      remote_url,
      "--output",
      local_path,
    ]
    |> Enum.join(" ")
    |> Mix.shell.cmd

    IO.puts "Synced #{remote_url} to #{local_path}"
  end
end
