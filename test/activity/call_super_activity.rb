require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class CallSuperActivity
  def onCreate(bundle)
    super
    setTitle 'Default'
    setTitle 'With Super', true
    setTitle 'Without Super', false

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => android.view.Gravity::CENTER do
          text_view :id => 42, :text => title, :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end

  def setTitle(title, call_super = true)
    super(title) if call_super
  end

  # FIXME(uwe):  We should test that super is not called implicitly
  # def onResume
  #   super
  # end

end
