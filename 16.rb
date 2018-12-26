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

Section = Struct.new(:data, :instruction, :expect)

class Instruction
  attr_accessor :use_register_a, :use_register_b, :fn, :possible_codes, :impossible_codes
  def initialize(use_register_a, use_register_b, &block)
    @use_register_a = use_register_a
    @use_register_b = use_register_b
    @fn = block
    @possible_codes = []
    @impossible_codes = []
  end

  def mark_code(code, possible)
    if possible
      @possible_codes << code unless @possible_codes.include?(code)
    else
      @impossible_codes << code unless @impossible_codes.include?(code)
    end
  end

  def codes
    @possible_codes - @impossible_codes
  end

  def apply(data, operation, clone = true)
    data = data.dup if clone
    input_a = operation[1]
    input_b = operation[2]
    input_a = data[input_a] if @use_register_a
    input_b = data[input_b] if @use_register_b
    result = @fn.call(input_a, input_b)
    data[operation[3]] = result
    data
  end
end

INSTRUCTIONS = {
  :addr => Instruction.new(true, true) {|a, b| a + b},
  :addi => Instruction.new(true, false) {|a, b| a + b},
  :mulr => Instruction.new(true, true) {|a, b| a * b},
  :muli => Instruction.new(true, false) {|a, b| a * b},
  :banr => Instruction.new(true, true) {|a, b| a & b},
  :bani => Instruction.new(true, false) {|a, b| a & b},
  :borr => Instruction.new(true, true) {|a, b| a | b},
  :bori => Instruction.new(true, false) {|a, b| a | b},
  :setr => Instruction.new(true, true) {|a, b| a},
  :seti => Instruction.new(false, true) {|a, b| a},
  :gtir => Instruction.new(false, true) {|a, b| a > b ? 1 : 0},
  :gtri => Instruction.new(true, false) {|a, b| a > b ? 1 : 0},
  :gtrr => Instruction.new(true, true) {|a, b| a > b ? 1 : 0},
  :eqir => Instruction.new(false, true) {|a, b| a == b ? 1 : 0},
  :eqri => Instruction.new(true, false) {|a, b| a == b ? 1 : 0},
  :eqrr => Instruction.new(true, true) {|a, b| a == b ? 1 : 0},
}

def parse_section(section, at = 0)
  before = /Before:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(section[at])
  opcode = /(\d+) (\d+) (\d+) (\d+)/.match(section[at + 1])
  expect = /After:\s+\[(\d+), (\d+), (\d+), (\d+)\]/.match(section[at + 2])

  before = [before[1].to_i, before[2].to_i, before[3].to_i, before[4].to_i]
  opcode = [opcode[1].to_i, opcode[2].to_i, opcode[3].to_i, opcode[4].to_i]
  expect = [expect[1].to_i, expect[2].to_i, expect[3].to_i, expect[4].to_i]

  Section.new(before, opcode, expect)
end

def parse_line(line)
  line = /(\d+) (\d+) (\d+) (\d+)/.match(line)
  [line[1].to_i, line[2].to_i, line[3].to_i, line[4].to_i]
end

def matches(section)
  matches = INSTRUCTIONS.select do |k, i|
    i.apply(section.data, section.instruction) == section.expect
  end

  INSTRUCTIONS.each do |k, i|
    i.mark_code(section.instruction[0], matches.include?(k))
  end

  matches.map {|k, _| k}.sort
end

def reset_possibilities
  INSTRUCTIONS.each {|k, i| i.possible_codes = 16.times.map(&:to_i)}
end

def instruction_by_code
  # continue until we can narrow completely
  while INSTRUCTIONS.select {|k, i| i.codes.length > 1}.length > 0
    complete = INSTRUCTIONS.select {|k, i| i.codes.length == 1}

    complete.each do |_, c|
      INSTRUCTIONS.each do |k, i|
        if i != c
          i.mark_code(c.codes[0], false)
        end
      end
    end
  end

  INSTRUCTIONS.map {|k, i| [i.codes[0], i]}.to_h
end

part "1 (Examples)" do
  assert_equal([5, 2, 3, 4], INSTRUCTIONS[:addr].apply([1, 2, 3, 4], [nil, 1, 2, 0]), ":addr")

  example_input = [
    "Before: [3, 2, 1, 1]",
    "9 2 1 2",
    "After:  [3, 2, 2, 1]",
  ]

  section = parse_section(example_input)
  assert_equal(section.expect, INSTRUCTIONS[:mulr].apply(section.data, section.instruction), ":mulr")
  assert_equal(section.expect, INSTRUCTIONS[:addi].apply(section.data, section.instruction), ":addi")
  assert_equal(section.expect, INSTRUCTIONS[:seti].apply(section.data, section.instruction), ":seti")
  assert_equal([:addi, :mulr, :seti], matches(section), "matches")
end

part "1" do
  reset_possibilities

  at = 0
  sections = []
  lines = []

  while at < input.length
    if input[at].include?("Before")
      sections << parse_section(input, at)
      at += 4
    else
      line = input[at].strip
      lines << parse_line(line) if line.length > 0
      at += 1
    end
  end

  three_or_more = sections.map do |section|
    matches(section).length >= 3 ? 1 : 0
  end.sum
  assert_equal(607, three_or_more, "sections three or more")

  by_code = instruction_by_code

  INSTRUCTIONS.each do |k, i|
    assert_equal(1, i.codes.length, "#{k} has 1 code")
  end

  assert_equal(16.times.map(&:to_i), INSTRUCTIONS.map {|k, v| v.codes}.flatten.sort, "codes")

  data = [0, 0, 0, 0]
  lines.each do |l|
    by_code[l[0]].apply(data, l, false)
  end

  p(data)
end
