require File.expand_path('test_helper', File.dirname(__FILE__))

class SplashTest < Test::Unit::TestCase
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_splash
    Dir.chdir APP_DIR do
      File.open('res/layout/splash.xml', 'w'){|f| f << <<EOF}
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="fill_parent"
    android:layout_height="fill_parent"
    android:orientation="vertical"
    android:gravity="center_horizontal|center_vertical"
    android:background="#30587c"
>
<!--Specify your splash image here-->
<ImageView
    android:layout_width="fill_parent"
    android:layout_height="fill_parent"
    android:src="@drawable/logo"
    android:scaleType="fitCenter"
    android:layout_weight="1"
/>
  <TextView android:id="@+id/text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Please wait..."
            android:color="#000000"
  />
</LinearLayout>
EOF

      FileUtils.cp '../../icons/ruboto-logo_512x512.png', 'res/drawable/logo.png'
    end

    run_app_tests
  end

end
