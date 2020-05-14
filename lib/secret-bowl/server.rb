require 'uri'
require 'rack/ssl-enforcer'
require 'resolv'

module SecretBowl
  class Server < Sinatra::Base
    set :bind, '127.0.0.1'
    set :port, 6623

    enable :logging, :dump_errors

    set :root, SecretBowl.root_folder

    # force HTTPS in production
    use Rack::SslEnforcer, :only_environments => ['production']

    # to support global state, process only one request at a time
    # obviously this is not incredibly scalable
    enable :lock

    @@cache = Cache.new

    not_found do
      erb :not_found
    end

    error do
      erb :error
    end

    get '/' do
      erb :root
    end

    get '/bowl/:key' do |key|
      redirect "/bowl/#{key}/"
    end

    get '/bowl/:key/' do |key|
      begin
        @bowl = @@cache.get(key)
      rescue IndexError
        raise Sinatra::NotFound
        # TODO: redirect instead
      end

      erb :info
    end

    get '/bowl' do
      redirect '/'
    end

    post '/bowl' do
      key = params.fetch('key', nil)
      key = nil if key.empty?

      begin
        request_host = Resolv.getname(request.ip)
      rescue Resolv::ResolvError => err
        puts 'Failed to resolve host: ' + err.inspect
        request_host = nil
      end

      bowl = Bowl.new(
        remote_host: request_host,
        remote_ip: request.ip,
        key: key
      )
      @@cache.add_bowl(bowl)

      redirect bowl.relative_url
    end

    # add a word to the bowl
    post '/bowl/:key/add' do |key|
      begin
        bowl = @@cache.get(key)
      rescue KeyError
        raise Sinatra::NotFound
      end

      text = params.fetch('text')

      if text.empty?
        halt 400, "Text cannot be empty"
      end
      bowl.add(text)

      redirect bowl.relative_url
    end

    # get the next word from the bowl
    post '/bowl/:key/next' do |key|
      begin
        @bowl = @@cache.get(key)
      rescue KeyError
        raise Sinatra::NotFound
      end

      begin
        @item_text = @bowl.next!
      rescue IndexError
        @draw_err = "Bowl is empty!"
      end

      erb :info
    end

    # clear the whole bowl
    post '/bowl/:key/clear' do |key|
      begin
        bowl = @@cache.get(key)
      rescue KeyError
        raise Sinatra::NotFound
      end

      bowl.clear!
      redirect bowl.relative_url
    end

    # reset the seen/not-seen lists
    post '/bowl/:key/restart' do |key|
      begin
        bowl = @@cache.get(key)
      rescue KeyError
        raise Sinatra::NotFound
      end

      bowl.restart!
      redirect bowl.relative_url
    end

    helpers do
      def escape(text)
        Rack::Utils.escape_html(text)
      end
    end
  end
end
