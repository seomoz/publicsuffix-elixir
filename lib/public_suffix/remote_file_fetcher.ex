defmodule PublicSuffix.RemoteFileFetcher do
  @moduledoc false

  def fetch_remote_file(url) when is_binary(url) do
    # These are not listed in `applications` in `mix.exs` because
    # this is only used at compile time or in one-off mix tasks --
    # so at deployed runtime, this is not used and these applications
    # are not needed.
    :inets.start
    :ssl.start

    url
    |> to_charlist()
    |> :httpc.request
    |> case do
         {:ok, {{_, 200, _}, _headers, body}} -> {:ok, to_string(body)}
         otherwise -> {:error, otherwise}
       end
  end
end
