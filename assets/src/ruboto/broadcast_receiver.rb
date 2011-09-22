require 'ruboto/base'

#######################################################
#
# ruboto/broadcast_receiver.rb
#
# Basic broadcast_receiver set up and callback configuration.
#
#######################################################

#
# Basic BroadcastReceiver Setup
#

module Ruboto
  module BroadcastReceiver
  end
end

def ruboto_configure_broadcast_receiver(klass)
  klass.class_eval do
    include Ruboto::BroadcastReceiver
    
    def on_receive(context, intent)
    end
  end
end

ruboto_import "org.ruboto.RubotoBroadcastReceiver"
ruboto_configure_broadcast_receiver(RubotoBroadcastReceiver)

