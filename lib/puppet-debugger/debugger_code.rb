require_relative 'code/loc'
require_relative 'code/code_range'
require_relative 'code/code_file'

  # `Pry::Code` is a class that encapsulates lines of source code and their
  # line numbers and formats them for terminal output. It can read from a file
  # or method definition or be instantiated with a `String` or an `Array`.
  #
  # In general, the formatting methods in `Code` return a new `Code` object
  # which will format the text as specified when `#to_s` is called. This allows
  # arbitrary chaining of formatting methods without mutating the original
  # object.
  class DebuggerCode
    class << self
     # include MethodSource::CodeHelpers

      # Instantiate a `Code` object containing code loaded from a file or
      # Pry's line buffer.
      #
      # @param [String] filename The name of a file, or "(pry)".
      # @param [Symbol] code_type The type of code the file contains.
      # @return [Code]
      def from_file(filename, code_type = nil)
        code_file = CodeFile.new(filename, code_type)
        new(code_file.code, 1, code_file.code_type, filename)
      end

      # Instantiate a `Code` object containing code loaded from a file or
      # Pry's line buffer.
      #
      # @param [String] source code".
      # @param [Symbol] code_type The type of code the file contains.
      # @return [Code]
      def from_string(code, code_type = nil)
        new(code, 1, code_type)
      end
    end

    # @return [Symbol] The type of code stored in this wrapper.
    attr_accessor :code_type, :filename

    # Instantiate a `Code` object containing code from the given `Array`,
    # `String`, or `IO`. The first line will be line 1 unless specified
    # otherwise. If you need non-contiguous line numbers, you can create an
    # empty `Code` object and then use `#push` to insert the lines.
    #
    # @param [Array<String>, String, IO] lines
    # @param [Integer?] start_line
    # @param [Symbol?] code_type
    def initialize(lines = [], start_line = 1, code_type = :ruby, filename=nil)
      if lines.is_a? String
        lines = lines.lines
      end
      @lines = lines.each_with_index.map { |line, lineno|
        LOC.new(line, lineno + start_line.to_i) }
      @code_type = code_type
      @filename = filename
      @with_file_reference = nil
      @with_marker = @with_indentation = nil
    end

    # Append the given line. +lineno+ is one more than the last existing
    # line, unless specified otherwise.
    #
    # @param [String] line
    # @param [Integer?] lineno
    # @return [String] The inserted line.
    def push(line, lineno = nil)
      if lineno.nil?
        lineno = @lines.last.lineno + 1
      end
      @lines.push(LOC.new(line, lineno))
      line
    end
    alias << push

    # Filter the lines using the given block.
    #
    # @yield [LOC]
    # @return [Code]
    def select(&block)
      alter do
        @lines = @lines.select(&block)
      end
    end

    # Remove all lines that aren't in the given range, expressed either as a
    # `Range` object or a first and last line number (inclusive). Negative
    # indices count from the end of the array of lines.
    #
    # @param [Range, Integer] start_line
    # @param [Integer?] end_line
    # @return [Code]
    def between(start_line, end_line = nil)
      return self unless start_line

      code_range = CodeRange.new(start_line, end_line)

      alter do
        @lines = @lines[code_range.indices_range(@lines)] || []
      end
    end

    # Take `num_lines` from `start_line`, forward or backwards.
    #
    # @param [Integer] start_line
    # @param [Integer] num_lines
    # @return [Code]
    def take_lines(start_line, num_lines)
      start_idx =
        if start_line >= 0
          @lines.index { |loc| loc.lineno >= start_line } || @lines.length
        else
          [@lines.length + start_line, 0].max
        end

      alter do
        @lines = @lines.slice(start_idx, num_lines)
      end
    end

    # Remove all lines except for the +lines+ up to and excluding +lineno+.
    #
    # @param [Integer] lineno
    # @param [Integer] lines
    # @return [Code]
    def before(lineno, lines = 1)
      return self unless lineno

      select do |loc|
        loc.lineno >= lineno - lines && loc.lineno < lineno
      end
    end

    # Remove all lines except for the +lines+ on either side of and including
    # +lineno+.
    #
    # @param [Integer] lineno
    # @param [Integer] lines
    # @return [Code]
    def around(lineno, lines = 1)
      return self unless lineno

      select do |loc|
        loc.lineno >= lineno - lines && loc.lineno <= lineno + lines
      end
    end

    # Remove all lines except for the +lines+ after and excluding +lineno+.
    #
    # @param [Integer] lineno
    # @param [Integer] lines
    # @return [Code]
    def after(lineno, lines = 1)
      return self unless lineno

      select do |loc|
        loc.lineno > lineno && loc.lineno <= lineno + lines
      end
    end

    # Remove all lines that don't match the given `pattern`.
    #
    # @param [Regexp] pattern
    # @return [Code]
    def grep(pattern)
      return self unless pattern
      pattern = Regexp.new(pattern)

      select do |loc|
        loc.line =~ pattern
      end
    end

    # Format output with line numbers next to it, unless `y_n` is falsy.
    #
    # @param [Boolean?] y_n
    # @return [Code]
    def with_line_numbers(y_n = true)
      alter do
        @with_line_numbers = y_n
      end
    end

    # Format output with line numbers next to it, unless `y_n` is falsy.
    #
    # @param [Boolean?] y_n
    # @return [Code]
    def with_file_reference(y_n = true)
      alter do
        @with_file_reference = y_n
      end
    end

    # Format output with a marker next to the given +lineno+, unless +lineno+ is
    # falsy.
    #
    # @param [Integer?] lineno
    # @return [Code]
    def with_marker(lineno = 1)
      alter do
        @with_marker   = !!lineno
        @marker_lineno = lineno
      end
    end

    # Format output with the specified number of spaces in front of every line,
    # unless `spaces` is falsy.
    #
    # @param [Integer?] spaces
    # @return [Code]
    def with_indentation(spaces = 0)
      alter do
        @with_indentation = !!spaces
        @indentation_num  = spaces
      end
    end

    # @return [String]
    def inspect
      Object.instance_method(:to_s).bind(self).call
    end

    # @return [Integer] the number of digits in the last line.
    def max_lineno_width
      @lines.length > 0 ? @lines.last.lineno.to_s.length : 0
    end

    # @return [String] a formatted representation (based on the configuration of
    #   the object).
    def to_s
      print_to_output("", false)
    end

    # @return [String] a (possibly highlighted) copy of the source code.
    def highlighted
      print_to_output("", true)
    end

    def add_file_reference
      "From file: #{File.basename(filename)}\n"
    end

    # Writes a formatted representation (based on the configuration of the
    # object) to the given output, which must respond to `#<<`.
    def print_to_output(output, color=false)
      output << add_file_reference if @with_file_reference
      @lines.each do |loc|
        loc = loc.dup
        loc.add_line_number(max_lineno_width) if @with_line_numbers
        loc.add_marker(@marker_lineno)        if @with_marker
        loc.indent(@indentation_num)          if @with_indentation
        output << loc.line
        output << "\n"
      end
      output
    end

    # Get the comment that describes the expression on the given line number.
    #
    # @param [Integer] line_number (1-based)
    # @return [String] the code.
    def comment_describing(line_number)
      self.class.comment_describing(raw, line_number)
    end

    # Get the multiline expression that starts on the given line number.
    #
    # @param [Integer] line_number (1-based)
    # @return [String] the code.
    def expression_at(line_number, consume = 0)
      self.class.expression_at(raw, line_number, :consume => consume)
    end

    # Get the multiline expression that starts on the given line number.
    #
    # @param [Integer] line_number (1-based)
    # @return [String] the code.
    def self.expression_at(raw, line_number, consume = 0)
      #self.class.expression_at(raw, line_number, :consume => consume)
      raw
    end

    # Get the (approximate) Module.nesting at the give line number.
    #
    # @param [Integer] line_number line number starting from 1
    # @param [Module] top_module the module in which this code exists
    # @return [Array<Module>] a list of open modules.
    def nesting_at(line_number, top_module = Object)
      Indent.nesting_at(raw, line_number)
    end

    # Return an unformatted String of the code.
    #
    # @return [String]
    def raw
      @lines.map(&:line).join("\n") << "\n"
    end

    # Return the number of lines stored.
    #
    # @return [Integer]
    def length
      @lines ? @lines.length : 0
    end

    # Two `Code` objects are equal if they contain the same lines with the same
    # numbers. Otherwise, call `to_s` and `chomp` and compare as Strings.
    #
    # @param [Code, Object] other
    # @return [Boolean]
    def ==(other)
      if other.is_a?(Code)
        other_lines = other.instance_variable_get(:@lines)
        @lines.each_with_index.all? { |loc, i| loc == other_lines[i] }
      else
        to_s.chomp == other.to_s.chomp
      end
    end

    # Forward any missing methods to the output of `#to_s`.
    def method_missing(name, *args, &block)
      to_s.send(name, *args, &block)
    end
    undef =~

    protected

    # An abstraction of the `dup.instance_eval` pattern used throughout this
    # class.
    def alter(&block)
      dup.tap { |o| o.instance_eval(&block) }
    end
  end
