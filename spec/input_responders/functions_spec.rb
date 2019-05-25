require "spec_helper"
require "puppet-debugger"
require "puppet-debugger/plugin_test_helper"

describe :functions do
  include_examples "plugin_tests"

  let(:input) do
    "md5('hello')"
  end

  let(:mod_dir) do
    File.join(fixtures_dir, "modules", "extlib")
  end

  it "runs" do
    expect(plugin.run).to be_a String
  end

  it "returns functions" do
    expect(plugin.function_map).to be_a Hash
  end

  it "sorted_list" do
    expect(plugin.sorted_list).to be_a Array
    expect(plugin.sorted_list.first).to be_a Hash
  end

  it "returns function names" do
    expect(plugin.func_list).to be_a Array
    expect(plugin.func_list.find { |m| m =~ /md5/ }).to eq("md5()")
  end

  it "execute md5" do
    debugger_output = /5d41402abc4b2a76b9719d911017c592/
    debugger.handle_input("md5('hello')")
    expect(output.string).to match(debugger_output)
  end

  it "execute swapcase" do
    debugger_output = /HELLO/
    debugger.handle_input("swapcase('hello')")
    expect(output.string).to match(debugger_output)
  end

  it "#function_obj with native function" do
    expect(plugin.function_obj(File.join(mod_dir, "functions", "dir_split.pp"))).to eq(
      { :file => File.join(mod_dir, "functions", "dir_split.pp"), :mod_name => "extlib",
        :full_name => "extlib::dir_split", :name => "extlib::dir_split", :namespace => "extlib",
        :summary => "Splits the given directory or directories into individual paths." }
    )
  end

  it "#function_obj ruby v4 without namespace" do
    expect(plugin.function_obj(File.join(mod_dir, "lib", "puppet", "functions", "echo.rb"))).to eq({ :file => File.join(mod_dir, "lib", "puppet", "functions", "echo.rb"), :mod_name => "extlib",
                                                                                                     :full_name => "echo", :name => "echo", :namespace => "", :summary => "DEPRECATED.  Use the namespaced function [`extlib::echo`](#extlibecho) instead." })
  end

  it "#function_obj ruby v4 and namespace" do
    expect(plugin.function_obj(File.join(mod_dir, "lib", "puppet", "functions", "extlib", "echo.rb"))).to eq({ :file => File.join(mod_dir, "lib", "puppet", "functions", "extlib", "echo.rb"), :mod_name => "extlib",
                                                                                                               :full_name => "extlib::echo", :name => "extlib::echo", :namespace => "extlib", :summary => nil })
  end

  it "#function_obj has puppet namespace" do
    file, _ = Puppet::Functions.method(:create_function).source_location
    dir = File.dirname(file)
    f_obj = plugin.function_obj(File.join(dir, "functions", "include.rb"))
    expect(f_obj[:mod_name]).to match(/puppet-.*/)
    expect(f_obj[:name]).to eq("include")
    expect(f_obj[:full_name]).to eq("include")
    expect(f_obj[:summary]).to be_nil
  end
end
