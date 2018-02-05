defmodule Calc do
  def eval(expr) do
    expr
      |> String.trim
      |> String.codepoints
      |> Enum.filter(fn (x) -> x != " " end)
      |> Calc.group
      |> Calc.convert_characters
      |> Calc.combine_wrapper
      |> IO.inspect
  end

  def group(xs) do
    handle_char = fn
      "(", {[], 0, groups} -> {[], 1, groups}
      "(", {temp, 0, groups} -> {[], 1, groups ++ [group temp]}
      "(", {temp, depth, groups} -> {temp ++ ["("], depth + 1, groups}
      ")", {temp, 1, groups} -> {[], 0, groups ++ [group temp]}
      ")", {temp, depth, groups} -> {temp ++ [")"], depth - 1, groups}
      char, {temp, depth, groups} -> {temp ++ [char], depth, groups}
    end
    case Enum.reduce xs, {[], 0, []}, handle_char do
      {[], _, groups} -> groups
      {temp, _, []} -> temp
      {temp, _, groups} -> groups ++ [group temp]
    end
  end

  def convert_characters(groups) do
    handle_char = fn
      "+", {"", new_groups} -> {"", new_groups ++ [:add]}
      "-", {"", new_groups} -> {"", new_groups ++ [:sub]}
      "/", {"", new_groups} -> {"", new_groups ++ [:div]}
      "*", {"", new_groups} -> {"", new_groups ++ [:mul]}
      "+", {temp, new_groups} -> {"", new_groups ++ [String.to_integer(temp), :add]}
      "-", {temp, new_groups} -> {"", new_groups ++ [String.to_integer(temp), :sub]}
      "/", {temp, new_groups} -> {"", new_groups ++ [String.to_integer(temp), :div]}
      "*", {temp, new_groups} -> {"", new_groups ++ [String.to_integer(temp), :mul]}
      x, {temp, new_groups} when is_binary(x) -> {temp <> x, new_groups}
      x, {"", new_groups} -> {"", new_groups ++ [convert_characters(x)]}
      x, {temp, new_groups} -> {"", new_groups ++ [String.to_integer(temp), convert_characters(x)]}
    end
    case Enum.reduce groups, {"", []}, handle_char do
      {"", new_groups} -> new_groups
      {temp, new_groups} -> new_groups ++ [String.to_integer(temp)]
    end
  end

  def combine_wrapper(groups) do
    maybe_combined = combine groups
    if is_list(maybe_combined) do
      combine_wrapper List.foldl(groups, [], &(&1 ++ &2))
    else
      maybe_combined
    end
  end

  def combine(groups) do
    if Enum.count(groups) == 1 do
      Enum.at(groups, 0)
    else
      index = Enum.find_index(groups, fn(x) -> x == :div end)
        || Enum.find_index(groups, fn(x) -> x == :mul end)
        || Enum.find_index(groups, fn(x) -> x == :add end)
        || Enum.find_index(groups, fn(x) -> x == :sub end)
      left = Enum.slice(groups, 0..index - 1)
      right = Enum.slice(groups, index + 1..-1)
      if Enum.empty?(left) || Enum.empty?(right) do
        groups
      else
        op = Enum.at(groups, index)
        case op do
          :add -> combine_wrapper(left) + combine_wrapper(right)
          :sub -> combine_wrapper(left) - combine_wrapper(right)
          :mul -> combine_wrapper(left) * combine_wrapper(right)
          :div -> combine_wrapper(left) / combine_wrapper(right)
        end
      end
    end
  end

  def main do
    expr = IO.gets "> "
    eval expr
    main()
  end
end
