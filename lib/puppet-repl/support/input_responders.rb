module PuppetRepl
  module Support
    module InputResponders

      def static_responder_list
        ["exit", "functions", "vars", "krt", "facts",
         "resources", "classes", "play","reset", "help"
        ]
      end

      def help(args=[])
        out_buffer.puts PuppetRepl::Cli.print_repl_desc
      end

      def facts(args=[])
        variables = node.facts.values
        out_buffer.puts variables.ai({:sort_keys => true, :indent => -1})
      end

      def functions(args=[])
        out_buffer.puts function_map.keys.sort
      end

      def vars(args=[])
        # remove duplicate variables that are also in the facts hash
        variables = scope.to_hash.delete_if {| key, value | node.facts.values.key?(key) }
        variables['facts'] = 'removed by the puppet-repl' if variables.key?('facts')
        out_buffer.puts 'Facts were removed for easier viewing'.ai
        out_buffer.puts variables.ai({:sort_keys => true, :indent => -1})
      end

      def environment(args=[])
        out_buffer.puts "Puppet Environment: #{puppet_env_name}"
      end

      def reset(args=[])
        set_scope(nil)
        # initilize scope again
        scope
        set_log_level(log_level)
      end

      def krt(args=[])
        out_buffer.puts known_resource_types.ai({:sort_keys => true, :indent => -1})
      end

      def play(args=[])
        config = {}
        config[:play] = args.first
        play_back(config)
      end

      def resources(args=[])
        res = scope.compiler.catalog.resources.map do |res|
          res.to_s.gsub(/\[/, "['").gsub(/\]/, "']") # ensure the title has quotes
        end
        if !args.first.nil?
          out_buffer.puts res[args.first.to_i].ai
        else
          puts "Resources not shown in any specific order".warning
          out_buffer.puts res.ai
        end
      end

      def classes(args=[])
        out_buffer.puts scope.compiler.catalog.classes.ai
      end

    end
  end
end
