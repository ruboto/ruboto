require 'pathname'

module Ruboto
  module SdkVersions
    VERSION_TO_API_LEVEL = {
        '2.3' => 9, '2.3.1' => 9, '2.3.2' => 9, '2.3.3' => 10, '2.3.4' => 10,
        '3.0' => 11, '3.1' => 12, '3.2' => 13, '4.0.1' => 14, '4.0.3' => 15,
        '4.0.4' => 15, '4.1' => 16, '4.1.1' => 16, '4.1.2' => 16, '4.2' => 17,
        '4.2.2' => 17, '4.3' => 18, '4.4.2' => 19,
    }
    API_LEVEL_TO_VERSION = {
        10 => '2.3.3', 11 => '3.0', 12 => '3.1', 13 => '3.2', 14 => '4.0',
        15 => '4.0.3', 16 => '4.1.2', 17 => '4.2.2', 18 => '4.3', 19 => '4.4.2',
    }

    MINIMUM_SUPPORTED_SDK_LEVEL = 10
    MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
    DEFAULT_TARGET_SDK_LEVEL = 15
    DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
  end
end
