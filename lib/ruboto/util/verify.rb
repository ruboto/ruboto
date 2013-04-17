require 'ruboto/api'
require 'yaml'

module Ruboto
  module Util
    module Verify
      ###########################################################################
      #
      # Verify the presence of important components
      #

      def verify_manifest
        return @manifest if @manifest
        abort "cannot find your AndroidManifest.xml to extract info from it. Make sure you're in the root directory of your app" unless
        File.exists? 'AndroidManifest.xml'
        @manifest = REXML::Document.new(File.read('AndroidManifest.xml')).root
      end

      def save_manifest
        File.open('AndroidManifest.xml', 'w') do |f|
          REXML::Formatters::OrderedAttributes.new(4).write(verify_manifest.document, f)
          f.puts
        end
      end
      
      def verify_test_manifest
        abort "cannot find your test AndroidManifest.xml to extract info from it. Make sure you're in the root directory of your app" \
            unless File.exists? 'test/AndroidManifest.xml'
        @manifest ||= REXML::Document.new(File.read('test/AndroidManifest.xml')).root
      end

      def save_test_manifest
        File.open('test/AndroidManifest.xml', 'w') {|f| verify_test_manifest.document.write(f, 4)}
      end

      def verify_package
        verify_manifest
        @package ||= @manifest.attribute('package').value
      end

      def verify_activity
        verify_manifest
        @activity ||= @manifest.elements['application/activity'].attribute('android:name').value
      end

      def verify_sdk_versions
        verify_manifest
        @uses_sdk ||= @manifest.elements['uses-sdk']
        abort "you must specify your sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless @uses_sdk
        @uses_sdk
      end

      def verify_min_sdk
        return @min_sdk if @min_sdk
        verify_sdk_versions
        min_sdk_attr = @uses_sdk.attribute('android:minSdkVersion').value
        abort "you must specify a minimum sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless min_sdk_attr
        @min_sdk = min_sdk_attr.to_i
      end

      def verify_target_sdk
        return @target_sdk if @target_sdk
        verify_sdk_versions
        target_sdk_attr = @uses_sdk.attribute('android:targetSdkVersion').value
        abort "you must specify a target sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless target_sdk_attr
        @target_sdk = target_sdk_attr.to_i
      end

      def verify_strings
        abort "cannot find your strings.xml to extract info from it. Make sure you're in the root directory of your app" unless
        File.exists? 'res/values/strings.xml'
        @strings ||= REXML::Document.new(File.read('res/values/strings.xml'))
      end

      def verify_api
        Ruboto::API.api
      end

      def verify_ruboto_config
        if File.exists? 'ruboto.yml'
          @ruboto_config ||= YAML::load_file('ruboto.yml')
        else
          @ruboto_config = {}
        end
      end

      def save_ruboto_config
        File.open('ruboto.yml', 'w') {|f| f << YAML.dump(verify_ruboto_config)}
      end

    end
  end
end
