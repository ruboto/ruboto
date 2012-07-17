#######################################################
#
# ruboto/broadcast_receiver.rb
#
# Basic broadcast_receiver set up and callback configuration.
#
#######################################################

require 'ruboto/base'

ruboto_import "org.ruboto.RubotoBroadcastReceiver"
RubotoBroadcastReceiver.class_eval do
    def self.new_with_callbacks &block
      (($broadcast_receiver.nil? || $broadcast_receiver.initialized) ? new : $broadcast_receiver).initialize_ruboto_callbacks &block
    end

    def initialized
      @initialized ||= false
    end

    def initialize_ruboto_callbacks &block
      instance_eval &block
      setup_ruboto_callbacks
      @initialized = true
      self
    end

    def on_receive(context, intent)
    end
end

module Ruboto
  module BroadcastReceiver
  end
end
