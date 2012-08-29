module Ruboto
  module Util
    module CodeFormatting
      ###########################################################################
      #
      # Methods for formatting code
      #
      def method_call(return_type, method_name, parameters=[], exceptions=nil, body_clause=[])
        ["public #{"#{return_type} " unless return_type.nil? || return_type.empty?}#{method_name}(" + parameters.map{|i| "#{i[1]} #{i[0]}"}.join(", ") + ") #{" throws #{exceptions.join(', ')}" if exceptions && exceptions.any?}{",
        body_clause.indent, "}"]
      end

      def if_else(condition, if_clause, else_clause)
        ["if (#{condition}) {", if_clause.indent, else_clause.compact.empty? ? nil : "} else {", else_clause.indent, "}"]
      end

      def try_catch(try_clause, catch_clause)
        ["try {", try_clause.indent, "} catch (RaiseException re) {", catch_clause.indent, "}"]
      end
    end
  end
end
