#!/usr/bin/ruby

# example usage:
# wget http://something/...
# cat file.html | prepare_file.rb > expected/test_something.html

str = STDIN.read()
print(Regexp.escape(str))