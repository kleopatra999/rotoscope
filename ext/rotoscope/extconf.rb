# frozen_string_literal: true
require "mkmf"

LIBDIR     = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

# # setup constant that is equal to that of the file path that holds that static libraries that will need to be compiled
# # against
# LIB_DIRS = [LIBDIR, File.expand_path(File.join(File.dirname(__FILE__), "lib"))]
# HEADER_DIRS = [INCLUDEDIR, File.expand_path(File.join(File.dirname(__FILE__), "include"))]

# # array of all libraries that the C extension should be compiled against
# libs = ['-lz']

# dir_config('rotoscope', HEADER_DIRS, LIB_DIRS)

# # iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
# libs.each do |lib|
#   $LOCAL_LIBS << "#{lib} " # rubocop:disable Style/GlobalVars
# end

dir_config('z')

unless have_header('zlib.h') && have_header('zconf.h')
  abort "zlib is missing.  please install zlib"
end

unless have_library('z', 'gzopen')
  abort "zlib is missing.  please install zlib"
end

create_makefile('rotoscope/rotoscope')
