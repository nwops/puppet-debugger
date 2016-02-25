# puppet-repl

A interactive command line tool for evaluating the puppet language.

## Compatibility
Requires Puppet 3.8+ and only uses the future parser.

## Installation
`gem install puppet-repl`

## Load path
puppet-repl will load all functions from your basemodulepath and environmentpath.

This means if you run `puppet module install puppetlabs-stdlib` and they will be available
in the repl.

## Usage
Puppet-repl will only parse and evaulate your code.  It will not build a catalog
and try to enforce the catalog. This has a few side affects.

1. Type and provider code will not get run.
2. Nothing is created or destroyed on your system.

`prepl`

Example Usage
```
MacBook-Pro-2/tmp % prepl
Puppet Version: 4.2.2
Puppet Repl Version: 0.0.1
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "types", "reset", "help" for more information.

>> file{'/tmp/test2': ensure => present}
 => File['/tmp/test2']
>> ['/tmp/test3', '/tmp/test4'].each |String $path| { file{$path: ensure => present} }
 =>
/tmp/test3
/tmp/test4

```

## Using Variables

```
MacBook-Pro-2/tmp % prepl
Puppet Version: 4.2.2
Puppet Repl Version: 0.0.1
Created by: NWOps <corey@nwops.io>
Type "exit", "functions", "types", "reset", "help" for more information.

>> $config_file = '/etc/httpd/httpd.conf'
 => /etc/httpd/httpd.conf
>> file{$config_file: ensure => present, content => 'hello'}
 => File['/etc/httpd/httpd.conf']
>>
```

## Using functions
Functions will run and produce the desired output.  If you type the word `functions`
a list of available functions will be displayed on the screen.

```
>> split('hello/there/one/two/three','/')
 => ["hello", "there", "one", "two", "three"]

```
## Duplicate resource error
Just like normal puppet code you cannot create duplicate resources.

```
>> file{'/tmp/failure2.txt': ensure => present}
 => Evaluation Error: Error while evaluating a Resource Statement, Duplicate declaration: File[/tmp/failure2.txt] is already declared in file :1; cannot redeclare at line 1 at line 1:1

```
You can reset the parser by running `reset` within the repl without having to exit.

## Troubleshooting

## Forward
I was just playing around and created this simple tool.  Its alpha quality,
and a ton of features need to be added. Please create a issue if you see a bug or feature that should be added.

Pull requests welcomed.

## Copyright

Copyright (c) 2016 Corey Osman. See LICENSE.txt for
further details.
