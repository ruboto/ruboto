#######################################################
#
# ruboto/util/toast.rb
#
# Utility methods for doing a toast.
#
#######################################################

Java::android.content.Context.class_eval do
  def toast(text, duration=Java::android.widget.Toast::LENGTH_SHORT)
    Java::android.widget.Toast.makeText(self, text, duration).show
  end

  def toast_result(result, success, failure, duration=Java::android.widget.Toast::LENGTH_SHORT)
    toast(result ? success : failure, duration)
  end
end

