require 'logger'
require 'yaml'

require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'

module SecretBowl
  def self.root_folder
    File.join(File.dirname(__FILE__), '..')
  end

  # Base SecretBowl exception class
  class Error < StandardError; end
end

require_relative './secret-bowl/bowl'
require_relative './secret-bowl/cache'
require_relative './secret-bowl/server'
