<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [puppet-repl](#puppet-repl)
  - [Compatibility](#compatibility)
  - [Installation](#installation)
  - [Load path](#load-path)
  - [Usage](#usage)
  - [Using Variables](#using-variables)
    - [Listing variables](#listing-variables)
  - [Using functions](#using-functions)
  - [Duplicate resource error](#duplicate-resource-error)
  - [Setting the puppet log level](#setting-the-puppet-log-level)
  - [Troubleshooting](#troubleshooting)
  - [Forward](#forward)
  - [Copyright](#copyright)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

[![Build Status](https://travis-ci.org/nwops/puppet-repl.png)](https://travis-ci.org/nwops/puppet-repl)
# puppet-repl

A interactive command line tool for evaluating the puppet language.

## Compatibility
Requires Puppet 3.8+ and only uses the future parser.

## Production usage
The puppet repl is a developer tool that should only be used when writing puppet code.  Although it might seem useful
to install on your production puppet master. Please do not install because of the puppet-repl gem dependencies that might conflict with your existing environment.

## Installation
`gem install puppet-repl`

## Load path
puppet-repl will load all functions from your basemodulepath and environmentpath.

This means if you run `puppet module install puppetlabs-stdlib` and they will be available
in the repl.  

## Interactive demo
I have put together a repo with a few setup instructions that will assist you in setting up a "mock" environment
for usage with the puppet-repl.  This was originally intended when giving a demo of the repl, but also seems
useful for other people. 

https://github.com/nwops/puppet-repl-demo

## Usage
Puppet-repl will only parse and evaulate your code.  It will not build a catalog
and try to enforce the catalog. This has a few side affects.

1. Type and provider code will not get run.
2. Nothing is created or destroyed on your system.

`prepl`

Example Usage
```
MacBook-Pro-2/tmp % prepl
Ruby Version: 2.0.0
Puppet Version: 3.8.5
Puppet Repl Version: 0.0.7
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "reset", "help" for more information.

>> ['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }
  => [
     [0] "/tmp/test3",
     [1] "/tmp/test4"
 ]
 >>

```

## Using Variables

```
MacBook-Pro-2/tmp % prepl
Ruby Version: 2.0.0
Puppet Version: 3.8.5
Puppet Repl Version: 0.0.7
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "vars", "krt", "facts", "reset", "help" for more information.

>>

>> $config_file = '/etc/httpd/httpd.conf'
 => "/etc/httpd/httpd.conf"
 >> file{$config_file: ensure => present, content => 'hello'}
  => Puppet::Type::File {
                        path => "/etc/httpd/httpd.conf",
                    provider => posix,
                      ensure => present,
                     content => "{md5}5d41402abc4b2a76b9719d911017c592",
                    checksum => nil,
                      backup => "puppet",
                     replace => true,
                       links => manage,
                       purge => false,
                sourceselect => first,
                   show_diff => true,
        validate_replacement => "%",
          source_permissions => use,
     selinux_ignore_defaults => false,
                    loglevel => notice,
                        name => "/etc/httpd/httpd.conf",
                       title => "/etc/httpd/httpd.conf"
 }
 >>
```
### Listing variables
To see the current variables in the scope use the  `vars` keyword.

```
>> $var1 = 'value'
=> value
>> $var2 = {'key1' => 'value1'}
=> {"key1"=>"value1"}
>> vars
"Facts were removed for easier viewing"
{
"datacenter"  => "datacenter1",
"facts"       => "removed by the puppet-repl",
"module_name" => "",
"name"        => "main",
"title"       => "main",
"trusted"     => {
      "authenticated" => "local",
      "certname"      => nil,
      "domain"        => nil,
      "extensions"    => {},
      "hostname"      => nil
      },
"var1"        => "value",
"var2"        => {
  "key1" => "value1"
  }
}

```
## Using functions
Functions will run and produce the desired output.  If you type the word `functions`
a list of available functions will be displayed on the screen.

```
>> split('hello/there/one/two/three','/')
 => ["hello", "there", "one", "two", "three"]

```

So you can imagine how much fun this can be trying out different types of functions.

## Duplicate resource error
Just like normal puppet code you cannot create duplicate resources.

```
>> file{'/tmp/failure2.txt': ensure => present}
 => Evaluation Error: Error while evaluating a Resource Statement, Duplicate declaration: File[/tmp/failure2.txt] is already declared in file :1; cannot redeclare at line 1 at line 1:1

```
You can reset the parser by running `reset` within the repl without having to exit.

## Setting the puppet log level
If you want to see what puppet is doing behind the scenes you can set the log level
via `:set loglevel debug`.  Valid log levels are `debug`, `info`, `warning` and other
levels defined in puppet [config reference](https://docs.puppetlabs.com/puppet/4.4/reference/configuration.html#loglevel) .

```
>> hiera('value')
 => foo
>> :set loglevel debug
loglevel debug is set
>> hiera('value')
Debug: hiera(): Looking up value in YAML backend
Debug: hiera(): Looking for data source nodes/foo.example.com
Debug: hiera(): Found value in nodes/foo.example.com
 => foo
```
## Troubleshooting

## Forward
I was just playing around and created this simple tool.  Its beta quality,
and a ton of features need to be added. Please create a issue if you see a bug or feature that should be added.

Pull requests welcomed.

## Copyright

Copyright (c) 2016 Corey Osman. See LICENSE.txt for
further details.
