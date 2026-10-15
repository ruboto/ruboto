require 'rexml/formatters/pretty'

class REXML::Formatters::OrderedAttributes < REXML::Formatters::Pretty
  def write_element(elm, out)
    att = elm.attributes

    class <<att
      unless method_defined?(:_ruboto_each_attribute)
        alias _ruboto_each_attribute each_attribute

        def each_attribute(&b)
          attrs = []
          _ruboto_each_attribute { |a| attrs << a }
          attrs.sort_by { |x| [x.prefix, x.name] }.each(&b)
        end
      end
    end

    super(elm, out)
  end
end
