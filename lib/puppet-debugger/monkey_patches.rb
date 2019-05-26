# monkey patch in some color effects string methods
class String
  def red
    "\033[31m#{self}\033[0m"
  end

  def bold
    "\033[1m#{self}\033[22m"
  end

  def black
    "\033[30m#{self}\033[0m"
  end

  def green
    "\033[32m#{self}\033[0m"
  end

  def cyan
    "\033[36m#{self}\033[0m"
  end

  def yellow
    "\033[33m#{self}\033[0m"
  end

  def warning
    yellow
  end

  def fatal
    red
  end

  def info
    green
  end

  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/

    split('_').map(&:capitalize).join
  end
end

# Bolt plans utilize the PAL Script Compiler to compile the code and thus
# don't store a catalog with the scope.  This is due to not needing the catalog
# in the scope.  The debugger relies on the catalog being present in the scope
# and thus uses all the methods to discover various data in the catalog
# We monkey patch in a catalog here instead of changing our API for simplicity.
class Puppet::Parser::ScriptCompiler
  def catalog
    @catalog ||= Puppet::Resource::Catalog.new(@node_name, @environment, 'bolt')
  end
end