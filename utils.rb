require 'net/http'
require 'uri'

module Utils
  def test(value, expect, input)
    input = input.to_s.gsub("\n", "\\n").gsub("\t", "\\t")
    if input.length > 60
      input = input.slice(0,57) + '...'
    end

    outcome = expect.nil? ? '?' : (value == expect ? '✓' : 'x')
    expect = '""' if expect == ""
    expected = expect.nil? ? '' : ", Expected: #{expect}"

    puts "  #{outcome} Value: #{value}#{expected}, Input: #{input}"
    return value
  end

  def test_call(method, expect, *args)
    result = self.send(method, *args)
    test(result, expect, "#{method}(#{args.to_s[1...-1]})")
  end

  def input
    @input ||= $<.map(&:to_s).map(&:strip)
    return @input[0] if @input.length == 1 # is this one line?
    @input.dup # prevents previous alteration to array
  end

  def part(num, &block)
    puts "Part #{num}:"
    yield
    puts ""
  end
end
