module PuppetDebugger
  module Support
    module Functions
      # returns a array of function files which is only required
      # when displaying the function map, puppet will load each function on demand
      # in the future we may want to utilize the puppet loaders to find these things
      def function_files
        search_dirs = lib_dirs.map do |lib_dir|
          [File.join(lib_dir, 'puppet', 'functions', '**', '*.rb'),
            File.join(lib_dir, 'functions', '**', '*.rb'),
           File.join(lib_dir, 'puppet', 'parser', 'functions', '*.rb')
           ]
        end
        # add puppet lib directories
        search_dirs << [File.join(puppet_lib_dir, 'puppet', 'functions', '**', '*.rb'),
          File.join(puppet_lib_dir, 'puppet', 'parser', 'functions', '*.rb')
         ]
        Dir.glob(search_dirs.flatten)
      end

      # returns either the module name or puppet version
      def mod_finder
        @mod_finder ||= Regexp.new('\/([\w\-\.]+)\/lib')
      end

      # returns a map of functions
      def function_map
        unless @functions
          do_initialize
          @functions = {}
          function_files.each do |file|
            obj = {}
            name = File.basename(file, '.rb')
            obj[:name] = name
            obj[:parent] = mod_finder.match(file)[1]
            @functions["#{obj[:parent]}::#{name}"] = obj
          end
        end
        @functions
      end

      # returns an array of module loaders that we may need to use in the future
      # in order to parse all types of code (ie. functions)  For now this is not
      # being used.
      def resolve_paths(loaders)
        mod_resolver = loaders.instance_variable_get(:@module_resolver)
        all_mods = mod_resolver.instance_variable_get(:@all_module_loaders)
      end

      # gather all the lib dirs
      def lib_dirs
        dirs = modules_paths.map do |mod_dir|
          Dir["#{mod_dir}/*/lib"].entries
        end.flatten
        dirs + [puppet_repl_lib_dir]
      end

      # load all the lib dirs so puppet can find the functions
      # at this time, this function is not being used
      def load_lib_dirs
        lib_dirs.each do |lib|
          $LOAD_PATH << lib
        end
      end

      # def functions
      #   @functions = []
      #   @functions << compiler.loaders.static_loader.loaded.keys.find_all {|l| l.type == :function}
      # end
    end
  end
end
