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

REGISTERS = 6

class Instruction
  attr_accessor :use_register_a, :use_register_b, :fn, :possible_codes, :impossible_codes
  def initialize(use_register_a, use_register_b, &block)
    @use_register_a = use_register_a
    @use_register_b = use_register_b
    @fn = block
    @possible_codes = []
    @impossible_codes = []
  end

  def apply(registers, operation, clone = false)
    registers = registers.dup if clone
    input_a = operation[0]
    input_b = operation[1]
    input_a = registers[input_a] if @use_register_a
    input_b = registers[input_b] if @use_register_b
    result = @fn.call(input_a, input_b)
    registers[operation[2]] = result
    registers
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

State = Struct.new(:registers, :ip, :instructions, :iteration)
InstructionInstance = Struct.new(:definition, :values, :symbol)

def parse_data(data, registers = REGISTERS.times.map {0})
  instruction_pointer = /#ip (\d+)/.match(data[0])
  instruction_pointer = instruction_pointer[1].to_i

  instructions = data[1..-1].map do |i|
    extracted = /(\w+) (\d+) (\d+) (\d+)/.match(i)
    InstructionInstance.new(
      INSTRUCTIONS[extracted[1].to_sym],
      [extracted[2].to_i, extracted[3].to_i, extracted[4].to_i],
      extracted[1],
    )
  end

  State.new(registers, instruction_pointer, instructions, 0)
end

def apply(state, logging = false)
  puts "State Iteration: #{state.iteration}" if logging
  state.iteration += 1
  instruction = state.instructions[state.registers[state.ip]]

  puts "  Instruction: #{state.registers[state.ip]} - #{instruction.symbol} #{instruction.values}" if logging

  instruction.definition.apply(state.registers, instruction.values)
  puts "  Registers: #{state.registers}" if logging

  if should_continue?(state, state.registers[state.ip] + 1)
    state.registers[state.ip] += 1
    return true
  end

  return false
end

def should_continue?(state, ip_value = state.registers[state.ip])
  ip_value < state.instructions.length
end


part "1 Example" do
  example_input = """#ip 0
seti 5 0 1
seti 6 0 2
addi 0 1 0
addr 1 2 3
setr 1 0 0
seti 8 0 4
seti 9 0 5""".split("\n")

  state = parse_data(example_input)
  assert_equal(0, state.ip, "state.ip")
  assert_equal(7, state.instructions.length, "instructions.length")
  assert_equal(INSTRUCTIONS[:seti], state.instructions[0].definition, "instructions[:seti]")
  assert_equal([5, 0, 1], state.instructions[0].values, "instructions[:seti].values")

  assert_equal(INSTRUCTIONS[:addr], state.instructions[3].definition, "instructions[:seti]")
  assert_equal([1, 2, 3], state.instructions[3].values, "instructions[:seti].values")

  while true
    break unless apply(state, false)
  end

  assert_equal([6, 5, 6, 0, 0, 9], state.registers, "final registers")
end

part "1" do
  state = parse_data(input)

  while true
    break unless apply(state, true)
  end

  assert_equal([1152, 956, 256, 956, 1, 955], state.registers, "final registers")
end

# part "2" do
#   # state = parse_data(input, [1, 0, 0, 0, 0, 0])

#   # Seed - [0, 1, 9, 10551356, 1, 10551355]
#   # Seed - [0, 2, 9, 10551356, 1, 10551355]
#   state = parse_data(input, [0, 35, 9, 10551356, 1, 10551355])

#   while true
#     break unless apply(state, true)
#   end

#   # Sum of all factors of 10551355
#   assert_equal([1152, 956, 256, 956, 1, 955], state.registers, "final registers")
# end
