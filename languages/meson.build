# Meson: a C library, its executable, and a test.
project('inventory', 'c',
  version : '1.4.0',
  default_options : ['c_std=c11', 'warning_level=3', 'buildtype=release'])

cc = meson.get_compiler('c')
sqlite = dependency('sqlite3', version : '>=3.40')
threads = dependency('threads')

conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set10('ENABLE_EXPORT', get_option('export'))
configure_file(output : 'config.h', configuration : conf)

inc = include_directories('include')
lib = static_library('inventory', ['src/stock.c', 'src/reorder.c'],
  include_directories : inc,
  dependencies : [sqlite, threads])

exe = executable('inventory', 'src/main.c',
  include_directories : inc,
  link_with : lib,
  install : true)

test('stock', executable('stock_test', 'tests/stock_test.c', link_with : lib, include_directories : inc))
