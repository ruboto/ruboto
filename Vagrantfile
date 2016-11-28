# -*- mode: ruby -*-
# vi: set ft=ruby :

# @param swap_size_mb [Integer] swap size in megabytes
# @param swap_file [String] full path for swap file, default is /swapfile1
# @return [String] the script text for shell inline provisioning
def create_swap(swap_size_mb, swap_file = '/swapfile')
  <<-EOS
    if [ ! -f #{swap_file} ]; then
      echo "Creating #{swap_size_mb}mb swap file=#{swap_file}. This could take a while..."
      dd if=/dev/zero of=#{swap_file} bs=1024 count=#{swap_size_mb * 1024}
      mkswap #{swap_file}
      chmod 0600 #{swap_file}
      swapon #{swap_file}
      if ! grep -Fxq "#{swap_file} swap swap defaults 0 0" /etc/fstab
      then
        echo "#{swap_file} swap swap defaults 0 0" >> /etc/fstab
      fi
    fi
  EOS
end


Vagrant.configure(2) do |config|
  config.vm.provider 'virtualbox' do |vb|
    vb.memory = '3072'
  end

  config.vm.define 'ubuntu' do |ubuntu|
    ubuntu.vm.box = 'ubuntu/trusty64'
    ubuntu.vm.provision :shell, inline: create_swap(1536)
    ubuntu.vm.provision :shell, inline: <<-SHELL
      sudo apt-get -y install git libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1
      su - vagrant -c 'command curl -sSL https://rvm.io/mpapis.asc | gpg --import -'
      su - vagrant -c 'curl -sSL https://get.rvm.io | bash -s stable --ruby'
      su - vagrant -c 'mkdir -p ruboto'
      su - vagrant -c 'rsync -acPuv --exclude adb_logcat.log --exclude /tmp /vagrant/* ruboto/'
      sudo apt-get -y autoremove
      sudo timedatectl set-timezone #{Time.now.zone}
    SHELL
  end

  config.vm.define 'windows' do |db|
    db.vm.box = 'designerror/windows-7'
  end

end
