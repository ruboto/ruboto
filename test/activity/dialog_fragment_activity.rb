require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class DialogFragmentActivity
  def onCreate(bundle)
    super
    set_title 'Dialog Fragment Test'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center do
          text_view :id => 42, :text => title, :text_size => 48.0,
                    :gravity => :center
        end
    ft = getFragmentManager.beginTransaction
    ft.addToBackStack(nil)
    ExampleDialogFragment.new.show(ft, 'example_dialog')
  end
end

class ExampleDialogFragment < android.app.DialogFragment
  def onCreate(bundle)
    super
    @some_var = 'Ruboto does fragments!'
  end

  def onCreateView(inflater, container, bundle)
    dialog.title = @some_var

    linear_layout :orientation => :vertical do
      linear_layout :gravity => :center, :layout => {:width => :fill_parent} do
        text_view :text => @some_var, :id => 43, :text_size => 40.0,
                  :gravity => :center
      end
    end
  end
end
