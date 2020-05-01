# chip-8

This is a basic Chip-8 emulator written in Crystal. Rendering is performed using SFML through CrSFML. Sound is not currently supported.

## Installation

First, you must install SFML. Next, simply clone the repo, run `shards install`, then `shards build`.

## Usage

After building, you'll be left with an executable in `bin/chip-8`. The executable takes a path to a Chip-8 rom as its only argument, so simply execute with `bin/chip-8 path/to/rom`.

## Contributing

1. Fork it (<https://github.com/mattrberry/chip-8/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Matthew Berry](https://github.com/mattrberry) - creator and maintainer
