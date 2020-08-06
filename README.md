# RTFDoc

Generate beautiful static documentation for your APIs.

## Installation

You can install the gem globally using the following command. It will install the `rtfdoc` binary for generating new projects from scratch.

```
$ gem install rtfdoc
```

## Usage

You can scaffold a new project using `rtfdoc bootstrap <project_name>`. It will create a skeleton for your project, and generate needed configuration files.

Once in your project directory, you can install ruby dependencies using `bundle install` and javascript dependencies using `yarn install`. Then we want to stub the binary by running `bundle binstubs bundler rtfdoc`.
And finally, you'll copy the assets source by running `bin/rtfdoc install`.

By convention, you should put your documentation content under the `content/` directory. If you don't follow this convention, don't forget to modify the configuration file as well.

When you're done writing your documentation, you can define the order they will appear on your page using the ` config.yml` file (see `examples/`).

Finally, you can use `yarn run build` to generate the HTML/CSS/JS files.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ccocchi/rtfdoc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RTFDoc project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ccocchi/rtfdoc/blob/master/CODE_OF_CONDUCT.md).
