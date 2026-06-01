require 'mkmf-rice'
$LOCAL_LIBS << "-lpulsar"
$CXXFLAGS += " -std=c++17 "
create_makefile('pulsar/bindings')
