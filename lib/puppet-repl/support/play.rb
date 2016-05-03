module PuppetRepl
  module Support
    module Play

      def play_back(config={})
        if config[:play]
          if config[:play] =~ /^http/
            play_back_url(config[:play])
          elsif File.exists? config[:play]
            play_back_string(File.read(config[:play]))
          else config[:play]
            out_buffer.puts "puppet-repl can't play #{config[:play]}'"
          end
        end
      end

      def play_back_url(url)
        require 'open-uri'
        require 'net/http'

        if url[/gist.github.com\/[a-z\d]+$/]
          url += '.txt'
        elsif url[/github.com.*blob/]
          url.sub!('blob', 'raw')
        end
        play_back_string open(url).read
      rescue SocketError
        abort "puppet-repl can't play `#{url}'"
      end

      def play_back_string(str)
        handle_input(str)
      end
    end
  end
end
