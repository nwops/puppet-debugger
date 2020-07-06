require 'puppet-debugger/input_responder_plugin'
module PuppetDebugger
  module InputResponders
    class Play < InputResponderPlugin
      COMMAND_WORDS = %w(play)
      SUMMARY = 'Playback a file or URL as input.'
      COMMAND_GROUP = :editing

      def run(args = [])
        config = {}
        config[:play] = args.first
        play_back(config)
        nil # we don't want to return anything
      end

      def play_back(config = {})
        if config[:play]
          if config[:play] =~ /^http/
            play_back_url(config[:play])
          elsif File.exist? config[:play]
            play_back_string(File.read(config[:play]))
          else config[:play]
               debugger.out_buffer.puts "puppet-debugger can't play #{config[:play]}'"
          end
        end
      end

      def convert_to_text(url)
        require 'uri'
        url_data = URI(url)
        case url_data.host
        when /^gist\.github*/
          url = url += '.txt' unless url_data.path =~ /raw/
          url
        when /^github.com/
          url.gsub('blob', 'raw') if url_data.path =~ /blob/
        when /^gist.github.com/
          url = url += '.txt' unless url_data.path =~ /raw/
          url
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

      # opens the url and reads the data
      def fetch_url_data(url)
        open(url).read
      end

      def play_back_url(url)
        require 'open-uri'
        require 'net/http'
        converted_url = convert_to_text(url)
        str = fetch_url_data(converted_url)
        play_back_string(str)
      rescue SocketError
        abort "puppet-debugger can't play `#{converted_url}'"
      end

      # plays back the string to the output stream
      # echos the input and the produced output
      def play_back_string(str)
        full_buffer = ''
        str.split("\n").each do |buf|
          begin
            full_buffer += buf
            # unless this is puppet code, otherwise skip repl keywords
            if PuppetDebugger::InputResponders::Commands.command_list_regex.match(buf)
              debugger.out_buffer.write('>> ')
            else
              debugger.parser.parse_string(full_buffer)
              debugger.out_buffer.write('>> ')
            end
          rescue Puppet::ParseErrorWithIssue => e
            if debugger.multiline_input?(e)
              full_buffer += "\n"
              next
            end
          end
          debugger.out_buffer.puts(full_buffer)
          debugger.handle_input(full_buffer)
          full_buffer = ''
        end
      end
    end
  end
end
