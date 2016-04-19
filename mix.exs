defmodule PublicSuffix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :public_suffix,
      version: "0.0.1",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      compilers: compilers,
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :idna,
        :logger,
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "1.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:idna, "~> 1.2"},
    ]
  end

  defp compilers do
    if Application.get_env(:public_suffix, :download_data_on_compile, false) do
      [:public_suffix | Mix.compilers]
    else
      Mix.compilers
    end
  end
end
