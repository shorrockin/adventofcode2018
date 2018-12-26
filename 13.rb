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

class String
  def indexes(needle)
    found = []
    current_index = -1
    while current_index = index(needle, current_index+1)
      found << current_index
    end
    found
  end
end

example_input = """
/->-\\
|   |  /----\\
| /-+--+-\\  |
| | |  | v  |
\\-+-/  \\-+--/
  \\---->-/   """.strip.split("\n")

example_input_2 = """
/>-<\\
|   |
| /<+-\\
| | | v
\\>+</ |
  |   ^
  \\<->/""".strip.split("\n")

def as_map(input)
  input.map do | i|
    i
    .gsub(">", "-")
    .gsub("<", "-")
    .gsub("^", "|")
    .gsub("v", "|")
  end
end

def extract_cars(input)
  cars = []
  input.each_with_index do |line, index|
    ys = line.indexes(">")
    ys = ys + line.indexes("<")
    ys = ys + line.indexes("^")
    ys = ys + line.indexes("v")
    ys.each {|y| cars << [y, index, line[y], "l"]}
  end
  cars
end

def move_cars(map, cars, tick = 0)
  cars = cars.sort_by {|c| [c[1], c[0]] }

  cars.each_with_index do |car, index|
    next if car[index].nil?

    map_spot = map[car[1]][car[0]]

    cars[index] = case [map_spot, car[2]]
    when ["+", ">"]
      case car[3]
      when "l"
        [car[0], car[1] - 1, "^", "s"]
      when "s"
        [car[0] + 1, car[1], car[2], "r"]
      when "r"
        [car[0], car[1] + 1, "v", "l"]
      else
        raise "Unable to handle #{car} on #{map_spot} (tick: #{tick})"
      end

    when ["+", "<"]
      case car[3]
      when "l"
        [car[0], car[1] + 1, "v", "s"]
      when "s"
        [car[0] - 1, car[1], car[2], "r"]
      when "r"
        [car[0], car[1] - 1, "^", "l"]
      else
        raise "Unable to handle #{car} on #{map_spot} (tick: #{tick})"
      end

    when ["+", "^"]
      case car[3]
      when "l"
        [car[0] - 1, car[1], "<", "s"]
      when "s"
        [car[0], car[1] - 1, car[2], "r"]
      when "r"
        [car[0] + 1, car[1], ">", "l"]
      else
        raise "Unable to handle #{car} on #{map_spot} (tick: #{tick})"
      end

    when ["+", "v"]
      case car[3]
      when "l"
        [car[0] + 1, car[1], ">", "s"]
      when "s"
        [car[0], car[1] + 1, car[2], "r"]
      when "r"
        [car[0] - 1, car[1], "<", "l"]
      end

    when ["-", ">"]
      [car[0] + 1, car[1], car[2], car[3]]
    when ["-", "<"]
      [car[0] - 1, car[1], car[2], car[3]]

    when ["|", "v"]
      [car[0], car[1] + 1, car[2], car[3]]
    when ["|", "^"]
      [car[0], car[1] - 1, car[2], car[3]]

    when ["/", "v"]
      [car[0] - 1, car[1], "<", car[3]]
    when ["/", "^"]
      [car[0] + 1, car[1], ">", car[3]]
    when ["/", ">"]
      [car[0], car[1] - 1, "^", car[3]]
    when ["/", "<"]
      [car[0], car[1] + 1, "v", car[3]]

    when ["\\", "v"]
      [car[0] + 1, car[1], ">", car[3]]
    when ["\\", "^"]
      [car[0] - 1, car[1], "<", car[3]]
    when ["\\", ">"]
      [car[0], car[1] + 1, "v", car[3]]
    when ["\\", "<"]
      [car[0], car[1] - 1, "^", car[3]]

    else
      raise "Unable to handle #{car} on #{map_spot} (tick: #{tick})"
    end

    crashed = cars.group_by {|c| "#{c[0]},#{c[1]}"}.select{|k,v| v.length > 1}
    crashed.each do |k, v|
      v.each do |c|
        puts "  Car #{c[0]},#{c[1]} has crashed..."
        cars.delete(c)
      end
    end
  end
  cars
end

def print(map, cars)
  map.each_with_index do |line, line_num|
    line = line.dup
    cars.each do |car|
      if line_num == car[1]
        if "<>^v".chars.include?(line[car[0]])
          line[car[0]] = "X"
        else
          line[car[0]] = car[2]
        end
      end
    end
    puts "#{line_num}\t#{line}"
  end
end

def first_crash(map, cars)
  crashed = {}
  tick = 0

  while cars.select{|c| !c.nil?}.length > 1
    cars = move_cars(map, cars, tick)
    tick += 1
    # print(map, cars)
  end

  puts "  Remaining: #{cars}"
end

part 1 do
  map = as_map(input)
  cars = extract_cars(input)
  first_crash(map, cars)
end

part "1 Example" do
  map = as_map(example_input)
  cars = extract_cars(example_input)

  assert_equal([2, 0, ">", "l"], cars[0], "cars[0]")
  assert_equal([9, 3, "v", "l"], cars[1], "cars[1]")

  cars = move_cars(map, cars)
  assert_equal([3, 0, ">", "l"], cars[0], "moved cars[0]")
  assert_equal([9, 4, "v", "l"], cars[1], "moved cars[1]")

  first_crash(map, cars)
end

part "2 Example" do
  map = as_map(example_input_2)
  cars = extract_cars(example_input_2)
  first_crash(map, cars)
end
