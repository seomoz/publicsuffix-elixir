defmodule PublicSuffix do
  @moduledoc """
  Implements the publicsuffix algorithm described at https://publicsuffix.org/list/.
  Comments throughout this module are direct quotes from https://publicsuffix.org/list/,
  showing how individual lines of code relate to the specification.
  """

  @doc """
  Extracts the _registerable_ part of the provided domain. The registerable
  part is the public suffix plus one additional domain part. For example,
  given a public suffix of `co.uk`, so `example.co.uk` would be the registerable
  domain part.
  """
  @spec registerable_domain_part(nil | String.t) :: nil | String.t
  def registerable_domain_part(nil), do: nil
  def registerable_domain_part(domain) do
    domain
    # "The domain...must be canonicalized in the normal way for hostnames - lower-case"
    |> String.downcase
    # "Empty labels are not permitted, meaning that leading and trailing dots are ignored."
    |> String.strip(?.)
    # "A domain or rule can be split into a list of labels using the separator "." (dot)."
    |> String.split(".")
    |> find_registerable_domain_labels
    |> case do
         nil -> nil
         labels -> Enum.join(labels, ".")
       end
  end

  defp find_registerable_domain_labels(labels) do
    prevailing_rule =
      # "If more than one rule matches, the prevailing rule is the one which is an exception rule."
      find_prevailing_exception_rule(labels) ||
      find_prevailing_normal_rule(labels) ||
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

  {exception_rules, normal_rules} =
    Path.expand("../data/public_suffix_list.dat", __DIR__)
    |> File.read!
    # "The list is a set of rules, with one rule per line."
    |> String.split("\n")
    # "...entire lines can also be commented using //.
    # Each line which is not entirely whitespace or begins with a comment
    # contains a rule."
    |> Stream.reject(&(&1 =~ ~r/^\s*$/ || String.starts_with?(&1, "//")))
    # "Each line is only read up to the first whitespace"
    |> Stream.map(&String.rstrip/1)
    |> Stream.flat_map(fn rule ->
      [rule,
        rule
        |> :xmerl_ucs.from_utf8
        |> :idna.to_ascii
        |> to_string
      ]
    end)
    # "An exclamation mark (!) at the start of a rule marks an exception to a
    # previous wildcard rule."
    |> Enum.partition(&String.starts_with?(&1, "!"))

  # TODO: "Wildcards are not restricted to appear only in the leftmost position"
  {wild_card_rules, full_match_rules} = Enum.partition(normal_rules, &String.starts_with?(&1, "*."))

  to_domain_label_set = fn rules ->
    rules
    # "A domain or rule can be split into a list of labels using the separator "." (dot)."
    |> Stream.map(&String.split(&1, "."))
    |> MapSet.new
  end

  # "A rule may begin with a "!" (exclamation mark). If it does, it is labelled
  # as a "exception rule" and then treated as if the exclamation mark is not
  # present."
  @exception_rules exception_rules
    |> Stream.map(&String.lstrip(&1, ?!))
    |> to_domain_label_set.()
  defp find_prevailing_exception_rule([]), do: nil
  defp find_prevailing_exception_rule([_ | suffix] = domain_labels) do
    if domain_labels in @exception_rules do
      # "If the prevailing rule is a exception rule, modify it by removing the leftmost label."
      suffix
    else
      find_prevailing_exception_rule(suffix)
    end
  end

  @full_match_rules to_domain_label_set.(full_match_rules)
  @wild_card_rules to_domain_label_set.(wild_card_rules)
  defp find_prevailing_normal_rule([]), do: nil
  defp find_prevailing_normal_rule([_ | suffix] = domain_labels) do
    cond do
      domain_labels in @full_match_rules -> domain_labels
      # TODO: "Wildcards are not restricted to appear only in the leftmost position"
      ["*" | suffix] in @wild_card_rules -> domain_labels
      true -> find_prevailing_normal_rule(suffix)
    end
  end
end
