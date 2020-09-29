![demo](resources/puppet_debugger_long_white.png)

![demo](resources/animated-debugger-demo.gif)


**Table of Contents** 

<!-- vim-markdown-toc GFM -->

* [puppet-debugger](#puppet-debugger)
  * [Documentation](#documentation)
  * [Compatibility](#compatibility)
  * [Production usage](#production-usage)
  * [Installation](#installation)
  * [Web demo](#web-demo)
  * [Usage](#usage)
  * [Copyright](#copyright)

<!-- vim-markdown-toc -->

[![Gem Version](https://badge.fury.io/rb/puppet-debugger.svg)](https://badge.fury.io/rb/puppet-debugger)

# puppet-debugger

An interactive command line tool for evaluating and debugging the Puppet language.

## Documentation
Please visit https://docs.puppet-debugger.com for more info.

## Compatibility
Requires Puppet 5.5+, ruby 2.4+

## Production usage
The puppet debugger is a developer tool that should only be used when writing
puppet code.  Although it might seem useful, please **do not install it on your
production puppet master**—the `puppet-debugger` gem's dependencies might
conflict with your existing environment.

## Installation
`gem install puppet-debugger`


## Web demo
There is a web version of the [puppet-debugger](https://demo.puppet-debugger.com) online but is somewhat
limited at this time. In the future we will be adding lots of awesome features to the web debugger.

## Usage
The puppet debugger is a Puppet application, so once you install the gem just
fire it up by running `puppet debugger`.  If you have used `puppet apply` to
evaulate Puppet code, this replaces all of that with a simple debugger REPL
console.  This means you can type any Puppet code in the debugger and see what
it would actually do when compiling a resource.

The debugger will only parse and evaluate your code—it will not build or try to
enforce a catalog.  This has a few side affects:

1. Type and provider code will not get run.
2. Nothing is created or destroyed on your system.

`puppet debugger`

Example Usage
```
Ruby Version: 2.6.5
Puppet Version: 6.17.0
Puppet Debugger Version: 1.0.0
Created by: NWOps <corey@nwops.io>
Type "commands" for a list of debugger commands
or "help" to show the help screen.


1:>> $os
 => {
  "architecture" => "x86_64",
        "family" => "RedHat",
      "hardware" => "x86_64",
          "name" => "Fedora",
       "release" => {
     "full" => "23",
    "major" => "23"
  },
       "selinux" => {
       "config_mode" => "permissive",
     "config_policy" => "targeted",
      "current_mode" => "permissive",
           "enabled" => true,
          "enforced" => false,
    "policy_version" => "29"
  }
}
2:>> 

```

## Copyright

Copyright (c) 2018 NWOPS, LLC. See LICENSE.txt for
further details.
