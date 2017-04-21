# frozen_string_literal: true
module PuppetDebugger
  module Support
    module InputResponders
      def static_responder_list
        %w(exit functions classification vars facterdb_filter krt facts types
           resources classes whereami datatypes play reset help)
      end

      def disable_benchmark
        $benchmark = false
        $extra_prompt = ''
        'Off'
      end

      def enable_benchmark(show_status = false)
        require 'benchmark'
        $benchmark = true
        if show_status
          $extra_prompt = 'BM'
          'On'
        end
      end

      def benchmark(args = [])
        if args.count > 0
          enable_benchmark(false)
          out = handle_input(args.first)
          disable_benchmark
          out
        else
          status = $benchmark ?  disable_benchmark : enable_benchmark(true)
          "Benchmark Mode #{status}"
        end
      end

      def datatypes(_args = [])
        types = all_data_types
        return types.sort.ai if types.instance_of?(Array)
        types
      end

      # @source_file and @source_line_num instance variables must be set for this
      # method to show the surrounding code
      # @return [String] - string output of the code surrounded by the breakpoint or nil if file
      # or line_num do not exist
      def whereami(_command = nil, _args = nil)
        file = @source_file
        line_num = @source_line_num
        if file && line_num
          if file == :code
            source_code = Puppet[:code]
            code = DebuggerCode.from_string(source_code, :puppet)
          else
            code = DebuggerCode.from_file(file, :puppet)
          end
          return code.with_marker(line_num).around(line_num, 5)
                     .with_line_numbers.with_indentation(5).with_file_reference.to_s
        end
      end

      # @return - returns a list of types available to the environment
      # if a error occurs we we run the types function again
      def types(_args = [])
        loaded_types = []
        begin
          # this loads all the types, if already loaded the file is skipped
          Puppet::Type.loadall
          Puppet::Type.eachtype do |t|
            next if t.name == :component
            loaded_types << t.name.to_s
          end
          loaded_types.ai
        rescue Puppet::Error => e
          puts e.message.red
          Puppet.info(e.message)
          # prevent more than two calls and recursive loop
          return if caller_locations(1,10).find_all{|f| f.label == 'types' }.count > 2
          types
        end
      end

      # displays the facterdb filter
      # @param [Array] - args is not used
      def facterdb_filter(_args = [])
        dynamic_facterdb_filter.ai
      end

      def help(_args = [])
        PuppetDebugger::Cli.print_repl_desc
      end

      def handle_set(input)
        output = ''
        args = input.split(' ')
        args.shift # throw away the set
        case args.shift
        when /node/
          if name = args.shift
            output = "Resetting to use node #{name}"
            reset
            set_remote_node_name(name)
          else
            out_buffer.puts 'Must supply a valid node name'
          end
        when /loglevel/
          if level = args.shift
            @log_level = level
            set_log_level(level)
            output = "loglevel #{Puppet::Util::Log.level} is set"
          end
        end
        output
      end

      def facts(_args = [])
        variables = node.facts.values
        variables.ai(sort_keys: true, indent: -1)
      end

      def functions(args = [])
        filter = args.first || ''
        function_map.keys.sort.grep(/^#{Regexp.escape(filter)}/)
      end

      def vars(_args = [])
        # remove duplicate variables that are also in the facts hash
        variables = scope.to_hash.delete_if { |key, _value| node.facts.values.key?(key) }
        variables['facts'] = 'removed by the puppet-debugger' if variables.key?('facts')
        output = 'Facts were removed for easier viewing'.ai + "\n"
        output += variables.ai(sort_keys: true, indent: -1)
      end

      def environment(_args = [])
        "Puppet Environment: #{puppet_env_name}"
      end

      def reset(_args = [])
        set_scope(nil)
        set_remote_node_name(nil)
        set_node(nil)
        set_facts(nil)
        set_environment(nil)
        set_compiler(nil)
        set_log_level(log_level)
      end

      def set_log_level(level)
        Puppet::Util::Log.level = level.to_sym
        buffer_log = Puppet::Util::Log.newdestination(:buffer)
        if buffer_log
          # if this is already set the buffer_log is nil
          buffer_log.out_buffer = out_buffer
          buffer_log.err_buffer = out_buffer
        end
        nil
      end

      def krt(_args = [])
        known_resource_types.ai(sort_keys: true, indent: -1)
      end

      def play(args = [])
        config = {}
        config[:play] = args.first
        play_back(config)
        nil # we don't want to return anything
      end

      def classification(_args = [])
        node.classes.ai
      end

      def resources(args = [])
        res = scope.compiler.catalog.resources.map do |res|
          res.to_s.gsub(/\[/, "['").gsub(/\]/, "']") # ensure the title has quotes
        end
        if !args.first.nil?
          res[args.first.to_i].ai
        else
          output = "Resources not shown in any specific order\n".warning
          output += res.ai
        end
      end

      def classes(_args = [])
        scope.compiler.catalog.classes.ai
      end
    end
  end
end
