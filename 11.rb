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

class FuelCell
  attr_accessor :x, :y, :serial, :power_level, :rack_id
  def initialize(x, y, serial)
    @x = x
    @y = y
    @serial = serial
    @rack_id = x + 10
    @power_level = @rack_id * y
    @power_level += serial
    @power_level *= @rack_id
    @power_level = @power_level.to_s.reverse[2]&.to_i || 0
    @power_level -= 5
  end

  def grid_power(grid, size = 3)
    return 0 if @x > grid.length - size
    return 0 if @y > grid[0].length - size
    out = 0
    (@x...@x+size).each do |tx|
      (@y...@y+size).each do |ty|
        binding.pry if grid[tx][ty].nil?
        out += grid[tx][ty].power_level
      end
    end
    out
  end

  def variable_grid_power(grid)
    (1..300-[@x, @y].max).map {|size| [size, grid_power(grid, size)]}.sort_by(&:last).last
  end
end

def make_grid(width, height, serial)
  grid = []
  (0...width).each do |x|
    grid[x] = []
    (0...height).each do |y|
      grid[x] << FuelCell.new(x, y, serial)
    end
  end
  grid
end

part 1 do
  assert_equal(4, FuelCell.new(3, 5, 8).power_level, "example 1")
  assert_equal(-5, FuelCell.new(122, 79, 57).power_level, "example 2")
  assert_equal(0, FuelCell.new(217, 196, 39).power_level, "example 3")
  assert_equal(4, FuelCell.new(101, 153, 71).power_level, "example 4")

  grid = make_grid(300, 300, 42)
  square = grid.flatten.map{|fc| [fc.grid_power(grid), fc]}.sort_by{|k,v|k}.last.last

  assert_equal(21, square.x, "example square x")
  assert_equal(61, square.y, "example square y")

  grid = make_grid(300, 300, 8979)
  square = grid.flatten.map{|fc| [fc.grid_power(grid), fc]}.sort_by{|k,v|k}.last.last

  puts "  #{square.x},#{square.y}"
end

part 2 do

  grid = make_grid(300, 300, 18)
  binding.pry
  square = grid.flatten.map{|fc| [fc.variable_grid_power(grid), fc]}.sort_by{|k, _|k[0][1]}.last
  binding.pry
end
