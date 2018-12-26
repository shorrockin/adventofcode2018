# Advent Boilerplate Start
require 'pry'

def test(expect, value, input = value)
  input = input.to_s.gsub("\n", "\\n").gsub("\t", "\\t")
  if input.length > 60
    input = input.slice(0,57) + '...'
  end

  check = '✓'
  outcome = expect.nil? ? '?' : (value == expect ? check : 'x')
  expect = '""' if expect == ""
  expected = (expect.nil? || outcome == check) ? '' : ", Expected: #{expect}"

  puts "  #{outcome} Value: #{value}#{expected}, Input: #{input}"
  return value
end

def test_call(expect, method, *args)
  result = self.send(method, *args)
  test(expect, result, "#{method}(#{args.to_s[1...-1]})")
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
# Advent Boilerplate End

LINE_FORMAT = /Step (\w) must be finished before step (\w) can begin./

def input_data
  @processed_input ||= process_input(input)
end

def example_data
  raw = """Step C must be finished before step A can begin.
    Step C must be finished before step F can begin.
    Step A must be finished before step B can begin.
    Step A must be finished before step D can begin.
    Step B must be finished before step E can begin.
    Step D must be finished before step E can begin.
    Step F must be finished before step E can begin."""
  process_input(raw.split("\n"))
end

def process_input(lines)
  out = Hash.new
  nodes = []

  lines.map do |line|
    match = LINE_FORMAT.match(line)
    out[match[2]] ||= []
    out[match[2]] << match[1]
    nodes.push(match[1])
    nodes.push(match[2])
  end

  nodes.each do |n|
    out[n] = [] if out[n].nil?
  end

  {path: out, nodes: nodes.uniq.sort}
end

def next_node(data, completed = [], started = [])
  data[:nodes].each do |node|
    if !completed.include?(node) && (data[:path][node] - completed).length == 0
      if !started.include?(node)
        return node
      end
    end
  end
  return nil
end

def find_path(data)
  starting = next_node(data)
  completed = [starting]

  while completed.length != data[:nodes].length
    completed << next_node(data, completed)
  end

  completed.join
end

def calculate_build_time(data, node, build_time)
  data[:nodes].index(node) + 1 + build_time
end

def duration(data, workers, build_time)
  time = 0
  workers = Array.new(workers)
  completed = []
  started = []

  while completed.length != data[:nodes].length
    # check completed
    workers.each_with_index do |worker, index|
      if !worker.nil? && worker[1] == time
        completed << worker[0]
        workers[index] = nil
      end
    end

    # queue up next batch of work if possible
    workers.each_with_index do |worker, index|
      if worker.nil?
        to_start = next_node(data, completed, started)

        if !to_start.nil?
          workers[index] = [to_start, calculate_build_time(data, to_start, build_time) + time]
          started << to_start
        end
      end
    end

    time += 1
  end

  {time: time - 1, path: completed.join}
end

part 1 do
  test(["C"], example_data[:path]["A"], "example_data[A]")
  test(["B", "D", "F"], example_data[:path]["E"], "example_data[E]")
  test([], example_data[:path]["C"], "example_data[E]")
  test(["A", "B", "C", "D", "E", "F"], example_data[:nodes], "example_data[:nodes]")
  test_call("C", :next_node, example_data)
  test_call("A", :next_node, example_data, ["C"])
  test_call("CABDFE", :find_path, example_data)
  test_call("FDSEGJLPKNRYOAMQIUHTCVWZXB", :find_path, input_data)
end

part 2 do
  test_call(1, :calculate_build_time, example_data, "A", 0)
  test_call(61, :calculate_build_time, example_data, "A", 60)
  test_call(2, :calculate_build_time, example_data, "B", 0)
  test_call(nil, :next_node, example_data, [], ["C"])
  test_call({time: 15, path: "CABFDE"}, :duration, example_data, 2, 0)
  test_call("F", :next_node, input_data)
  test_call({:time=>1000, :path=>"FSDEGPLJKNRYOQUAIMHTCVWZXB"}, :duration, input_data, 5, 60)
end
