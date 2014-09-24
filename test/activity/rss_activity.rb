require 'ruboto/util/stack'
require 'rss'
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class RssActivity
  attr_reader :list

  def onCreate(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').
        map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    @list = []
    self.content_view = linear_layout orientation: :vertical, gravity: :center do
      @status = text_view id: 42, text: 'Activity created...'
      @list_view = list_view id: 43, list: @list
    end
  end

  def onResume
    super
    @status.text = 'Resuming activity...'
    Thread.with_large_stack do
      begin
        run_on_ui_thread { @status.text = 'Started update thread...' }
        subjects = []
        rss = RSS::Parser.parse('http://www.feedforall.com/sample.xml')
        rss.items.each do |item|
          subject = item.title.to_s
          subjects << subject
        end
        run_on_ui_thread { @list_view.adapter.add_all subjects }
        run_on_ui_thread { @status.text = 'List updated' }
      rescue Exception
        msg = "#{$!.message}\n#{$!.backtrace.join("\n")}"
        run_on_ui_thread { @status.text = "Thread: Exception: #{msg}" }
      end
    end
    @status.text = 'Resume...OK'
  end
end
