require 'pry'
require './utils'

def lines
  @lines ||= Utils.lines('./02.input.txt')
end

def count_em(string, substring)
  string.scan(/(?=#{substring})/).count
end

def has_amount?(line, amount)
  line.chars.uniq.each do |c|
    return true if count_em(line, c) == amount
  end
  false
end

two = lines.select {|l| has_amount?(l, 2)}.length
three = lines.select {|l| has_amount?(l, 3)}.length
puts "Part 1: #{two * three}"

def difference_count(left, right)
  left.chars.zip(right.chars).count {|x| x[0] != x[1] }
end

def find_diff
  lines.each do |current|
    lines.each do |other|
      if difference_count(current, other) == 1
        return (current.chars & other.chars).join
      end
    end
  end
end

puts "Part 2: #{find_diff}"
