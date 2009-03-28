require 'rack'
require 'mongrel'
require 'json'

module VertebraGithubHttp
  module Actors
    class Server < Vertebra::Actor
      def initialize(*args)
        super
        Thread.new {
          Rack::Handler::Mongrel.run(self, :Port => 9292)
        }
      end

      provides "/github"

      def call(env)
        request = Rack::Request.new(env)
        unless request.path_info == "/1ce3b2ec626b82bea91b2f23d8b9080f3f5b4b72"
          return [403, {}, "NO"]
        end

        data = JSON.parse(request.POST['payload'])
        pp data

        repository = data['repository']['name']
        data['commits'].each do |commit|
          @agent.request("/code/commit", :repository => repository, :commit => commit)
        end
        [200, {"Content-Type" => "text/plain"}, "OK"]
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
