require 'java'

def assert(value, message = "#{value.inspect} expected to be true")
  raise message unless value
end

def assert_equal(expected, actual, message = "'#{expected}' expected, but got '#{actual}'")
  raise message unless expected == actual
end

def assert_less_than_or_equal(limit, actual, message = "Expected '#{expected}' to be less than or equal to '#{limit}'")
  raise message unless expected <= limit
end
