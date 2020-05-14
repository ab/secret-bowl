# frozen_string_literal: true

require 'set'

module SecretBowl
  class Bowl
    attr_reader :key, :content, :seen_content, :remote_host, :remote_ip,
                :created, :created_by_name

    def initialize(remote_host:, remote_ip:, key: nil)
      @content = Set.new
      @seen_content = Set.new
      @remote_host = remote_host
      @remote_ip = remote_ip
      @created = Time.now.to_i
      @created_by_name = 'TODO'

      @key = key || Cache.random_key(length: 6)
    end

    def add(text)
      return if seen_content.include?(text) # noop

      content << text
    end

    def empty?
      size == 0
    end

    def size
      content.size + seen_content.size
    end

    # Pop a random item out of content, put it in seen_content, and return it.
    def next!
      if empty?
        raise IndexError.new('bowl is empty')
      end

      if content.empty?
        # TODO: make this user-controlled
        restart!
      end

      item = content.to_a.sample
      seen_content << item
      content.delete(item)

      return item
    end

    def clear!
      content.clear
      seen_content.clear
    end

    def restart!
      content.merge(seen_content)
      seen_content.clear
    end

    # Make an absolute URL relative to the user-provided request_url.
    #
    # @param request_url [String]
    # @return [String]
    #
    def url(request_url)
      uri = URI.parse(request_url)
      uri.path = "/bowl/#{key}/"
      uri.query = nil
      uri.fragment = nil

      unless ['http', 'https'].include?(uri.scheme)
        raise ArgumentError.new("Bad URI scheme #{uri.inspect}")
      end

      return uri.to_s
    end

    def relative_url
      "/bowl/#{key}/"
    end
  end
end
