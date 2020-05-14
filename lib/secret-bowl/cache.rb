require 'securerandom'

module SecretBowl
  class Cache
    KeyChars = ('a'..'z').to_a + ('0'..'9').to_a

    def self.random_char
      KeyChars[SecureRandom.random_number(KeyChars.length)]
    end
    def self.random_key(length: 30)
      (0...length).map { random_char }.join
    end

    class Duplicate < SecretBowl::Error; end

    def initialize
      @data = {}
    end

    def length
      @data.length
    end

    alias :size :length

    def get(key)
      @data[key] or raise KeyError.new("key #{key.inspect} not found")
    end

    def delete(key)
      @data.delete(key) or raise KeyError.new("key #{key.inspect} not found")
    end

    def add_bowl(bowl)
      add_by_key(key: bowl.key, value: bowl)
    end

    def add_by_key(key:, value:)
      if @data[key]
        raise Duplicate.new("Duplicate key: #{key.inspect}")
      end
      unless value
        raise "Storing falsy values is not allowed ¯\_(ツ)_/¯"
      end
      if !key || key.empty?
        raise "Storing empty keys is not allowed ¯\_(ツ)_/¯"
      end
      @data[key] = value
    end
  end
end
