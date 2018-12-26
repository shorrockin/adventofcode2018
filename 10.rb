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
  @input ||= $<.map(&:to_s).map(&:strip)
  @input.length == 1 ? @input[0].dup : @input.dup # prevents alterations to source
end

def part(num, &block)
  puts "Part #{num}:".green; yield; puts ""
end
# Advent Boilerplate End
require 'io/console'

FORMAT = /position=<\s*(-?\d+),\s*(-?\d+)> velocity=<\s*(-?\d+),\s*(-?\d+)>/

example_input = """position=< 9,  1> velocity=< 0,  2>
position=< 7,  0> velocity=<-1,  0>
position=< 3, -2> velocity=<-1,  1>
position=< 6, 10> velocity=<-2, -1>
position=< 2, -4> velocity=< 2,  2>
position=<-6, 10> velocity=< 2, -2>
position=< 1,  8> velocity=< 1, -1>
position=< 1,  7> velocity=< 1,  0>
position=<-3, 11> velocity=< 1, -2>
position=< 7,  6> velocity=<-1, -1>
position=<-2,  3> velocity=< 1,  0>
position=<-4,  3> velocity=< 2,  0>
position=<10, -3> velocity=<-1,  1>
position=< 5, 11> velocity=< 1, -2>
position=< 4,  7> velocity=< 0, -1>
position=< 8, -2> velocity=< 0,  1>
position=<15,  0> velocity=<-2,  0>
position=< 1,  6> velocity=< 1,  0>
position=< 8,  9> velocity=< 0, -1>
position=< 3,  3> velocity=<-1,  1>
position=< 0,  5> velocity=< 0, -1>
position=<-2,  2> velocity=< 2,  0>
position=< 5, -2> velocity=< 1,  2>
position=< 1,  4> velocity=< 2,  1>
position=<-2,  7> velocity=< 2, -2>
position=< 3,  6> velocity=<-1, -1>
position=< 5,  0> velocity=< 1,  0>
position=<-6,  0> velocity=< 2,  0>
position=< 5,  9> velocity=< 1, -2>
position=<14,  7> velocity=<-2,  0>
position=<-3,  6> velocity=< 2, -1>""".split("\n")

class Position
  attr_accessor :x, :y, :vx, :vy
  def initialize(match)
    @x = match[1].to_i
    @y = match[2].to_i
    @vx = match[3].to_i
    @vy = match[4].to_i
  end

  def at(time)
    out = self.dup
    out.x = out.x + (out.vx * time)
    out.y = out.y + (out.vy * time)
    out
  end
end

def to_structure(input)
  input.map {|l| Position.new(FORMAT.match(l))}
end

def draw_at(positions, time)
  positions = positions.map {|i| i.at(time)}
  min_x = positions.map(&:x).min
  min_y = positions.map(&:y).min
  max_x = positions.map(&:x).max
  max_y = positions.map(&:y).max
  positions = positions.map{|i| [[i.x, i.y], i]}.to_h

  return false if (max_x - min_x) > 300
  return false if (max_y - min_y) > 100

  (min_y..max_y).each do |y|
    (min_x..max_x).each do |x|
      character = "."
      character = "#" unless positions[[x, y]].nil?
      putc character
    end
    putc "\n"
  end

  putc "\n"
  true
end

part 1 do
  example_input.each_with_index do |l, index|
    assert_equal(false, FORMAT.match(l).nil?, "FORMAT.match(#{index})")
  end

  example = to_structure(example_input)
  assert_equal(9, example[0].x, "example[0].x")
  assert_equal(0, example[1].y, "example[1].y")
  assert_equal(-1, example[2].vx, "example[2].vx")
  assert_equal(-1, example[3].vy, "example[3].vy")

  input_structure = to_structure(input)

  continue = 'y'
  time = 0

  while continue == 'y'
    if draw_at(input_structure, time)
      continue = STDIN.getch
    end
    time += 1
  end

  puts "Time: #{time - 1}"
end
