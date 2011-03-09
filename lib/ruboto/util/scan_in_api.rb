module Ruboto
  module Util
    module ScanInAPI
      ###########################################################################
      #
      # Scan the XML file. Much faster than using REXML.
      #

      def scan_in_api(file)
        require 'strscan'
        doc = StringScanner.new(file)
        Thread.current[:api] = XMLElement.new
        parents = [Thread.current[:api]]

        while not doc.eos?
          doc.scan(/</)
          if doc.scan(/\/\w+>/)
            parents.pop
          else
            name = doc.scan(/\w+/)
            doc.scan(/\s+/)
            values = {}
            while not (term = doc.scan(/[\/>]/))
              key = doc.scan(/\w+/)
              doc.scan(/='/)
              value = doc.scan(/[^']*/)
              doc.scan(/'\s*/)
              values[key] = value
            end
            element = parents[-1].add_element(name, values)
            parents.push(element) if term == ">"
            doc.scan(/>/) if term == "/"
          end
        end

        Thread.current[:api]
      end
    end
  end
end