module Ruboto
  module Util
    class AssetCopier
      def initialize(from, to)
        @from = from
        @to = to
      end

      def copy(from, to='')
        FileUtils.mkdir_p(File.join(@to, to))
        FileUtils.cp_r(Dir[File.join(@from, from)], File.join(@to, to))
      end

      def copy_from_absolute_path(from, to='')
        FileUtils.mkdir_p(File.join(@to, to))
        FileUtils.cp_r(Dir[from], File.join(@to, to))
      end
    end
  end
end