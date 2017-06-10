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
  - [Available Scope](#available-scope)
  - [Calling other plugins](#calling-other-plugins)
    - [Indirectly](#indirectly)
    - [Directly](#directly)
  - [Testing your plugin code](#testing-your-plugin-code)

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
    bundle gem fancy_plugin
    cd fancy_plugin
    mkdir -p lib/puppet-debugger/input_responders
    
    ```

2. Follow the [New Plugin Instructions](#new-plugin-instructions)
3. Version the gem
4. Package and push the gem to rubygems.
5. Tell others about it.

### Testing your gem plugin code
In order to test your plugin gem with the puppet-debugger you will need to add your gem's lib path to the RUBYLIB environment variable.

`RUBYLIB=~/path_to_gem/lib:$RUBYLIB puppet debugger`

Once this is set, puppet-debugger will discover your gem automatically and you should see it in the commands list.


## Creating a plugin to be merged into core
1. Fork the puppet-debugger repo
1. Follow the [New Plugin Instructions](#new-plugin-instructions)
2. Submit a PR 


## New Plugin Instructions
1. Create a file with the name of your plugin lib/puppet-debugger/input_responders/fancy_plugin.rb
2. Add the following content to the plugin.

    ```
    require 'puppet-debugger/input_responder_plugin'
    module PuppetDebugger
      module InputResponders
        class FancyPlugin < InputResponderPlugin
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
the following directory `lib/puppet-debugger/input_responders/`

If you are packaging as a gem you must still provide this directory layout in addition to whatever other supporting files
are also in your gem.

## Run Method

Your plugin must override the following method.  When your plugin is run, an array is passed as the args variable.
This variable contains all the arguments that can be supplied to your plugin.  It is not required that you use
the `args` variable as some plugins run without arguments.

For example: `fancy arg1 arg2 arg3` would be passed as ['hello', 'arg2', 'arg3'] to the run method in your plugin.


```
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
 
## Available Scope
Every plugin has access to the debugger scope.  This means that you can access everything in the debugger codebase.
When you want access to this scope you must use the `debugger` object. 

Useful objects you might want access to

* scope             `debugger.scope`
* node              `debugger.node`
* environment       `debugger.environment`
* facts             `debugger.facts`
* compiler          `debugger.compiler`

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