defmodule PublicSuffix.TestCaseGenerator do
  @data_dir Path.expand("../data", __DIR__)
  @header_line_count 2

  def test_cases do
    @data_dir
    |> Path.join("tests.txt")
    |> File.read!
    |> String.split("\n")
    |> Stream.with_index
    |> Stream.reject(fn {line, _} -> line == "" end)
    |> Stream.drop(@header_line_count)
    # Match on descriptive comment lines (which go before the test cases to which they apply)
    |> Stream.chunk_by(fn {line, _index} -> String.starts_with?(line, "// ") end)
    |> Stream.chunk(2) # provides chunks of comment plus test cases matching the comment
    |> Stream.flat_map(&parse_group/1)
  end

  defp parse_group([[{"// " <> group_description, _}], test_cases]) do
    group_description = String.rstrip(group_description, ?.)

    test_cases
    |> Stream.with_index
    |> Enum.map(&generate_test_case(&1, group_description))
  end

  defp generate_test_case({{test_case_line, line_index}, group_case_index}, group_description) do
    [input, output] =
      test_case_line
      |> String.replace_prefix("checkPublicSuffix(", "")
      |> String.replace_suffix(");", "")
      |> String.split(", ")
      |> Enum.map(&parse_arg/1)

    %{
      group_description: group_description,
      line_number: line_index + 1,
      group_case_number: group_case_index + 1,
      input: input,
      output: output,
    }
  end

  defp parse_arg("null"), do: nil
  defp parse_arg(string), do: String.strip(string, ?')
end

defmodule PublicSuffixGeneratedCasesTest do
  use ExUnit.Case
  import PublicSuffix

  for test_case <- PublicSuffix.TestCaseGenerator.test_cases do
    @test_case test_case
    expression = "registrable_domain(#{inspect test_case.input}) == #{inspect test_case.output}"
    description = "#{test_case.group_description} ##{test_case.group_case_number} -- line #{test_case.line_number}"
    test_name = case test_case.group_description do
      "IDN labels" -> "#{description} (can't embed expression in test name due to chinese characters)"
      _otherwise -> "#{expression} (#{description})"
    end

    @tag skip: (
      # the test file has some commented out tests.
      String.starts_with?(test_case.input || "", "//") ||
      # These two test cases are inconsistent with our reading
      # of the spec. TODO: figure out if we are wrong or the
      # tests are wrong.
      # See: https://github.com/publicsuffix/list/issues/208
      test_case.input == ".example.example" ||
      test_case.input == ".example.com"
    )
    test test_name do
      assert registrable_domain(@test_case.input) == @test_case.output
    end
  end
end
