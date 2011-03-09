# Add an "indent" method to Array
class Array
  def indent
    flatten.compact.map{|i| "  " + i}
  end
end
