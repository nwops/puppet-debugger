module PuppetRepl
  module Support
    module Functions
      # returns a array of function files
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
    
      # def functions
      #   @functions = []
      #   @functions << compiler.loaders.static_loader.loaded.keys.find_all {|l| l.type == :function}
      # end
    end
  end
end
