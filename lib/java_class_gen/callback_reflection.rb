#
# Run on a device and then copy interfaces.txt back to the callback_gen directory.
#
# The result is a hash.
# The keys are names the names of the classes, sometimes followed by a
# $ and then the name of the interface.
# The keys are hashes themselves. These hashes have keys of the method
# names and values of yet another hash, which gives the argument types
# (and thus implicitly the number of args), the return type, etc.

require 'java'

class ReflectionBuilder
  attr_reader :methods

  def initialize(class_name, callbacks_only=false)
    @methods = {}
    @@count = 0 unless defined?(@@count)
    reflect class_name, callbacks_only
  end

  def reflect(klass, callbacks_only=false)
    # klass can be the java class object or a string
    klass = java_class klass if klass.class == String

    hash = @methods[klass.getName] = {}

    # iterate over the public methods of the class
    klass.getDeclaredMethods.select {|method| java.lang.reflect.Modifier.isPublic(method.getModifiers) }.each do |method|
      if !callbacks_only or method.getName[0..1] == "on"
        hash[method.getName] = {}
        hash[method.getName]["return_type"] = method.getReturnType.getName unless method.getReturnType.getName == "void" 
        hash[method.getName]["args"] = method.getParameterTypes.map{|i| i.getName} unless method.getParameterTypes.empty?
        hash[method.getName]["abstract"] = java.lang.reflect.Modifier.isAbstract(method.getModifiers)
        @@count += 1
      end
    end
  end

  def interfaces(*args)
    args.each {|arg| reflect arg}
  end

  def interfaces_under(*args)
    args.each do |name|
      interfaces *java.lang.Class.forName(name).getClasses.select {|klass| klass.isInterface}
    end
  end

  def self.count
    @@count
  end

  def self.reset_count
    @@count = 0
  end
  
  protected
  def java_class(class_name)
    java.lang.Class.forName(class_name)
  end
end

def java_reflect(class_name, callbacks_only=false, &block)
  r = ReflectionBuilder.new(class_name, callbacks_only)
  yield r
  $result[class_name] = r.methods
end

$result = {}
ReflectionBuilder.reset_count

java_reflect 'android.app.Activity', true do |r|
  r.interfaces *%w(
  android.hardware.SensorEventListener
  java.lang.Runnable
  )

  r.interfaces_under *%w(
  android.view.View
  android.widget.AdapterView
  android.widget.TabHost
  android.widget.TextView
  android.widget.DatePicker
  android.widget.TimePicker
  android.app.DatePickerDialog
  android.app.TimePickerDialog
  android.content.DialogInterface
  )
end


File.open("/sdcard/jruby/interfaces.txt", "w") do |file|
  file.write $result.inspect
end

puts ReflectionBuilder.count

