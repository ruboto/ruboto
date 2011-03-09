require 'java'

def assert(value, message = "#{value.inspect} expected to be true")
  raise message unless value
end

def assert_equal(expected, actual, message = "'#{expected}' expected, but got '#{actual}'")
  raise message unless expected == actual
end
