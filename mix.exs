defmodule PublicSuffix.Mixfile do
  use Mix.Project

  def project do
    [app: :public_suffix,
     version: "0.3.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [
      # :idna is intentionally NOT included in this list because it is
      # only used at compile time, as part of processing the publicsuffix.org
      # rules file. So it is not needed at runtime.
      applications: [
        :logger,
      ]
    ]
  end

  defp deps do
    [
      {:idna, ">= 1.2.0 and < 3.0.0"},
      # ex_doc and earmark are necessary to publish docs to hexdocs.pm.
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
    ]
  end

  defp description do
    """
    Operate on domain names using the public suffix rules provided by https://publicsuffix.org/.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Myron Marston", "Ben Kirzhner"],
      links: %{"GitHub" => "https://github.com/seomoz/publicsuffix-elixir",
               "Public Suffix List" => "https://publicsuffix.org/"},
      files: ["lib", "priv", "data/public_suffix_list.dat",
              "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
    ]
  end

  defp aliases do
    [
      "hex.publish": ["hex.publish", &tag_version/1, "hex.docs"],
    ]
  end

  defp tag_version(_args) do
    version = Keyword.fetch!(project, :version)
    System.cmd("git", ["tag", "-a", "-m", "Version #{version}", "v#{version}"])
    System.cmd("git", ["push", "origin"])
    System.cmd("git", ["push", "origin", "--tags"])
  end
end

defmodule Mix.Tasks.PublicSuffix.SyncFiles do
  use Mix.Task

  @shortdoc "Syncs the files from publicsuffix.org"
  @data_dir Path.expand("data", __DIR__)

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
