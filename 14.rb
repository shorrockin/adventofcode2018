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

class Recipe
  attr_accessor :score, :previous, :next, :idx, :head
  def initialize(score, previous, idx = 0)
    @score = score
    @idx = idx

    unless previous.nil?
      @previous = previous
      @previous.next = self
      @idx = @previous.idx + 1
      @head = @previous.head
    else
      @head = self
    end
  end

  def next_or_head
    @next || @head
  end

  def to_s
    return @score if @next.nil?
    @score.to_s + @next.to_s
  end

  def to_s_back(length)
    cur = self
    length.times.map do
      if cur
        s = cur.score.to_s
        cur = cur.previous
        s
      else
        ""
      end
    end.join.reverse
  end
end

def score_at(recipes, current, after)
  (0...after+10).each do
    new_score = current.map do |c|
      recipes[c].to_i
    end.sum

    recipes = recipes + new_score.to_s

    current = current.map do |c|
      movement = recipes[c].to_i + 1
      (c + movement) % recipes.length
    end
  end

  recipes[after...after+10].to_s
end

def score_at2(recipes, current, after)
  while (recipes.idx != (after + 9)) do
    new_score = current.map do |c|
      c.score.to_i
    end.sum

    new_score.to_s.chars.each do |s|
      recipes = Recipe.new(s, recipes)
    end

    current = current.map do |c|
      movement = c.score.to_i + 1
      movement.times {c = c.next_or_head}
      c
    end
  end


  10.times.map do
    score = recipes.score
    recipes = recipes.previous
    score.to_s
  end.join.reverse
end

def recipes_at(recipes, current, at)
  iterations = 0

  while !recipes.include?(at) do
    new_score = current.map do |c|
      recipes[c].to_i
    end.sum

    new_score.to_s.chars.map(&:to_i).each do |i|
      recipes = recipes * 100
      recipes += i
    end

    current = current.map do |c|
      movement = recipes[c].to_i + 1
      (c + movement) % recipes.length
    end

    iterations += 1
    puts "#{iterations}" if iterations % 100000 == 0
  end

  return recipes.size - at.length
end

def recipes_at3(recipes, current, at)
  at = at.chars.map(&:to_i)
  match_at = nil
  match_at2 = nil

  while (match_at != at && match_at2 != at) do
    new_score = current.map do |c|
      recipes[c].to_i
    end.sum

    recipes = recipes + new_score.to_s.chars.map(&:to_i)

    current = current.map do |c|
      movement = recipes[c].to_i + 1
      (c + movement) % recipes.length
    end

    match_at = recipes[recipes.length - at.length, at.length]
    match_at2 = recipes[recipes.length - at.length - 1, at.length]
  end
binding.pry
  return recipes.length - at.length
end


def recipes_at2(recipes, current, at)
  match_at = nil

  while (match_at != at) do
    new_score = current.map do |c|
      recipes[c]
    end.sum

    recipes = recipes + new_score.to_s.chars.map(&:to_i)

    current = current.map do |c|
      movement = recipes[c] + 1
      (c + movement) % recipes.length
    end

    match_at = recipes[recipes.length - at.length, at.length]
  end

  return recipes.length - at.length
end

part "2" do
  start = "37"
  current = [0, 1]

  assert_equal(9, recipes_at(start, current, "51589"), "51589")
  assert_equal(5, recipes_at(start, current, "01245"), "01245")
  assert_equal(1, recipes_at(start, current, "71"), "71")
  assert_equal("?", recipes_at(start, current, "598701"), "598701")
end

part "2b" do
  # tail = Recipe.new(7, Recipe.new(3, nil))
  # current = [tail.previous, tail]
  # assert_equal(9, recipes_at2(tail, current, "51589"), "51589")

  # tail = Recipe.new(7, Recipe.new(3, nil))
  # current = [tail.previous, tail]
  # assert_equal(5, recipes_at2(tail, current, "01245"), "01245")

  # tail = Recipe.new(7, Recipe.new(3, nil))
  # current = [tail.previous, tail]
  # assert_equal("?", recipes_at2(tail, current, "598701"), "598701")
end

part "2c" do
  # start = [3, 7]
  # current = [0, 1]

  # assert_equal(9, recipes_at3(start, current, "51589"), "51589")
  # assert_equal(5, recipes_at3(start, current, "01245"), "01245")
  # assert_equal("?", recipes_at3(start, current, "598701"), "598701")
end


part "1b" do
  # tail = Recipe.new(7, Recipe.new(3, nil))
  # current = [tail.previous, tail]
  # assert_equal("5158916779", score_at2(tail, current, 9), "9")

  # tail = Recipe.new(7, Recipe.new(3, nil))
  # current = [tail.previous, tail]
  # assert_equal("2776141917", score_at2(tail, current, 598701), "598701")
end

part "1" do
  # start = "37"
  # current = [0, 1]
  # assert_equal("2776141917", score_at(start, current, 598701), "9")
end
