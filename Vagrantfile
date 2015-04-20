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
    # vb.gui = true
    vb.memory = '3072'
  end

  config.vm.define 'ubuntu' do |ubuntu|
    ubuntu.vm.box = 'ubuntu/trusty64'
    ubuntu.vm.provision :shell, inline: 'apt-get install puppet ; puppet apply --modulepath=/vagrant/puppet/modules /vagrant/puppet/manifests/site.pp'
    # ubuntu.vm.provision :shell, inline: create_swap(1536)
    ubuntu.vm.provision :shell, inline: <<-SHELL
      su - vagrant -c 'mkdir -p ruboto'
      su - vagrant -c 'rsync -acPuv --exclude adb_logcat.log --exclude /tmp /vagrant/* ruboto/'
    SHELL
  end

  config.vm.define 'windows' do |db|
    db.vm.box = 'designerror/windows-7'
  end

end
