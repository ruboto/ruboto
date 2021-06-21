require 'pathname'

module Ruboto
  module SdkVersions
    VERSION_TO_API_LEVEL = {
        '2.3.3' => 10, '2.3.4' => 10, '2.3.5' => 10, '2.3.6' => 10, '2.3.7' => 10,
        '3.0' => 11, '3.1' => 12, '3.2' => 13, '4.0.1' => 14, '4.0.3' => 15,
        '4.0.4' => 15, '4.1' => 16, '4.1.1' => 16, '4.1.2' => 16, '4.2' => 17,
        '4.2.2' => 17, '4.3' => 18, '4.3.1' => 18, '4.4.2' => 19, '5.0.1' => 21,
        '5.1' => 22, '6.0' => 23, '7.0' => 24, '7.1.1' => 25
    }
    API_LEVEL_TO_VERSION = {
        10 => '2.3.3', 11 => '3.0', 12 => '3.1', 13 => '3.2', 14 => '4.0',
        15 => '4.0.3', 16 => '4.1.2', 17 => '4.2.2', 18 => '4.3.1',
        19 => '4.4.2', 21 => '5.0.1', 22 => '5.1', 23 => '6.0', 24 => '7.0', 25 => '7.1.1'
    }

    MINIMUM_SUPPORTED_SDK_LEVEL = 27
    MINIMUM_SUPPORTED_SDK = "android-#{MINIMUM_SUPPORTED_SDK_LEVEL}"
    DEFAULT_TARGET_SDK_LEVEL = 30
    DEFAULT_TARGET_SDK = "android-#{DEFAULT_TARGET_SDK_LEVEL}"
  end
end
