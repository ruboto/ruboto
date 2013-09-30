require 'rexml/formatters/pretty'

class REXML::Formatters::OrderedAttributes < REXML::Formatters::Pretty
  def write_element(elm, out)
    att = elm.attributes

    class <<att
      alias _each_attribute each_attribute

      def each_attribute(&b)
        to_enum(:_each_attribute).sort_by { |x| [x.prefix, x.name] }.each(&b)
      end
    end

    super(elm, out)
  end
end
