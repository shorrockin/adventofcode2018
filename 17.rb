# Advent Boilerplate Start
require 'pry'

class String
  def colorize(color_code); "\e[#{color_code}m#{self}\e[0m"; end
  def red; colorize(31); end
  def green; colorize(32); end
  def yellow; colorize(33); end
end

def value_string(val)
  value_str = val
  value_str = '"' + value_str + '"' if val.is_a?(String)
  value_str = 'nil' if val.nil?
  value_str
end

def assert_equal(expect, value, description)
  puts "  #{'✔'.green} #{description} == #{value_string(value)}" if value == expect
  puts "  #{'✖'.red} #{description}: expected #{value_string(expect)}, received #{value_string(value)}" if value != expect
  value
end

def assert_call(expect, *args)
  log_call(*args) {|m, r, desc| assert_equal(expect, r, "#{m}(#{desc})")}
end

def log_call(method, *args)
  arg_description = args.to_s[1...-1]
  arg_description = "..." if arg_description.length > 10
  method, arg_description = method if method.is_a?(Array)

  result = self.send(method, *args)
  return yield method, result, arg_description if block_given?
  puts "  #{'-'.yellow} #{method}(#{arg_description}) == #{value_string(result)}"
end

def input
  @input ||= $<.map(&:to_s)
  @input.length == 1 ? @input[0].dup : @input.dup # prevents alterations to source
end

def part(num, &block)
  puts "Part #{num}:".green; yield; puts ""
end
# Advent Boilerplate End

require 'set'
require 'io/console'

INPUT_PATTERN = /([xy]?)=(\d+), ([xy]?)=(\d+)..(\d+)/

def parse_input(input)
  input.map do |line|
    match = INPUT_PATTERN.match(line); raise "invalid input: #{line}" unless match

    (match[4].to_i..match[5].to_i).map do |r|
      [match[1] == 'x' ? match[2].to_i : r, match[1] == 'x' ? r.to_i : match[2].to_i]
    end
  end.flatten(1).sort.to_set
end

def fall_from(position, clay, logging = false, water = {})
  fall_to = [position[0], position[1] + 1]
  stop_at = clay.map {|c| c[1]}.max + 1

  while fall_to[1] < stop_at
    if clay.include?(fall_to)
      puts "fell into clay at #{fall_to}, need to fill" if logging
      fall_to = [fall_to[0], fall_to[1] - 1]
      break if fill_at(fall_to, clay, logging, water)
    elsif water[fall_to] == "~"
      puts "fell into water at #{fall_to}, need to fill" if logging
      fall_to = [fall_to[0], fall_to[1] - 1]
      break if fill_at(fall_to, clay, logging, water)
    elsif water[fall_to] == "|" # fell into something already processed
      puts "fell into water stream at #{fall_to}, breaking" if logging
      break
    else
      water[fall_to] = "|"
      fall_to = [fall_to[0], fall_to[1] + 1]
      puts "fall to #{fall_to}" if logging
    end

    display(clay, water) if logging
  end

  water
end

def anything_at?(pos, clay, water)
  return clay.include?(pos) || water[pos] == "~"
end

def fill_at(position, clay, logging, water)
  # left_stop = clay.detect do |c| c[0] < position[0] && c[1] == position[1]}
  left_stop = position[0]
  while !clay.include?([left_stop - 1, position[1]]) && anything_at?([left_stop, position[1] + 1], clay, water)
    left_stop -= 1
  end

  right_stop = position[0]
  while !clay.include?([right_stop + 1, position[1]]) && anything_at?([right_stop, position[1] + 1], clay, water)
    right_stop += 1
  end

  left_stop = [left_stop, position[1]]
  right_stop = [right_stop, position[1]]

  cascade = false

  if !anything_at?([left_stop[0], position[1] + 1], clay, water)
    puts "cascade left at #{left_stop}" if logging
    fall_from(left_stop, clay, logging, water)
    cascade = true
  end

  if !anything_at?([right_stop[0], position[1] + 1], clay, water)
    puts "cascade right at #{right_stop}" if logging
    fall_from(right_stop, clay, logging, water)
    cascade = true
  end

  puts "filling at #{position} between #{left_stop} and #{right_stop}" if logging
  (left_stop[0]..right_stop[0]).each do |fill_x|
    fill_pos = [fill_x, position[1]]
    if water[fill_pos] != '~'
      puts "  filling at #{fill_pos}" if logging
      water[fill_pos] = cascade ? '|' : '~'
    end
  end

  display(clay, water) if logging

  return cascade
end

def display(clay, water)
  clay_xs = clay.sort_by(&:first)
  min_x = clay_xs.first[0] - 1
  max_x = clay_xs.last[0] + 1
  max_y = clay.sort_by(&:last).last[1] + 1

  max_y.times do |y|
    line = "#{y}\t"
    (min_x..max_x).each do |x|
      char = "."
      if clay.include?([x, y])
        char = "#"
      elsif water.include?([x, y])
        char = water[[x, y]]
      end
      line += char
    end
    puts line
  end
  puts ""

  character = STDIN.getch
  Kernel.exit if character == 'x'
end

part "1 (Example)" do
  example_input = [
    'x=495, y=2..7',
    'y=7, x=495..501',
    'x=501, y=3..7',
    'x=498, y=2..4',
    # 'x=506, y=1..2',
    'x=498, y=10..13',
    'x=504, y=10..13',
    'y=13, x=498..504',
  ]

  clay = parse_input(example_input)
  assert_equal(false, clay.include?([495, 1]), "clay @ 495, 1")
  assert_equal(true, clay.include?([495, 2]), "clay @ 495, 2")
  assert_equal(34, clay.length, "clay.length")

  water = fall_from([500, 0], clay, false)
  assert_equal(57, water.length, "water.length")
  assert_equal(29, water.map {|k, v| v == "~" ? 1 : 0}.sum, "water count")
end

part "1 (Edgecases)" do
  example_input = [
    'x=495, y=2..6',
    'y=6, x=495..501',
    'x=501, y=3..6',
    'x=498, y=2..4',
    # 'x=506, y=1..2',
    'x=450, y=8..13',
    'x=504, y=8..13',
    'y=13, x=450..504',
    'y=11, x=460..465',
    'x=460, y=8..11',
    'x=465, y=9..11',
    # 'y=9, x=460..465',
  ]

  water = fall_from([500, 0], parse_input(example_input), false)
  assert_equal("?", water.uniq.length, "water.length")
end

part "1" do
  clay = parse_input(input)
  water = fall_from([500, 0], clay, false)

  # 2196643 too high
  # 34383 too high (-4) == 34379 YAY (forgot to account for min y value)

  assert_equal("?", water.uniq.length, "water.length")
  assert_equal(29, water.map {|k, v| v == "~" ? 1 : 0}.sum, "water count")
end
