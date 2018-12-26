require 'pry'
require './utils'

include Utils

def next_at_position(input, position)
  while input[position] == nil
    position += 1
    break if position >= input.length
  end

  position_val = input[position]
  [position_val, position_val.nil? ? nil : position]
end

def should_reduce?(input, position)
  return [false, nil] if input[position].nil?
  next_char, next_position = next_at_position(input, position + 1)
  result = input[position].swapcase == next_char
  return [result, result ? next_position : nil]
end

def reduce(input)
  input = input.chars
  position = 0

  while position <= input.length
    reduce, reduce_at = should_reduce?(input, position)
    if reduce
      input[position] = nil
      input[reduce_at] = nil

      # back it up to the previous non-nil value
      while (input[position].nil? && position > 0)
        position -= 1
      end
    else
      position += 1
    end
  end

  input.join
end


part 1 do
  test(next_at_position(["A", "B", "C"], 1), ["B", 1], "[A, B, C], 1")
  test(next_at_position(["A", "B", "C"], 2), ["C", 2], "[A, B, C], 2")
  test(next_at_position(["A", "B", "C"], 3), [nil, nil], "[A, B, C], 3")
  test(next_at_position(["A", nil, "C"], 1), ["C", 2], "[A nil C], 1")

  test(should_reduce?(["a", "A"], 0), [true, 1], "[a A], 0")
  test(should_reduce?(["a", "B"], 0), [false, nil], "[a B], 0")
  test(should_reduce?(["a", nil, nil, "A"], 0), [true, 3], "[a, nil, nil, A], 0")

  test_call(:reduce, "", "Aa")
  test_call(:reduce, "", "abBA")
  test_call(:reduce, "abAB", "abAB")
  test_call(:reduce, "aabAAB", "aabAAB")
  test_call(:reduce, "dabCBAcaDA", "dabAcCaCBAcCcaDA")
  test_call(:reduce, "bCB", "aAbCBCc")

  test({length: reduce(input.chars).length}, {length: 11042}, input)
end

part 2 do
  def test_two(input, expect)
    removals = input.downcase.chars.uniq
    results = []

    removals.each do |remove|
      replaced = input.gsub(remove, "")
      replaced = replaced.gsub(remove.upcase, "")
      result = reduce(replaced.chars)
      results << {length: result.length, char: remove}
    end

    v = results.sort_by {|r| r[:length]}.first

    test(v, expect, input)
  end

  test_two("dabAcCaCBAcCcaDA", {length: 4, char: 'c'})
  test_two(input, nil)
end
