require 'mkmf-rice'
$LOCAL_LIBS << "-lpulsar"
$CXXFLAGS += " -std=c++17 " unless $CXXFLAGS.include?("-std=")
create_makefile('pulsar/bindings')
