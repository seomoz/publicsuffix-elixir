defmodule PublicSuffix.PublicSuffixTest do
  use ExUnit.Case
  import PublicSuffix
  doctest PublicSuffix

  test_cases = [
    {"exact match", "foo.github.io", "foo.github.io", "github.io"},
    {"wildcard", "foo.bar.api.githubcloud.com", "foo.bar.api.githubcloud.com", "githubcloud.com"},
    # The current rules file does not have any private exception rules, so we don't
    # have any tests for it :(.
  ]

  for {rule_type, input, expected_with_private, expected_without_private} <- test_cases do
    @input input
    @expected_with_private expected_with_private
    @expected_without_private expected_without_private

    test "`registrable_domain` includes private domains by default (#{rule_type})" do
      assert registrable_domain(@input) == @expected_with_private
    end

    test "`registrable_domain` includes private domains if passed `ignore_private: false` (#{rule_type})" do
      assert registrable_domain(@input, ignore_private: false) == @expected_with_private
    end

    test "`registrable_domain` excludes private domains if passed `ignore_private: true` (#{rule_type})" do
      assert registrable_domain(@input, ignore_private: true) == @expected_without_private
    end
  end
end
