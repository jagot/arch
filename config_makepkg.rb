#!/usr/bin/env ruby

require 'parseconfig'

config = ParseConfig.new('/etc/makepkg.conf.orig')
cflags = config.params['CFLAGS']
cflags.sub! 'x86-64', 'native'
cflags.sub! '-mtune=generic ', ''
cflags += ' -D_FORTIFY_SOURCE=2'
config.params['CFLAGS'] = cflags
config.params['CXXFLAGS'] = '${CFLAGS}'
config.params['MAKEFLAGS'] = '-j4'
config.params['PKGEXT'] = '.pkg.tar' # We don't want compression of
                                     # locally built packages

File.open('/etc/makepkg.conf', 'w') do |file|
  config.write file # Saving this way breaks the config file (and all
                    # comments are lost).
end
