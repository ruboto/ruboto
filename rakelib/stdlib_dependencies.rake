require 'fileutils'

def log_action(initial_text, final_text='Done.', &block)
  $stdout.sync = true

  print initial_text, '...'
  result = yield
  puts final_text

  result
end
