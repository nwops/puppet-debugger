require "puppet-debugger/input_responder_plugin"
require "table_print"
require 'fileutils'
require 'bundler'

module PuppetDebugger
  module InputResponders
    class Functions < InputResponderPlugin
      COMMAND_WORDS = %w(functions)
      SUMMARY = "List all the functions available in the environment."
      COMMAND_GROUP = :environment
      FUNC_NATIVE_NAME_REGEX = %r{\Afunction\s([\w\:]+)}
      FUNC_V4_NAME_REGEX = %r{Puppet\:\:Functions.create_function\s?\(?\:?\'?([\w\:]+)}

      def run(args = [])
        filter = args.first || ""
        TablePrint::Printer.table_print(sorted_list(filter), [:full_name, :mod_name])
      end

      def sorted_list(filter = "")
        search = /#{Regexp.escape(filter)}/
        function_map.values.find_all do |v|
          "#{v[:mod_name]}_#{v[:full_name]}" =~ search
        end.sort { |a, b| a[:full_name] <=> b[:full_name] }
      end

      # append a () to functions so we know they are functions
      def func_list
        # ideally we should get a list of function names via the puppet loader
        function_map.map { |name, metadata| "#{metadata[:full_name]}()" }
      end

      # @return [Hash] - a map of all the functions
      def function_map
        functions = {}
        function_files.each do |file|
          obj = function_obj(file)
          # return the last matched in cases where rbenv might be involved
          functions[obj[:full_name]] = obj
        end
        functions
      end

      # @return [String] - the current module directory or directory that contains a gemfile
      def current_module_dir
        @current_module_dir ||= begin
          File.dirname(::Bundler.default_gemfile)
                                rescue ::Bundler::GemfileNotFound
                                  Dir.pwd
        end
      end

      def lib_dirs(module_dirs = modules_paths)
        dirs = module_dirs.map do |mod_dir|
          Dir["#{mod_dir}/*/lib"].entries
        end.flatten
        dirs + [puppet_debugger_lib_dir, File.join(current_module_dir, 'lib')]
      end

      # @return [Array] - returns a array of the parentname and function name
      def function_obj(file)
        namespace = nil
        name = nil
        if file =~ /\.pp/
          File.readlines(file, :encoding => "UTF-8").find do |line|
            # TODO: not getting namespace for functio
            if line.match(FUNC_NATIVE_NAME_REGEX)
              namespace, name = $1.split("::", 2)
              name = namespace if name.nil?
              namespace = "" if namespace == name
            end
          end
        elsif file.include?("lib/puppet/functions")
          File.readlines(file, :encoding => "UTF-8").find do |line|
            if line.match(FUNC_V4_NAME_REGEX)
              namespace, name = $1.split("::", 2)
              name = namespace if name.nil?
              namespace = "" if namespace == name
            end
          end
        end
        name ||= File.basename(file, File.extname(file))
        match = file.match('\/(?<mod>[\w\-\.]+)\/(lib|functions|manifests)')
        summary_match = File.read(file, :encoding => "UTF-8").match(/@summary\s(.*)/)
        summary = summary_match[1] if summary_match
        # fetch the puppet version if this is a function from puppet gem
        captures = file.match(/(puppet-[\d\.]+)/)
        file_namespace = captures[1] if captures
        mod_name = file_namespace || match[:mod]
        full_name = namespace.nil? || namespace.empty? ? name : name.prepend("#{namespace}::")
        { namespace: namespace, summary: summary, mod_name: mod_name, name: name, full_name: full_name, file: file }
      end

      private

      # load all the lib dirs so puppet can find the functions
      # at this time, this function is not being used
      def load_lib_dirs(module_dirs = modules_paths)
        lib_dirs(module_dirs).each do |lib|
          $LOAD_PATH << lib
        end
      end

      # returns a array of function files which is only required
      # when displaying the function map, puppet will load each function on demand
      # in the future we may want to utilize the puppet loaders to find these things
      def function_files
        search_dirs = lib_dirs.map do |lib_dir|
          [File.join(lib_dir, "puppet", "functions", "**", "*.rb"),
           File.join(lib_dir, "functions", "**", "*.rb"),
           File.join(File.dirname(lib_dir), "functions", "**", "*.pp"),
           File.join(lib_dir, "puppet", "parser", "functions", "*.rb")]
        end

        # add puppet lib directories
        search_dirs << [File.join(puppet_lib_dir, "puppet", "functions", "**", "*.rb"),
                        File.join(puppet_lib_dir, "puppet", "parser", "functions", "*.rb")]
        Dir.glob(search_dirs.flatten)
      end
    end
  end
end
