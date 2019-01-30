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
    |> Stream.chunk_every(2) # provides chunks of comment plus test cases matching the comment
    |> Stream.flat_map(&parse_group/1)
  end

  defp parse_group([[{"// " <> group_description, _}], test_cases]) do
    group_description = String.trim_trailing(group_description, ".")

    test_cases
    |> Stream.with_index
    |> Enum.map(&generate_test_case(&1, group_description))
  end

  defp generate_test_case({{test_case_line, line_index}, group_case_index}, group_description) do
    [input, registrable_domain_output] =
      test_case_line
      |> String.split(" ")
      |> Enum.map(&parse_arg/1)

    %{
      group_description: group_description,
      line_number: line_index + 1,
      group_case_number: group_case_index + 1,
      input: input,
      registrable_domain_output: registrable_domain_output,
      public_suffix_output: public_suffix_output(registrable_domain_output, input),
    }
  end

  defp parse_arg("null"), do: nil
  defp parse_arg(string), do: String.trim(string, "'")

  defp public_suffix_output(nil, nil), do: nil
  # Inputs with a leading dot are a special case: the output should always be `nil`.
  defp public_suffix_output(nil, "." <> _), do: nil
  defp public_suffix_output(nil, input) do
    # If the `registrable_domain` is `nil`, it is generally because the provided input
    # is itself a public suffix and therefore has no registrable domain. However, the inputs
    # are not sanitized and we need to sanitize the inputs to convert them to expected
    # public suffix outputs.
    input
    |> String.downcase
    |> String.trim_leading(".")
  end
  defp public_suffix_output(registrable_domain, _) do
    registrable_domain
    |> String.split(".")
    |> Enum.drop(1)
    |> Enum.join(".")
  end
end

defmodule PublicSuffixGeneratedCasesTest do
  use ExUnit.Case
  import PublicSuffix

  test_name = fn test_case, fun_name, output_field ->
    output = Map.fetch!(test_case, output_field)

    expression = "#{fun_name}(#{inspect test_case.input}) == #{inspect output}"
    description = "#{test_case.group_description} ##{test_case.group_case_number} -- line #{test_case.line_number}"
    case test_case.group_description do
      "IDN labels" -> "#{fun_name} (#{description}) (can't embed expression in test name due to chinese characters)"
      _otherwise -> "#{expression} (#{description})"
    end
  end

  for test_case <- PublicSuffix.TestCaseGenerator.test_cases, test_case.input do
    @test_case test_case
    # the test file has some commented out tests.
    should_skip? = String.starts_with?(test_case.input || "", "//")

    @tag skip: should_skip?
    test test_name.(test_case, "registrable_domain", :registrable_domain_output) do
      assert registrable_domain(@test_case.input) == @test_case.registrable_domain_output
    end

    @tag skip: should_skip?
    test test_name.(test_case, "public_suffix", :public_suffix_output) do
      assert public_suffix(@test_case.input) == @test_case.public_suffix_output
    end
  end
end
