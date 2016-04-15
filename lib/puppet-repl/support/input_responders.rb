module PuppetRepl
  module Support
    module InputResponders
      def help(args=[])
        PuppetRepl::Cli.print_repl_desc
      end

      def facts(args=[])
        # convert symbols to keys
        vars = node.facts.values
        ap(vars, {:sort_keys => true, :indent => -1})
      end

      def functions(args=[])
        puts function_map.keys.sort
      end

      def vars(args=[])
        # remove duplicate variables that are also in the facts hash
        vars = scope.to_hash.delete_if {| key, value | node.facts.values.key?(key) }
        vars['facts'] = 'removed by the puppet-repl' if vars.key?('facts')
        ap 'Facts were removed for easier viewing'
        ap(vars, {:sort_keys => true, :indent => -1})
      end

      def environment(args=[])
        puts "Puppet Environment: #{puppet_env_name}"
      end

      def reset(args=[])
        set_scope(nil)
        # initilize scope again
        scope
        set_log_level(log_level)
      end

      def krt(args=[])
        ap(known_resource_types, {:sort_keys => true, :indent => -1})
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
          ap res[args.first.to_i]
        else
          puts "Resources not shown in any specific order".warning
          ap res
        end
      end

      def classes(args=[])
        ap scope.compiler.catalog.classes
      end

    end
  end
end
