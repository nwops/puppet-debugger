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
          str = open(converted_url).read
          play_back_string(str)
        rescue SocketError
          abort "puppet-repl can't play `#{converted_url}'"
        end
      end

      def play_back_string(str)
        full_buffer = ''
        str.split("\n").each do |buf|
          begin
            full_buffer += buf
            # unless this is puppet code, otherwise skip repl keywords
            if keyword_expression.match(buf)
              out_buffer.write(">> ")
            else
              parser.parse_string(full_buffer)
              out_buffer.write(">>\n")
            end
          rescue Puppet::ParseErrorWithIssue => e
            if multiline_input?(e)
              full_buffer += "\n"
              next
            end
          end
          out_buffer.puts(full_buffer)
          handle_input(full_buffer)
          full_buffer = ''
        end
      end
    end
  end
end
