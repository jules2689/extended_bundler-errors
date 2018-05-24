# ExtendedBundler::Errors

Extended Bundler Errors is a `bundler` plugin that makes gem installation errors more actionable, educative, and all around easier to understand.

Previously when gems fail, `bundler` would simply tell you it failed and give you any output from the gem itself. This often includes C traces from native extensions.

These are hard to follow, particularly for people new to Ruby, because it requires you to understand the underlying system, programs in use (Imagemagick, SSL libraries, parsers, etc), and the output is simply verbose.

This gem instead will try to match the output of the gem to a series of handlers (see `lib/extended_bundler/handlers` for a list). Each handler is specific to a gem, an matches one of many potential output. Once matched, we replace the error with something that explains the known problem, how to fix it, and (if possible) include a link to the original output.

Here is an example:

Before when RMagick fails to install, you got a verbose log.

![Before this plugin, RMagick failures were cryptic and confusing](https://user-images.githubusercontent.com/3074765/40488035-c89a6678-5f33-11e8-89fc-f66c054d8765.png)

After when it fails to install you get a specific, actionable reason and step-by-step guide on how to handle it.

![After This Plugin, RMagick has better errors](https://user-images.githubusercontent.com/3074765/40489293-c8cf8e9a-5f36-11e8-88f5-fceed052aa24.png)

## Installation

While this is a gem, you need to install it as a plugin:

`bundler plugin install extended_bundler-errors`

OR

`bundler plugin install extended_bundler-errors --git=https://github.com/Shopify/extended_bundler-errors.git`

## Development

It is recommended to install from `git` and work directly in a `bundle install` run.

You can also...

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/extended_bundler-errors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ExtendedBundler::Errors project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/extended_bundler-errors/blob/master/CODE_OF_CONDUCT.md).
