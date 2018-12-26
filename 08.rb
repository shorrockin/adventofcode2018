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

def example_input
  "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2".split(" ").map(&:strip).map(&:to_i)
end

def parsed_input
  input.split(" ").map(&:strip).map(&:strip).map(&:to_i)
end

class Node
  attr_reader :child_nodes_count
  attr_reader :metadata_count
  attr_reader :children
  attr_reader :metadata

  def initialize(iterator)
    @child_nodes_count = iterator.next || 0
    @metadata_count = iterator.next || 0
    parse(iterator)
  end

  def parse(iterator)
    @children = (0...@child_nodes_count).map {Node.new(iterator)}
    @metadata = (0...@metadata_count).map {iterator.next}
  end

  def sum_metadata
    @metadata.sum + @children.map(&:sum_metadata).sum
  end

  def value
    return @metadata.sum if @child_nodes_count == 0

    @metadata.map do |index|
      index == 0 ? 0 : (@children[index - 1]&.value || 0)
    end.sum
  end
end

class Iterator
  attr_reader :data
  attr_reader :index
  def initialize(data)
    @data = data
    @index = 0
  end

  def next
    @index += 1
    @data[index - 1]
  end
end

part 1 do
  assert_equal(16, example_input.length, "example_input.length")
  assert_equal(7, parsed_input.first, "parsed_input.first")
  assert_equal(2, parsed_input.last, "parsed_input.last")

  example_iterator = Iterator.new([1, 2])
  assert_equal(1, example_iterator.next, "example_iterator.next (first)")
  assert_equal(2, example_iterator.next, "example_iterator.next (second)")
  assert_equal(nil, example_iterator.next, "example_iterator.next (exausted)")

  def assert_node(child_count, metadata_count, metadata, node, name)
    assert_equal(child_count, node.child_nodes_count, "#{name}.child_nodes_count")
    assert_equal(metadata_count, node.metadata_count, "#{name}.metadata_count")
    assert_equal(child_count, node.children.length, "#{name}.children.length")
    assert_equal(metadata, node.metadata, "#{name}.metadata")
    node
  end

  node_a = assert_node(2, 3, [1, 1, 2], Node.new(Iterator.new(example_input)), "node_a")
  assert_node(0, 3, [10, 11, 12], node_a.children[0], "node_b")
  node_c = assert_node(1, 1, [2], node_a.children[1], "node_c")
  assert_node(0, 1, [99], node_c.children[0], "node_d")
  assert_equal(138, node_a.sum_metadata, "node_a.sum_metadata")

  input_node = Node.new(Iterator.new(parsed_input))
  puts "  #{'-'.yellow} parsed_input.sum_metadata == #{input_node.sum_metadata}"
end

part 2 do
  node_a = Node.new(Iterator.new(example_input))
  assert_equal(66, node_a.value, "node_a.value")

  input_node = Node.new(Iterator.new(parsed_input))
  puts "  #{'-'.yellow} parsed_input.value == #{input_node.value}"
end
