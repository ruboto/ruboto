require 'java'

def assert(value, message = nil)
  raise "#{"#{message}\n" if message}#{value.inspect} expected to be true" unless value
end

def assert_equal(expected, actual, message = nil)
  raise "#{"#{message}\n" if message}'#{expected}' expected, but got '#{actual}'" unless expected == actual
end

def assert_less_than_or_equal(limit, actual, message = nil)
  raise "#{"#{message}\n" if message}Expected '#{actual}' to be less than or equal to '#{limit}'" unless actual <= limit
end

def assert_matches(pattern, actual, message = nil)
  raise "#{"#{message}\n" if message}'#{pattern}' expected, but got '#{actual}'" unless pattern =~ actual
end
