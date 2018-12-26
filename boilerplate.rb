# Advent Boilerplate Start
require 'pry'

class String
  def colorize(color_code); "\e[#{color_code}m#{self}\e[0m"; end
  def red; colorize(31); end
  def green; colorize(32); end
  def yellow; colorize(33); end
  def blue; colorize(34); end
end

module Loggable
  attr_accessor :logging, :log_depth

  def log(s, *args);
    @log_depth ||= "  "
    out = nil

    puts "#{@log_depth}#{s} #{args.map(&:to_s).join(", ")}" if @logging;

    if block_given?
      original_depth = @log_depth
      @log_depth = @log_depth + "  "
      begin
        out = yield
      ensure
        @log_depth = original_depth
      end
    end

    return out
  end
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
  assert_call_on(self, expect, *args)
end

def log_call(method, *args)
  log_call_on(self, method, *args)
end

def assert_call_on(target, expect, *args)
  log_call_on(target, *args) {|m, r, desc| assert_equal(expect, r, "#{m}(#{desc})")}
end

def log_call_on(target, method, *args)
  arg_description = args.to_s[1...-1]
  arg_description = "..." if arg_description.length > 10
  method, arg_description = method if method.is_a?(Array)

  result = target.send(method, *args)
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
