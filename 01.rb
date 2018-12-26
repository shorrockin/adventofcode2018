require 'pry'
require './utils'

def lines
  @lines ||= Utils.lines('./01.input.txt').map {|l| Integer(l)}
end

def frequency_sum
  lines.reduce(0) {|a, v| a + v}
end

def part_two
  sum = 0
  frequencies = lines.map {|l| sum += l; sum}

  while true
    lines.each do |line|
      sum += line
      return sum if frequencies.include?(sum)
    end
  end
end

puts "Part 1: #{frequency_sum}"
puts "Part 2: #{part_two}"
