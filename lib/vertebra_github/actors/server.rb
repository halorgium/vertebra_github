require 'rack'
require 'mongrel'
require 'json'

module VertebraGithub
  module Actors
    class Server < Vertebra::Actor
      class Unauthorized < StandardError; end
      class BadRequest < StandardError; end

      def initialize(*args)
        super

        host, port, @user, @pass = args.first
        Thread.new {
          Rack::Handler::Mongrel.run(self, :Host => host, :Port => port)
        }
      end

      def call(env)
        auth = Rack::Auth::Basic::Request.new(env)

        return Unauthorized unless auth.provided?
        return BadRequest unless auth.basic?
        username, password = auth.credentials
        raise Unauthorized unless @user == username && @pass == password

        request = Rack::Request.new(env)

        case request.path_info
        when "/"
          data = JSON.parse(request.POST['payload'])

          owner = data['repository']['owner']['name']
          repository = data['repository']['name']
          data['commits'].each do |commit|
            topic = commit['message'].split("\n").first
            ref =   commit['id'][0,7]
            author = commit['author']['name']
            args = {:repository => Vertebra::Utils.resource("/repository/github/#{owner}/#{repository}"), :commit => commit}
            @agent.request("/code/commit", :single, args)
          end

          [200, {"Content-Type" => "text/plain"}, "OK"]
        else
          [404, {}, ""]
        end
      rescue Unauthorized
        [401, {'WWW-Authenticate' => %(Basic realm="IrcCat")}, 'Authorization Required']
      rescue BadRequest
        [400, {}, 'Bad Request']
      rescue Exception => e
        puts "Got an error: #{e.class}, #{e.message}"
        e.backtrace.each do |b|
          puts "- #{b}"
        end
        [503, {}, "ERR"]
      end
    end
  end
end
