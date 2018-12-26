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

TREE = '|'
EMPTY = '.'
LUMBER = '#'

def parse(raw)
  out = []
  raw.each_with_index do |line|
    out << line.strip.chars
  end
  out
end

def count_around(data, x, y, char)
  out = 0
  (x-1..x+1).each do |cx|
    (y-1..y+1).each do |cy|
      next if cx == x && cy == y
      next if cy < 0 || cy >= data.length
      next if cx < 0 || cx >= data[cy].length
      out += 1 if data[cy][cx] == char
    end
  end
  out
end

def process(data)
  out = Array.new(data.length)
  out.each_with_index {|_, i| out[i] = Array.new(data[0].length)}

  data.each_with_index do |row, y|
    row.each_with_index do |plot, x|
      # binding.pry if x == 6
      case plot
      when EMPTY
        trees = count_around(data, x, y, TREE)
        out[y][x] = trees >= 3 ? TREE : EMPTY
      when TREE
        lumbers = count_around(data, x, y, LUMBER)
        out[y][x] = lumbers >= 3 ? LUMBER : TREE
      when LUMBER
        lumbers = count_around(data, x, y, LUMBER)
        trees = count_around(data, x, y, TREE)
        out[y][x] = (lumbers >= 1 && trees >= 1) ? LUMBER : EMPTY
      else
        raise "unknown plot #{plot} / #{row}"
      end
    end
  end
  out
end

part "1 (Example)" do
  example_input = """.#.#...|#.
.....#|##|
.|..|...#.
..|#.....#
#.#|||#|#|
...#.||...
.|....|...
||...#|.#|
|.||||..|.
...#.|..|.""".split("\n")

  current = parse(example_input)

  10.times do
    current = process(current)
  end

  trees = current.flatten.count {|c| c == '|'}
  lumbers = current.flatten.count {|c| c == '#'}
  assert_equal(1147, trees * lumbers, "muli")
end

part "1" do
  current = parse(input)

  10.times do |counter|
    current = process(current)
  end

  trees = current.flatten.count {|c| c == '|'}
  lumbers = current.flatten.count {|c| c == '#'}
  assert_equal(483840, trees * lumbers, "muli")
end

part "2" do
  current = parse(input)
  history = [].to_set
  found = false
  i = 0
  ITER = 1000000000

  until i == ITER
    current = process(current)
    stringd = current.flatten.join
    i += 1

    if !found && history.include?(stringd)
      i = ITER - (ITER % i)
      found = true
    else
      history << stringd
    end
  end

  trees = current.flatten.count {|c| c == TREE}
  lumbers = current.flatten.count {|c| c == LUMBER}

  assert_equal(219919, trees * lumbers, "muli")
end
