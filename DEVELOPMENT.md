## Testing

In order to test you need to export the following environment variable when in the project directory.
The puppet command will then load the face so you can use with `puppet debugger`

`export RUBYLIB=lib/`

`puppet debugger`


## Vendoring libraries
gem unpack pluginator -​-target vendor/gems
gem specification --ruby pluginator > vendor/gems/pluginator/pluginator.gemspec
