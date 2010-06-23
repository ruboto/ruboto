#
# Run on a device and then copy interfaces.txt back to the callback_gen directory.
#
# The result is a hash.
# The keys are names the names of the classes, sometimes followed by a
# $ and then the name of the interface.
# The keys are hashes themselves. These hashes have keys of the method
# names and values of yet another hash, which gives the argument types
# (and thus implicitly the number of args), the return type, etc.

result = {}
@count = 0

def hash_methods(klass, callbacks_only=false)
  rv = {}
  klass.getDeclaredMethods.each do |method|
    if !callbacks_only or method.getName[0..1] == "on"
      rv[method.getName] = {}
      rv[method.getName]["return_type"] = method.getReturnType.getName unless method.getReturnType.getName == "void" 
      rv[method.getName]["args"] = method.getParameterTypes.map{|i| i.getName} unless method.getParameterTypes.empty?
      @count += 1
    end
  end
  rv
end

%w(
  android.app.Activity
).each do |name|
  h = hash_methods(java.lang.Class.forName(name), true)
  result[name] = h unless h.empty?
end

%w(
  android.hardware.SensorEventListener
  java.lang.Runnable
).each do |name|
  h = hash_methods(java.lang.Class.forName(name))
  result[name] = h unless h.empty?
end

%w(
  android.view.View
  android.widget.AdapterView
  android.widget.TabHost
  android.widget.TextView
  android.widget.DatePicker
  android.widget.TimePicker
  android.app.DatePickerDialog
  android.app.TimePickerDialog
  android.content.DialogInterface
).each do |name|
  java.lang.Class.forName(name).getClasses.each do |klass|
    if klass.isInterface
      h = hash_methods(klass)
      result[klass.getName] = h unless h.empty?
    end
  end
end

File.open("/sdcard/jruby/interfaces.txt", "w") do |file|
  file.write result.inspect
end

puts @count
