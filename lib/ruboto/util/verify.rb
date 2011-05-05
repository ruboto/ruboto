require 'ruboto/api'

module Ruboto
  module Util
    module Verify
      ###########################################################################
      #
      # Verify the presence of important components
      #

      def verify_manifest
        abort "cannot find your AndroidManifest.xml to extract info from it. Make sure you're in the root directory of your app" unless
        File.exists? 'AndroidManifest.xml'
        @manifest ||= REXML::Document.new(File.read('AndroidManifest.xml')).root
      end

      def save_manifest
        File.open("AndroidManifest.xml", 'w') {|f| verify_manifest.document.write(f, 4)}
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
        @uses_sdk ||= @manifest.elements["uses-sdk"]
        abort "you must specify your sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless @uses_sdk
        @uses_sdk
      end

      def verify_min_sdk
        verify_sdk_versions
        @min_sdk ||= @uses_sdk.attribute('android:minSdkVersion').value
        abort "you must specify a minimum sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless @min_sdk
        @min_sdk
      end

      def verify_target_sdk
        verify_sdk_versions
        @target_sdk ||= @uses_sdk.attribute('android:targetSdkVersion').value
        abort "you must specify a target sdk level in the manifest (e.g., <uses-sdk android:minSdkVersion='3' android:targetSdkVersion='8' />)" unless @target_sdk
        @target_sdk
      end

      def verify_strings
        abort "cannot find your strings.xml to extract info from it. Make sure you're in the root directory of your app" unless
        File.exists? 'res/values/strings.xml'
        @strings ||= REXML::Document.new(File.read('res/values/strings.xml'))
      end

      def verify_api
        Ruboto::API.api
      end
    end
  end
end