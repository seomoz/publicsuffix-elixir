defmodule PublicSuffix.RulesParser do
  @moduledoc false

  @type rule :: [String.t, ...]
  @type rule_type :: :icann | :private
  @type rule_map :: %{rule => rule_type}

  @spec parse_rules(String.t) :: %{
    exception_rules: rule_map,
    exact_match_rules: rule_map,
    wild_card_rules: rule_map,
  }
  def parse_rules(rule_string) do
    [icann_rule_string, private_rule_string] =
      rule_string
      |> String.split(~r|===END ICANN DOMAINS===\n// ===BEGIN PRIVATE DOMAINS===|, parts: 2)

    icann_rules = parse_rules_section(icann_rule_string, :icann)
    private_rules = parse_rules_section(private_rule_string, :private)

    Map.merge(icann_rules, private_rules, fn _key, m1, m2 -> Map.merge(m1, m2) end)
  end

  def parse_rules_section(rule_section_string, type) do
    {exception_rules, normal_rules} =
      rule_section_string
      # "The list is a set of rules, with one rule per line."
      |> String.split("\n")
      # "...entire lines can also be commented using //.
      # Each line which is not entirely whitespace or begins with a comment
      # contains a rule."
      |> Stream.reject(&(&1 =~ ~r/^\s*$/ || String.starts_with?(&1, "//")))
      # "Each line is only read up to the first whitespace"
      |> Stream.map(&String.rstrip/1)
      |> Stream.flat_map(fn rule -> [rule, punycode_domain(rule)] end)
      # "An exclamation mark (!) at the start of a rule marks an exception to a
      # previous wildcard rule."
      |> Enum.partition(&String.starts_with?(&1, "!"))

    # TODO: "Wildcards are not restricted to appear only in the leftmost position"
    {wild_card_rules, exact_match_rules} = Enum.partition(normal_rules, &String.starts_with?(&1, "*."))

    exception_rules =
      exception_rules
      |> Stream.map(&String.lstrip(&1, ?!))
      |> to_domain_label_map(type)

    exact_match_rules = to_domain_label_map(exact_match_rules, type)
    wild_card_rules = to_domain_label_map(wild_card_rules, type)

    %{
      exception_rules: exception_rules,
      exact_match_rules: exact_match_rules,
      wild_card_rules: wild_card_rules,
    }
  end

  defp punycode_domain(rule) do
    rule
    |> :xmerl_ucs.from_utf8
    |> :idna.to_ascii
    |> to_string
  end

  defp to_domain_label_map(rules, type) do
    rules
    # "A domain or rule can be split into a list of labels using the separator "." (dot)."
    |> Stream.map(&{String.split(&1, "."), type})
    |> Map.new
  end
end
