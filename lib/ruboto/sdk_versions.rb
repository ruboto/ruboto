require 'pathname'

module Ruboto
  module SdkVersions
    VERSION_TO_API_LEVEL = {
        '2.1' => 'android-7', '2.1-update1' => 'android-7', '2.2' => 'android-8',
        '2.3' => 'android-9', '2.3.1' => 'android-9', '2.3.2' => 'android-9',
        '2.3.3' => 'android-10', '2.3.4' => 'android-10',
        '3.0' => 'android-11', '3.1' => 'android-12', '3.2' => 'android-13',
        '4.0.1' => 'android-14', '4.0.3' => 'android-15', '4.0.4' => 'android-15',
        '4.1' => 'android-16', '4.1.1' => 'android-16', '4.1.2' => 'android-16',
        '4.2' => 'android-17', '4.2.2' => 'android-17',
    }
    MINIMUM_SUPPORTED_SDK_LEVEL = 7
    MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
    DEFAULT_TARGET_SDK_LEVEL = 10
    DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
  end
end
