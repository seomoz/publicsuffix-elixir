defmodule PublicSuffix.RemoteFileFetcher do
  @moduledoc false

  def fetch_remote_file(url) when is_binary(url) do
    # These are not listed in `applications` in `mix.exs` because
    # this is only used at compile time or in one-off mix tasks --
    # so at deployed runtime, this is not used and these applications
    # are not needed.
    :hackney.start()

    url
    |> :hackney.request
    |> case do
         {:ok, 200, _headers, body_ref} -> :hackney.body(body_ref)
         otherwise -> {:error, otherwise}
       end
  end
end
