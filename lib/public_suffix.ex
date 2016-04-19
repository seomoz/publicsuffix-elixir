defmodule PublicSuffix do
  import PublicSuffix.{RemoteFileFetcher, RulesParser}

  @moduledoc """
  Implements the publicsuffix algorithm described at https://publicsuffix.org/list/.
  Comments throughout this module are direct quotes from https://publicsuffix.org/list/,
  showing how individual lines of code relate to the specification.
  """

  @type options :: [ignore_private: boolean]

  @doc """
  Extracts the public suffix from the provided domain based on the publicsuffix.org rules.

  ## Examples
    iex> public_suffix("foo.bar.com")
    "com"

  You can use the `ignore_private` keyword to exclude private (non-ICANN) domains.

    iex> public_suffix("foo.github.io", ignore_private: false)
    "github.io"
    iex> public_suffix("foo.github.io", ignore_private: true)
    "io"
    iex> public_suffix("foo.github.io")
    "github.io"
  """
  @spec public_suffix(String.t) :: nil | String.t
  @spec public_suffix(String.t, options) :: nil | String.t
  def public_suffix(domain, options \\ []) when is_binary(domain) do
    parse_domain(domain, options, 0)
  end

  @doc """
  Extracts the _registrable_ part of the provided domain. The registrable
  part is the public suffix plus one additional domain part. For example,
  given a public suffix of `co.uk`, `example.co.uk` would be the registrable
  domain part. If the domain does not contain a registrable part (for example,
  if the domain is itself a public suffix), this function will return `nil`.

  ## Examples
    iex> registrable_domain("foo.bar.com")
    "bar.com"
    iex> registrable_domain("com")
    nil

  You can use the `ignore_private` keyword to exclude private (non-ICANN) domains.

    iex> registrable_domain("foo.github.io", ignore_private: false)
    "foo.github.io"
    iex> registrable_domain("foo.github.io", ignore_private: true)
    "github.io"
    iex> registrable_domain("foo.github.io")
    "foo.github.io"
  """
  @spec registrable_domain(String.t) :: nil | String.t
  @spec registrable_domain(String.t, options) :: nil | String.t
  def registrable_domain(domain, options \\ []) when is_binary(domain) do
    # "The registered or registrable domain is the public suffix plus one additional label."
    parse_domain(domain, options, 1)
  end

  # Inputs with a leading dot should be treated as a special case.
  # see https://github.com/publicsuffix/list/issues/208
  defp parse_domain("." <> _domain, _, _), do: nil
  defp parse_domain(domain, options, extra_label_parts) do
    domain
    # "The domain...must be canonicalized in the normal way for hostnames - lower-case"
    |> String.downcase
    # "A domain or rule can be split into a list of labels using the separator "." (dot)."
    |> String.split(".")
    |> extract_labels_using_rules(extra_label_parts, options)
    |> case do
         nil -> nil
         labels -> Enum.join(labels, ".")
       end
  end

  defp extract_labels_using_rules(labels, extra_label_parts, options) do
    num_labels =
      labels
      |> find_prevailing_rule(options)
      |> length
      |> +(extra_label_parts)

    if length(labels) >= num_labels do
      take_last_n(labels, num_labels)
    else
      nil
    end
  end

  defp find_prevailing_rule(labels, options) do
    allowed_rule_types = allowed_rule_types_for(options)

    # "If more than one rule matches, the prevailing rule is the one which is an exception rule."
    find_prevailing_exception_rule(labels, allowed_rule_types) ||
    find_prevailing_normal_rule(labels, allowed_rule_types) ||
    # "If no rules match, the prevailing rule is "*"."
    ["*"]
  end

  data_file = Path.expand("../data/public_suffix_list.dat", __DIR__)
  @external_resource data_file

  raw_data = if Application.get_env(:public_suffix, :download_data_on_compile, false) do
    case fetch_remote_file("https://publicsuffix.org/list/public_suffix_list.dat") do
      {:ok, data} ->
        IO.puts "PublicSuffix: fetched fresh data file for compilation."
        data
      {:error, error} ->
         raise """
         PublicSuffix: failed to fetch fresh data file for compilation:
         #{inspect error}

         Try again or change `download_data_on_compile` config to `false` to use the cached copy of the rules file.
         """
    end
  else
    File.read!(data_file)
  end

  rule_maps = parse_rules(raw_data)

  @exception_rules rule_maps.exception_rules
  defp find_prevailing_exception_rule([], _allowed_rule_types), do: nil
  defp find_prevailing_exception_rule([_ | suffix] = domain_labels, allowed_rule_types) do
    if @exception_rules[domain_labels] in allowed_rule_types do
      # "If the prevailing rule is a exception rule, modify it by removing the leftmost label."
      suffix
    else
      find_prevailing_exception_rule(suffix, allowed_rule_types)
    end
  end

  @exact_match_rules rule_maps.exact_match_rules
  @wild_card_rules rule_maps.wild_card_rules
  defp find_prevailing_normal_rule([], _allowed_rule_types), do: nil
  defp find_prevailing_normal_rule([_ | suffix] = domain_labels, allowed_rule_types) do
    cond do
      @exact_match_rules[domain_labels] in allowed_rule_types -> domain_labels
      # TODO: "Wildcards are not restricted to appear only in the leftmost position"
      @wild_card_rules[["*" | suffix]] in allowed_rule_types -> domain_labels
      true -> find_prevailing_normal_rule(suffix, allowed_rule_types)
    end
  end

  defp allowed_rule_types_for(options) do
    if Keyword.get(options, :ignore_private, false) do
      [:icann]
    else
      [:icann, :private]
    end
  end

  defp take_last_n(list, n) do
    list
    |> Enum.reverse
    |> Enum.take(n)
    |> Enum.reverse
  end
end
