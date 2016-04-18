defmodule PublicSuffix do
  @moduledoc """
  Implements the publicsuffix algorithm described at https://publicsuffix.org/list/.
  Comments throughout this module are direct quotes from https://publicsuffix.org/list/,
  showing how individual lines of code relate to the specification.
  """

  @doc """
  Extracts the _registrable_ part of the provided domain. The registrable
  part is the public suffix plus one additional domain part. For example,
  given a public suffix of `co.uk`, so `example.co.uk` would be the registrable
  domain part.

  ## Examples
    iex> registrable_domain("foo.bar.com")
    "bar.com"

  You can use the `ignore_private` keyword to exclude private (non-ICANN) domains.

    iex> registrable_domain("foo.github.io", ignore_private: false)
    "foo.github.io"
    iex> registrable_domain("foo.github.io", ignore_private: true)
    "github.io"
    iex> registrable_domain("foo.github.io")
    "foo.github.io"
  """
  @spec registrable_domain(nil | String.t) :: nil | String.t
  @spec registrable_domain(nil | String.t, ignore_private: boolean) :: nil | String.t
  def registrable_domain(domain, options \\ [ignore_private: false])
  def registrable_domain(nil, _), do: nil
  def registrable_domain(domain, options) do
    domain
    # "The domain...must be canonicalized in the normal way for hostnames - lower-case"
    |> String.downcase
    # "Empty labels are not permitted, meaning that leading and trailing dots are ignored."
    |> String.strip(?.)
    # "A domain or rule can be split into a list of labels using the separator "." (dot)."
    |> String.split(".")
    |> find_registrable_domain_labels(options)
    |> case do
         nil -> nil
         labels -> Enum.join(labels, ".")
       end
  end

  defp find_registrable_domain_labels(labels, options) do
    allowed_rule_types = allowed_rule_types_for(options)

    prevailing_rule =
      # "If more than one rule matches, the prevailing rule is the one which is an exception rule."
      find_prevailing_exception_rule(labels, allowed_rule_types) ||
      find_prevailing_normal_rule(labels, allowed_rule_types) ||
      # "If no rules match, the prevailing rule is "*"."
      ["*"]

    rule_size = length(prevailing_rule)

    if length(labels) > rule_size do
      labels
      |> Enum.reverse
      # "The registered or registrable domain is the public suffix plus one additional label."
      |> Enum.take(rule_size + 1)
      |> Enum.reverse
    else
      nil
    end
  end

  rule_maps =
    Path.expand("../data/public_suffix_list.dat", __DIR__)
    |> File.read!
    |> PublicSuffix.RulesParser.parse_rules

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
end
