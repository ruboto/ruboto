node default {
  package { ["libc6-i386","lib32stdc++6","lib32gcc1","lib32ncurses5","lib32z1"]: ensure => present }
  include users
  exec { 'rvm':
    command     => "/usr/bin/curl -sSL https://rvm.io/mpapis.asc | gpg --import - ; /usr/bin/curl -sSL https://get.rvm.io | bash -s stable --ruby",
    creates     => '/home/vagrant/.rvm',
  }
}
