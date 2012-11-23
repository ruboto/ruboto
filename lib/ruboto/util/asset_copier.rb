module Ruboto
  module Util
    class AssetCopier
      def initialize(from, to, force = true)
        @from = from
        @to = to
        @force = force
      end

      def copy(from, to='')
        target_dir = File.join(@to, to)
        file_pattern = File.directory?(File.join(@from, from)) ? File.join(from, '**/*') : from
        existing_files = @force ? [] : Dir.chdir(target_dir){Dir[file_pattern].select{|f| !File.directory?(f)}}
        files_to_copy = Dir.chdir(@from){Dir[file_pattern].select{|f| !File.directory?(f)}} - existing_files
        files_to_copy.each do |f|
          FileUtils.mkdir_p(File.join(target_dir, File.dirname(f)))
          FileUtils.cp(File.join(@from, f), File.join(target_dir, f))
        end
      end

      def copy_from_absolute_path(from, to='')
        FileUtils.mkdir_p(File.join(@to, to))
        FileUtils.cp_r(Dir[from], File.join(@to, to))
      end
    end
  end
end
