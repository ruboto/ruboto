activity org.ruboto.test_app.RssActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @list_view = activity.findViewById(43)
    break if (@text_view && @list_view) || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view && @list_view
end

test('fetch rss feed', ui: false) do |activity|
  start = Time.now
  loop do
    break if activity.findViewById(42).text.to_s == 'List updated'
    break if Time.now - start > 90
    sleep 0.5
  end
  assert_equal 'List updated', activity.findViewById(42).text.to_s
  # assert_equal [],activity.findViewById(43).adapter.list.to_a
  assert_equal [
          "20,000 Leagues Under ActiveRecord",
          "Are there any Databases written in Pure Ruby? Related to \"FullStack Ruby\" Development.",
          "Dancing drones, Matz, sun and the nicest-looking presentation ever, in other words, BaRuCo 2014",
          "Validating JSON Schemas with an RSpec Matcher", "Tiny testing",
          "Don't daemonize your daemons!",
          "It’s a rails world babe and it ain’t magic.",
          "How big is too big for a monolithic rails application ?",
          "Simulating an hexagonal grid.",
          "Other ways to interact with an object",
          "Great new feature in RSpec 3: Verifying Doubles",
          "Easy interoperability between Ruby and Python scripts with JSON",
          "Current Status of Ruby Language (the real discussion)",
          "How to properly deal with timezones in Ruby apps",
          "Learning Advanced Ruby: \"The Right Way\"",
          "Daemonizing Ruby Processes", "Arrays are to hard, what should I do?",
          "Figuring out clearer ways of using Structs",
          "Video Processing with IronWorker + FFmpeg (Ruby example included)",
          "Finding specific strings within an array and comparing to a list",
          "Rails Ramp up", "Ruby Gem: prefix_with",
          "A tl;dr summary of: Eliminating GIL in Ruby through Hardware Transactional Memory",
          "Restful Rails",
          "Sonic Pi: cross-platform audio synthesis using Ruby 2.1 and SuperCollider"
      ],
      activity.list
end
