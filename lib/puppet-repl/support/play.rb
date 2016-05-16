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

      def convert_to_text(url)
        require 'uri'
        url_data = URI(url)
        case url_data.host
        when /^github.com/
          if url_data.path =~ /blob/
            url.gsub('blob', 'raw')
          end
        when /^gist.github.com/
          unless url_data.path =~ /raw/
            url = url += '.txt'
          end
        when /^gitlab.com/
          if url_data.path =~ /snippets/
            url += '/raw' unless url_data.path =~ /raw/
            url
          else
            url.gsub('blob', 'raw')
          end
        else
          url
        end
      end

      def play_back_url(url)
        begin
          require 'open-uri'
          require 'net/http'
          converted_url = convert_to_text(url)
          play_back_string open(converted_url).read
        rescue SocketError
          abort "puppet-repl can't play `#{converted_url}'"
        end
      end

      def play_back_string(str)
        handle_input(str)
      end
    end
  end
end
