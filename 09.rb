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

class Marble
  attr_accessor :value, :left, :right
  def initialize(value, left = self, right = self)
    @value = value
    @left = left
    @right = right
  end

  def append(value)
    new_marble = Marble.new(value, self, @right)

    @right.left = new_marble
    @right = new_marble
    new_marble
  end

  def remove
    @left.right = @right
    @right.left = @left
    @right
  end
end


class Game
  attr_reader :num_players, :last_worth, :marbles, :current, :scores, :turn, :scoring_multiple
  def initialize(num_players, last_worth, scoring_multiple = 23)
    @num_players = num_players
    @last_worth = last_worth
    @scores = (0...num_players).map{0}
    @turn = -1
    @scoring_multiple = scoring_multiple
    @finished = false
    @current = Marble.new(0)
  end

  def winning_score
    @scores.max
  end

  def place
    @turn += 1
    next_value = @turn + 1

    if next_value % scoring_multiple == 0
      next_marble = Marble.new(next_value)
      @scores[@turn % @scores.length] += next_marble.value
      to_remove = (0...7).reduce(@current) {|i, _|i.left}
      @scores[@turn % @scores.length] += to_remove.value
      @current = to_remove.remove
    else
      @current = @current.right.append(next_value)
    end

    @finished = (next_value == last_worth)
  end
end

def winning_score(num_players, last_worth)
  game = Game.new(num_players, last_worth)
  while !game.place; end
  game.winning_score
end

part 1 do
  assert_call(32, :winning_score, 9, 25)
  assert_call(8317, :winning_score, 10, 1618)
  assert_call(146373, :winning_score, 13, 7999)
  assert_call(2764, :winning_score, 17, 1104)
  assert_call(54718, :winning_score, 21, 6111)
  assert_call(37305, :winning_score, 30, 5807)
  log_call(:winning_score, 493, 71863)
end

part 2 do
  log_call(:winning_score, 493, 71863 * 100)
end
