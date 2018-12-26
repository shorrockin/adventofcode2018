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

class Plant
  attr_accessor :number, :generation, :plant, :next, :previous
  def initialize(number, generation, plant)
    @number = number
    @generation = generation
    @plant = plant
  end

  def append(plant)
    @next = Plant.new(@number + 1, @generation, plant)
    @next.previous = self
    @next
  end

  def head
    return self if @previous.nil?
    @previous.head
  end

  def tail
    return self if @next.nil?
    @next.tail
  end

  def next_plant
    return self if plant == '#'
    map(self) do |plant|
      return plant if plant.plant == '#'
    end
    self
  end

  def last_plant
    last = self if plant == '#'
    map(self) do |plant|
      last = plant if plant.plant == '#'
    end
    last
  end

  def prune
    head = self.head.next_plant
    head.left.left.previous = nil # buffer left by two
    head.last_plant.right.right.next = nil # buffer by two right
    head.left.left
  end

  def left
    return @previous unless @previous.nil?
    @previous = Plant.new(@number - 1, @generation, '.')
    @previous.next = self
    @previous
  end

  def right
    return @next unless @next.nil?
    append('.')
  end

  def applies?(rule)
    rule == [left.left.plant, left.plant, @plant, @next&.plant || '.', @next&.next&.plant || '.']
  end
end

Rule = Struct.new(:rule, :on_match)

def create_state(initial)
  initial = /initial state: (.*)/.match(initial)[1]
  initial.chars.reduce(Plant.new(-1, 0, '.')) {|previous, next_char| previous.append(next_char)}.prune
end

def create_rules(rules)
  rules.map do |rule|
    match = /(.*) => (.*)/.match(rule)
    Rule.new(match[1].chars, match[2])
  end
end

def map(start)
  out = []
  while true
    result = yield start
    out << result
    break if start.next.nil?
    start = start.next
  end
  out
end

def next_generation(start, rules)
  applies = rules.select {|rule| start.applies?(rule.rule)}
  applies = applies.length == 1 ? applies[0] : nil
  at = Plant.new(start.number, start.generation + 1, applies.nil? ? '.' : applies.on_match)

  map(start.right) do |plant|
    applies = rules.select {|rule| plant.applies?(rule.rule)}
    applies = applies.length == 1 ? applies[0] : nil
    at = at.append(applies.nil? ? '.' : applies.on_match)
  end

  at.prune
end

def as_string(plant)
  map(plant) {|m| m.plant}.join
end

def sum(plant)
  map(plant) {|m| m.plant == '#' ? m.number : 0}.sum
end

part "1 (Example)" do
  root = create_state("initial state: #..#.#..##......###...####..#.#..##......###...###")

  rules = create_rules([
    "...## => #",
    "..#.. => #",
    ".#... => #",
    ".#.#. => #",
    ".#.## => #",
    ".##.. => #",
    ".#### => #",
    "#.#.# => #",
    "#.### => #",
    "##.#. => #",
    "##.## => #",
    "###.. => #",
    "###.# => #",
    "####. => #"
  ])

  assert_equal(true, root.next.applies?('...#.'.chars), "applies?('..#..')")
  assert_equal(false, root.applies?('..#.#'.chars), "applies?('..#.#')")
  assert_equal(0, root.next_plant.number, "next_plant(root)")
  assert_equal('...##', rules[0].rule.join, "rule[0].rule")
  assert_equal('#', rules[0].on_match, "rule[0].on_match")
  assert_equal('..#..#.#..##......###...####..#.#..##......###...###..', as_string(root), "map[input]")

  root = create_state('initial state: #..#.#..##......###...###')
  assert_equal('..#...#....#.....#..#..#..#..', as_string(next_generation(root, rules)), "map[input_gen_2]")

  while root.generation != 20
    root = next_generation(root, rules)
    # puts "#{root.generation}: #{as_string(root)}"
  end

  assert_equal('..#....##....#####...#######....#.#..##..', as_string(root), "map[input_gen_20]")
  assert_equal(325, sum(root), "sum[input]")
end

part "1" do
  root = create_state(input[0])
  root.right.right
  rules = create_rules(input[2, input.length])

  while root.generation != 20
    root = next_generation(root, rules)
    puts "#{root.generation}: #{as_string(root)}"
  end

  log_call(:sum, root)
end

part "2" do
  root = create_state(input[0])
  root.right.right
  rules = create_rules(input[2, input.length])
  previous = []
  delta = 0

  while root.generation != 300
    root = next_generation(root, rules)
    str = as_string(root)

    puts "#{root.generation}: #{sum(root)} #{delta - sum(root)}"
    delta = sum(root)

    previous << str
  end

  log_call(:sum, root)
end
