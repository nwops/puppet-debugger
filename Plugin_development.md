<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Plugin Development Guide](#plugin-development-guide)
  - [Creating a new Plugin](#creating-a-new-plugin)
  - [Creating a plugin as a gem](#creating-a-plugin-as-a-gem)
    - [Testing your gem plugin code](#testing-your-gem-plugin-code)
  - [Creating a plugin to be merged into core](#creating-a-plugin-to-be-merged-into-core)
  - [New Plugin Instructions](#new-plugin-instructions)
  - [Required Directory layout](#required-directory-layout)
  - [Run Method](#run-method)
  - [Required Constants](#required-constants)
    - [Command words](#command-words)
    - [Summary](#summary)
    - [Command groups](#command-groups)
  - [Plugin API](#plugin-api)
  - [Debugger Hooks](#debugger-hooks)
    - [Hook Events](#hook-events)
  - [Calling other plugins](#calling-other-plugins)
    - [Indirectly](#indirectly)
    - [Directly](#directly)
  - [Testing your plugin code](#testing-your-plugin-code)
  - [Examples](#examples)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Plugin Development Guide
The puppet debugger now features a plugin system.  This was added to support future expansion
via third party developers.  

At this time there is only a single type of plugin called InputResponder, but in the future there will be additional types of plugins.

## Creating a new Plugin
There are two ways to package a plugin.

1. create a core plugin to be merged into the puppet-debugger codebase
2. create a external plugin packaged as a gem and distributed via gem server such as rubygems.org

If you think your plugin should be in the core please create a PR and ensure you have unit test coverage for your plugin.

## Creating a plugin as a gem
For reference you can use the following doc [How to create a gem](http://bundler.io/v1.15/guides/creating_gem.html)

1. Create the gem via `bundle gem <plugin_name>`

    ```
    bundle gem --test=rspec fancy_plugin
    cd fancy_plugin
    mkdir -p lib/plugins/puppet-debugger/input_responders
    
    ```
    
2. Add the following to your Gemfile
    ```ruby
    group :dev, :test do
      gem 'puppet-debugger'
      gem 'pry'
      gem 'CFPropertyList'
      gem 'rake'
      gem 'rspec', '>= 3.6'
      # loads itself so you don't have to update RUBYLIB path
      gem 'your_plugin', path: './'
    end
    ```
    
3. bundle install    
2. Follow the [New Plugin Instructions](#new-plugin-instructions)
3. Version the gem
4. Package and push the gem to rubygems.
5. Tell others about it.

### Testing your gem plugin code
In order to test your plugin gem with the puppet-debugger you will need to add your gem's lib path to the RUBYLIB environment variable.

`RUBYLIB=~/path_to_gem/lib:$RUBYLIB puppet debugger`

Once this is set, puppet-debugger will discover your gem automatically and you should see it in the commands list.

Note: if you add the your plugin to the Gemfile as shown above in step 2 there is no need to set the RUBYLIB variable.

## Creating a plugin to be merged into core
1. Fork the puppet-debugger repo
1. Follow the [New Plugin Instructions](#new-plugin-instructions)
2. Submit a PR 


## New Plugin Instructions
1. Create a file with the name of your plugin lib/plugins/puppet-debugger/input_responders/fancy_plugin.rb
2. Add the following content to the plugin.

    ```
    require 'puppet-debugger/input_responder_plugin'
    module PuppetDebugger
      module InputResponders
        class Fancy < InputResponderPlugin
          COMMAND_WORDS = %w(fancy)
          SUMMARY = 'This is a fancy plugin'
          COMMAND_GROUP = :tools
    
          def run(args = [])
            'hello from a fancy plugin'
          end
        end
      end
    end
    ```

4. ensure the class name is the same as the file name which follows ruby best practices
5. Add words to the COMMAND_WORDS constant which will be used to run your plugin from the debugger.
6. Add a short summary that describes your plugin's functionality
7. Add a group to which your plugin should belong to.  This appears in the `commands` plugin output.
8. You must implement the [Run Method](#run-method).  This method is called when your plugin's command word is entered.
9. Write unit tests to validate your code works.

You can review the [Required Constants](#required-constants) docs for more info.

## Required Directory layout
In order for you plugin to be discovered you must create this exact directly layout.  Your plugin file must be in
the following directory `lib/plugins/puppet-debugger/input_responders/`

If you are packaging as a gem you must still provide this directory layout in addition to whatever other supporting files
are also in your gem.

## Run Method

Your plugin must override the run method.  When your plugin is executed, an array is passed as the args variable.
This variable contains all the arguments that can be supplied to your plugin.  It is not required that you utilize
the `args` variable as some plugins run without arguments but it must be the only argument.

For example: `fancy hello there sir` would be passed as ['hello', 'there', 'sir'] to your plugin's run method.


```ruby
def run(args = [])
  greeting = args.first
  "#{greeting} from a fancy plugin"
end

```

## Required Constants

### Command words
These are the words the user will enter to interact with your plugin.  You can provide
multiple words but only the first word will show up in the commands help screen.

Example:

```
2:>> classes
[
  [0] "settings",
  [1] "__node_regexp__foo"
]
2:>>
```

Ensure you set the following in your plugin class
`COMMAND_WORDS = %w(fancy werd)`
 
### Summary
Set the Summary Constant to tell users what your plugin does.  This will show up in the commands help
screen.

```bash
Tools
   fancy            This is a fancy plugin that does nothing
```

`SUMMARY = 'This is a fancy plugin that does nothing'`
    

### Command groups
The group name appears on the commands help screen and categories tools
based on the value of the command_group constant ie. `COMMAND_GROUP = :tools`

Below is a list of groups you can use to categorize your plugin.  Groups are created dynamically by simply supplying
a new group name.

* `:help`
* `:tools`
* `:scope`
* `:node`
* `:environment`
* `:editing`
* `:context`
 
## Plugin API
Every plugin has access to debugger's central objects.  You may need to use these objects to implement your plugin.

Objects exposed that you might want access to:

* debugger     (direct use is not recommended)
* scope        (The puppet scope object)        
* node         (The puppet node object)       
* environment  (The puppet environment object)
* facts        (The puppet facts hash)    
* compiler     (The puppet compiler object)    
* catalog      (The puppet catalog)
* function_map (Current map of functions)

While you do have access to the `debugger` object itself and everything inside this object.  I would recommend not using the debugger
object directly since the debugger code base is changing rapidly.  Usage can result in a broken plugin.  If you are using
the debugger object directly please open an issue so we can create a interface for your use case to provide future compatibility. 

## Debugger Hooks
In addition the plugin API you can run code during certain events in the debugger lifecycle.  This allows you to run your plugin code
only when certain actions occur.  Please remember that your hook's code will be run multiple times during the debugger's session.

If your hook code takes a while to run, please ensure it runs fast or throw the code into a separate thread if applicable.

### Hook Events
Below is a list of the current events that you can hook into.

 * after_output  (After the debugger has returned control back to the console)
 * before_eval   (Occurs before puppet evaluates the code)
 * after_eval    (Occurs after puppet evaluates the code and before the debugger sends the output to the console)
 
To hook into a debugger event you just add a hook via the `add_hook` method with the name of the event you wish to hook into.
 
An example of this pattern is below.  In this example, when `graph` is entered by the user, the plugin toggles the execution
of creating a graph after the output is sent to the console.  The toggle either adds or deletes the hook.  Since creating the graph
can take a while we also create a thread so we don't hold the console hostage.  A new graph is created each time a puppet evaluation occurs.

```ruby
def run(args = [])
    toggle_status
end

def toggle_status
    status = !status
    if status
      add_hook(:after_eval, :create_graph) do |code, debugger|
        # ensure we only start a single thread, otherwise they could stack up
        # and try to write to the same file.
        Thread.kill(@graph_thread) if @graph_thread
        @graph_thread = Thread.new { create_html(create_graph_content) }
      end
      out = "Graph mode enabled at #{get_url}"
    else
      delete_hook(:after_output, :create_graph_content)
      out = "Graph mode disabled"
    end
    out
end
```

## Calling other plugins
There are two ways to call other plugins.

### Indirectly 
You can call another plugin via the handle_input method ie. `debugger.handle_input('help')`.  Just use the plugin command word
and any arguments that it takes to call the plugin.

This makes the debugger handle the loading of the plugin and returns formatted output which is most of the time what you want.
This does not send any output to the console so it is up to you to decide what to do next.

### Directly
Should you want to call the plugin directly you can bypass the `handle_input` method and use the `plugin_from_command`
to return the plugin instance.

```
# get a plugin instance
play_plugin = PuppetDebugger::InputResponders::Commands.plugin_from_command('play')

# execute the plugin  
args = ['https://gists.github.com/sdalfsdfadsfds.txt']
# pass an instance of the debugger (always do this)
output = plugin.execute(args, debugger)

```

If the command used to find the plugin is incorrect a `PuppetDebugger::Exception::InvalidCommand` error will be raised.

## Testing your plugin code
1. Create a new rspec test file as `spec/input_responders/plugin_name_spec.rb`

At a minimum you will need the following test code.  By including the shared examples `plugin_tests' you will automatially
inherit some basic tests for your plugin.  However, you will need to further test your code by creating additional
tests.

Replace `:plugin_name ` with the name of your plugin command word.

```ruby
require 'spec_helper'
require 'puppet-debugger'
require 'puppet-debugger/plugin_test_helper'

describe :plugin_name do
  include_examples "plugin_tests"
  let(:args) { [] }
  
  # you must test your run implementation similar to this, if you have args please set them in the args let blocks
  it 'works' do
    expect(plugin.run(args)).to eq('????')
  end
end
  
```

## Examples
There are plenty of examples of plugins that are in the core code base.  See lib/plugins/puppet-debugger/input_responders 
for examples.