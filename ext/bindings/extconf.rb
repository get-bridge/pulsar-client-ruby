require 'mkmf-rice'
require 'rbconfig'

DEFAULT_PULSAR_DIRS = if RbConfig::CONFIG['host_os'] =~ /darwin/
  ['/opt/homebrew/opt/libpulsar']
else
  ['/usr', '/usr/local']
end.freeze

def existing_dir(paths)
  paths.find { |path| path && File.directory?(path) }
end

pulsar_dir = with_config('pulsar-dir') || existing_dir(DEFAULT_PULSAR_DIRS)

include_dir, = dir_config(
  'pulsar',
  pulsar_dir && File.join(pulsar_dir, 'include'),
  pulsar_dir && File.join(pulsar_dir, 'lib')
)

client_header = File.join(include_dir.to_s, 'pulsar', 'Client.h')

abort 'libpulsar headers not found' unless File.exist?(client_header)
abort 'libpulsar library not found' unless have_library('pulsar')

$CXXFLAGS += ' -std=c++17 '

create_makefile('pulsar/bindings')
