require './boilerplate'

class Instruction
  attr_accessor :use_register_a, :use_register_b, :fn, :possible_codes, :impossible_codes
  def initialize(use_register_a, use_register_b, &block)
    @use_register_a   = use_register_a
    @use_register_b   = use_register_b
    @fn               = block
    @possible_codes   = []
    @impossible_codes = []
  end

  def apply(registers, operation, clone = false)
    registers = registers.dup if clone
    input_a   = operation[0]
    input_b   = operation[1]
    input_a   = registers[input_a] if @use_register_a
    input_b   = registers[input_b] if @use_register_b
    result    = @fn.call(input_a, input_b)
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
  :setr => Instruction.new(true, false) {|a, b| a},
  :seti => Instruction.new(false, false) {|a, b| a},
  :gtir => Instruction.new(false, true) {|a, b| a > b ? 1 : 0},
  :gtri => Instruction.new(true, false) {|a, b| a > b ? 1 : 0},
  :gtrr => Instruction.new(true, true) {|a, b| a > b ? 1 : 0},
  :eqir => Instruction.new(false, true) {|a, b| a == b ? 1 : 0},
  :eqri => Instruction.new(true, false) {|a, b| a == b ? 1 : 0},
  :eqrr => Instruction.new(true, true) {|a, b| a == b ? 1 : 0},
}

REGISTERS = 6

InstructionInstance = Struct.new(:definition, :values, :symbol, :annot)

class Registers
  attr_accessor :data
  def initialize(initial)
    @data = initial
  end

  def get(register)
    @data[register] || 0
  end

  def set(register, value)
    @data[register] = value
  end

  def include?(register)
    @data.include?(register)
  end

  def to_s
    @data.to_s
    # "[" + @data.sort_by {|k, v| k}.map {|k, v| "#{k}=>#{v}"}.join(", ") + "]"
  end
end

class State
  include Loggable
  attr_accessor :registers, :ip, :instructions, :iteration
  attr_accessor :history

  def initialize(input, logging: false, registers: REGISTERS.times.map{0})
    @logging = logging
    @iteration = 0
    @registers = registers
    @history = []

    data = input.map(&:strip)

    @ip = /#ip (\d+)/.match(data[0])
    @ip = @ip[1].to_i

    @instructions = data[1..-1].map do |i|
      extracted = /(\w+) (\d+) (\d+) (\d+)(\s+#\s+(.*))?/.match(i)
      InstructionInstance.new(
        INSTRUCTIONS[extracted[1].to_sym],
        [extracted[2].to_i, extracted[3].to_i, extracted[4].to_i],
        extracted[1],
        extracted[6]&.strip,
      ) unless extracted.nil?
    end.compact
  end

  def apply
    if @registers[@ip] == 28
      binding.pry if @history.include?(@registers[4])
      puts "#{@iteration}\t#{@registers.to_s} (val: #{@history.include?(@registers[4]) ? @registers[4] : @registers[4].to_s.green})"
      @history << @registers[4]
    end

    instruction = @instructions[@registers[@ip]]
    # log "##{@iteration} iteration" do
      @iteration += 1

      # log "before:", @registers.to_s
      # if instruction.annot
      #   log "instruction (#{@registers[@ip].to_s.red}):", instruction.annot.green
      # else
      #   log "instruction (#{@registers[@ip].to_s.red}):", instruction.symbol, instruction.values
      # end

      # log "  (#{instruction.annot.to_s.green})" if instruction.annot
      instruction.definition.apply(@registers, instruction.values)
      # log "result:", @registers.to_s

      if should_continue?(@registers[@ip] + 1)
        # log("ip register #{@ip.to_s.red} = #{@registers[@ip]} + 1")
        @registers[@ip] =  @registers[@ip] + 1
        return true
      end

      return false
    # end
  end

  def should_continue?(ip_value = @registers[@ip])
    ip_value < @instructions.length
  end
end

part "1" do
  state = State.new(input, logging: false, registers: [9079325, 0, 0, 0, 0, 0])
  while true
    break unless state.apply
  end
  assert_call_on(state, 1848, :iteration)
end

part "2" do
  break
  # 1846   [0=>0, 1=>1, 2=>1, 3=>28, 4=>9079325, 5=>1]
  # 252918 [0=>0, 1=>1, 2=>1, 3=>28, 4=>1293036, 5=>139]
  # 288446 [0=>0, 1=>1, 2=>1, 3=>28, 4=>637585, 5=>19]
  # 305984 [0=>0, 1=>1, 2=>1, 3=>28, 4=>4545250, 5=>9]

  # 33495 too low?
  state = State.new(input, logging: false, registers: [0, 0, 0, 0, 0, 0])
  while true
    break unless state.apply
  end
  assert_call_on(state, 1848, :iteration)

end
