# Meson 1.9 — syntax showcase: a C library, its executable, options and tests.
# TODO: split the tests into their own subdir
# FIXME: pin the sqlite version once the CI image is updated

project('inventory', ['c', 'cpp'],
  version : '1.4.0',
  license : ['MIT', 'Apache-2.0'],
  meson_version : '>= 1.1.0',
  default_options : [
    'c_std=c11',
    'cpp_std=c++17',
    'warning_level=3',
    'buildtype=release',
    'werror=false',
  ])

# ── Literals ──
integer_dec = 42
integer_hex = 0xFF
integer_oct = 0o755
integer_bin = 0b1010
negative = -7
truthy = true
falsy = false
plain = 'single quoted string'
escaped = 'it\'s a tab:\t, newline:\n, backslash:\\, hex:\x41, unicode:é, big:\U0001F4E6'
multiline = '''
A multi-line string, with 'quotes' and no escapes processing: \n stays literal.
Stock level: @0@
'''
formatted = 'Version @0@ built @1@'.format(meson.project_version(), 'today')
fstring = f'inventory @integer_dec@ is @plain@'
empty_list = []
numbers = [1, 2, 3]
mixed = ['a', 1, true, [4, 5]]
empty_dict = {}
flags = {'debug': true, 'level': 3, 'name': 'inv'}

# ── Operators ──
sum = 1 + 2
diff = 5 - 3
prod = 4 * 2
quot = 9 / 3
rem = 10 % 3
cmp_eq = sum == 3
cmp_ne = sum != 4
cmp_lt = sum < 4
cmp_le = sum <= 3
cmp_gt = sum > 1
cmp_ge = sum >= 1
both = truthy and not falsy
either = falsy or truthy
inlist = 'a' in mixed
notin = 'z' not in mixed
tern = truthy ? 'yes' : 'no'
mixed += ['extra']
integer_dec += 1
integer_dec -= 1
integer_dec *= 2
integer_dec /= 2
integer_dec %= 5
first = numbers[0]
val = flags['level']
path_join = 'src' / 'main.c'

# ── Compiler and dependencies ──
cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : false)
sqlite = dependency('sqlite3', version : '>=3.40', required : true, fallback : ['sqlite', 'sqlite_dep'])
threads = dependency('threads')
zlib = dependency('zlib', required : get_option('compress'))

if cc.has_function('strlcpy', prefix : '#include <string.h>')
  add_project_arguments('-DHAVE_STRLCPY', language : 'c')
elif cc.has_header('bsd/string.h')
  add_project_arguments('-DHAVE_BSD_STRING', language : 'c')
else
  message('no strlcpy available')
endif

if host_machine.system() == 'windows'
  warning('Windows support is experimental')
elif host_machine.system() in ['linux', 'darwin']
  message('Unix-like host:', host_machine.cpu_family())
endif

if get_option('buildtype').startswith('debug')
  add_project_arguments('-DDEBUG', language : ['c', 'cpp'])
endif

# ── Configuration ──
conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set10('ENABLE_EXPORT', get_option('export'))
conf.set('MAX_ITEMS', 1000)
conf.set('USE_SQLITE', true)
configure_file(output : 'config.h', configuration : conf)

# ── Targets ──
inc = include_directories('include')
sources = files('src/stock.c', 'src/reorder.c')

foreach name : ['stock', 'reorder', 'audit']
  message('module: ' + name)
  if name == 'audit'
    continue
  endif
  if name == 'reorder'
    break
  endif
endforeach

foreach key, value : flags
  message('flag @0@ = @1@'.format(key, value))
endforeach

lib = static_library('inventory', sources + ['src/util.c'],
  include_directories : inc,
  dependencies : [sqlite, threads, m_dep],
  c_args : ['-fvisibility=hidden'],
  install : true)

shared = shared_library('inventory-shared', sources,
  version : '1.4.0',
  soversion : '1',
  include_directories : inc,
  dependencies : [sqlite])

inventory_dep = declare_dependency(
  link_with : lib,
  include_directories : inc,
  dependencies : [sqlite])

exe = executable('inventory', 'src/main.c',
  include_directories : inc,
  link_with : lib,
  install : true,
  install_dir : get_option('bindir'))

# ── Custom targets, generators, run_command ──
gen = custom_target('version-header',
  input : 'version.h.in',
  output : 'version.h',
  command : [find_program('sed'), 's/@VER@/' + meson.project_version() + '/', '@INPUT@'],
  capture : true,
  install : false)

res = run_command('git', 'rev-parse', '--short', 'HEAD', check : false)
if res.returncode() == 0
  rev = res.stdout().strip()
endif

py = import('python').find_installation('python3', required : false)
fs = import('fs')
if fs.exists('data/seed.csv')
  install_data('data/seed.csv', install_dir : get_option('datadir') / 'inventory')
endif

install_headers('include/inventory.h', subdir : 'inventory')
install_man('docs/inventory.1')

pkg = import('pkgconfig')
pkg.generate(lib, name : 'inventory', description : 'Stock library', version : meson.project_version())

# ── Tests ──
stock_test = executable('stock_test', 'tests/stock_test.c',
  link_with : lib, include_directories : inc)
test('stock', stock_test,
  args : ['--verbose'],
  env : ['INVENTORY_DB=:memory:'],
  timeout : 30,
  suite : ['unit', 'fast'],
  should_fail : false)
benchmark('stock-bench', stock_test, args : ['--bench'])

subdir('docs')
subproject('sqlite', required : false)
summary({'prefix': get_option('prefix'), 'compress': zlib.found()}, section : 'Configuration')
summary('version', meson.project_version(), bool_yn : true)

# ── More builtins, methods and functions ──
assert(integer_dec >= 0, 'dec must be positive')
if not cc.compiles('int main(void) { return 0; }', name : 'compiles check')
  error('compiler is broken')
endif
disabled = disabler()
nf = dependency('nonexistent', required : false)
if nf.found() and not is_disabler(disabled)
  message('found')
endif
set_variable('dynamic_var', 5)
dyn = get_variable('dynamic_var', 0)
if is_variable('dynamic_var')
  unset_variable('dynamic_var')
endif
env = environment()
env.set('INVENTORY_DB', ':memory:')
env.append('PATH', '/opt/bin', separator : ':')
env.prepend('LD_LIBRARY_PATH', meson.current_build_dir())
text = 'Hello, World'
message(text.to_upper(), text.to_lower(), text.strip(), text.contains('World'), text.startswith('H'), text.endswith('d'))
message(text.split(',')[0], ','.join(['a', 'b']), text.replace('World', 'Meson'), text.underscorify(), text.to_int().to_string())
message('1.2.3'.version_compare('>=1.0'), '@0@'.format(3), 'x'.substring(0, 1), text.format())
message(numbers.length(), numbers.contains(2), numbers.get(5, 'none'), flags.keys(), flags.has_key('debug'), flags.get('missing', false))
message(42.is_even(), 3.is_odd(), 4.to_string(), true.to_int(), false.to_string('no', 'yes'))
message(meson.version(), meson.source_root(), meson.build_root(), meson.current_source_dir(), meson.is_cross_build(), meson.is_subproject())
message(build_machine.system(), host_machine.cpu(), host_machine.endian(), target_machine.cpu_family())
message(join_paths('a', 'b'), range(0, 10, 2), cc.get_id(), cc.version(), cc.sizeof('int'), cc.get_define('__GNUC__'))
meson.add_install_script('scripts/post_install.sh', '--verbose')
meson.add_dist_script('scripts/dist.sh')
meson.override_dependency('inventory', inventory_dep)
meson.override_find_program('inventory-tool', exe)
meson.add_devenv(env)
add_global_arguments('-DGLOBAL=1', language : 'c')
add_global_link_arguments('-Wl,--as-needed', language : 'c')
add_project_link_arguments('-lm', language : 'c')
add_languages('cpp', required : false, native : false)
add_test_setup('valgrind', exe_wrapper : ['valgrind', '--error-exitcode=1'], timeout_multiplier : 4, is_default : false)
objs = lib.extract_objects('src/stock.c')
all_objs = lib.extract_all_objects(recursive : true)
both = both_libraries('both', sources, install : true)
mod = library('mod', 'src/mod.c', gnu_symbol_visibility : 'hidden', override_options : ['c_std=c99'])
loadable = shared_module('plugin', 'src/plugin.c', name_prefix : '', link_depends : 'plugin.map')
generic = build_target('generic', sources, target_type : 'executable')
jarfile = jar('Main', 'Main.java', main_class : 'Main')
gen_cmd = generator(find_program('protoc'), output : ['@BASENAME@.pb.cc', '@BASENAME@.pb.h'], arguments : ['--cpp_out=@BUILD_DIR@', '@INPUT@'])
generated = gen_cmd.process('a.proto', 'b.proto', preserve_path_from : meson.current_source_dir())
vcs = vcs_tag(command : ['git', 'describe', '--tags'], input : 'version.c.in', output : 'version.c', fallback : 'unknown')
alias_target('everything', exe, lib)
run_target('format', command : ['clang-format', '-i', sources], depends : [exe], env : env)
install_subdir('assets', install_dir : get_option('datadir') / 'inventory', exclude_files : ['*.tmp'], strip_directory : true)
install_symlink('inventory-link', pointing_to : 'inventory', install_dir : get_option('bindir'))
install_emptydir(get_option('localstatedir') / 'inventory')
i18n = import('i18n')
i18n.gettext('inventory', preset : 'glib')
rust = import('rust')
cmake = import('cmake')
windows = import('windows')
files_list = files('a.c', 'b.c')
included = include_directories('include', is_system : true)
config_h = configure_file(input : 'config.h.in', output : 'config.h', configuration : conf, format : 'cmake', install : false, copy : false)
dep_pkg = dependency('glib-2.0', method : 'pkg-config', modules : ['glib-2.0'], static : false, native : false, include_type : 'system')
ver = dep_pkg.version()
var = dep_pkg.get_variable(pkgconfig : 'prefix', default_value : '/usr')
mdep = dep_pkg.partial_dependency(compile_args : true, includes : true)
external = find_library('z', dirs : ['/usr/lib'], has_headers : ['zlib.h'], required : false)
prog = find_program('python3', 'python', required : false, version : '>=3.8', native : true)
if prog.found()
  message(prog.full_path(), prog.version())
endif
fs.copyfile('a.txt', 'b.txt')
message(fs.is_file('a'), fs.is_dir('b'), fs.name('x/y.c'), fs.parent('x/y.c'), fs.stem('y.c'), fs.replace_suffix('y.c', '.o'), fs.hash('a.txt', 'sha256'), fs.size('a.txt'), fs.as_posix('x\\y'), fs.is_absolute('/a'), fs.expanduser('~'), fs.relative_to('a/b', 'a'))
sub = subproject('sqlite2', default_options : ['x=1'], version : '>=3', required : false)
if sub.found()
  sub_dep = sub.get_variable('sqlite_dep')
endif
option_value = get_option('feature_x').enabled() or get_option('feature_y').disabled() or get_option('feature_z').auto()
feature_dep = dependency('zlib', required : get_option('feature_x').allowed())
if get_option('feature_x').disable_auto_if(host_machine.system() != 'linux').enabled()
  message('enabled')
endif
foreach item : range(3)
  message('item @0@'.format(item))
endforeach
message('done', meson.project_name(), meson.project_license(), meson.backend(), meson.global_build_root(), meson.project_build_root())

# ── Strings: every quoting form ──
q1 = 'single'
q2 = 'with \'escape\''
q3 = '''triple
quoted'''
q4 = f'''formatted @q1@
multi-line'''
q5 = 'unicode escapes: \u00e9 \U0001F4E6 \N{LATIN SMALL LETTER E WITH ACUTE} \x41 \101'
q6 = 'raw-ish: \d stays'
q7 = '@0@ and @1@'.format('a', 'b')

# ── Control flow: nested ternary, elif chains, loop forms ──
kind = integer_dec < 0 ? 'neg' : (integer_dec == 0 ? 'zero' : 'pos')
if kind == 'neg'
  message('negative')
elif kind == 'zero'
  message('zero')
elif kind == 'pos' and not falsy
  message('positive')
else
  message('unreachable')
endif
foreach i : [1, 2, 3]
  foreach j : range(2)
    if i == j
      continue
    endif
  endforeach
endforeach
foreach k, v : {'a': 1, 'b': 2}
  message(k, v)
endforeach

# ── More compiler checks ──
cc.links('int main(void) { return 0; }', name : 'link check')
cc.run('int main(void) { return 0; }', name : 'run check')
cc.check_header('stdint.h')
cc.has_member('struct stat', 'st_size', prefix : '#include <sys/stat.h>')
cc.has_type('uint64_t', prefix : '#include <stdint.h>')
cc.compute_int('sizeof(int)', low : 1, high : 16)
cc.alignment('double')
cc.has_argument('-Wall')
cc.get_supported_arguments(['-Wextra', '-Wpedantic'])
cc.first_supported_argument(['-O3', '-O2'])
cc.has_multi_arguments(['-Wall', '-Wextra'])
cc.get_argument_syntax()
cc.symbols_have_underscore_prefix()
cc.preprocess('src/stock.c', output : '@BASENAME@.i')
cc.get_supported_link_arguments(['-Wl,--as-needed'])
cc.has_function_attribute('unused')
cc.check_header('zlib.h', dependencies : zlib, required : false)
cc.find_library('dl', required : false, static : false)
cc.cmd_array()
cc.get_linker_id()

# ── Target keyword arguments ──
exe2 = executable('inventory2', 'src/main.c',
  win_subsystem : 'console',
  pie : true,
  export_dynamic : false,
  implib : false,
  build_rpath : '$ORIGIN',
  install_rpath : '$ORIGIN/../lib',
  extra_files : ['README.md'],
  objects : objs,
  name_suffix : 'bin',
  build_by_default : true,
  gui_app : false,
  c_pch : 'pch/pch.h',
  override_options : ['optimization=3', 'b_lto=true'])
ct = custom_target('gen',
  output : 'gen.h',
  command : [find_program('python3'), '@INPUT@', '@OUTPUT@', '@DEPFILE@'],
  input : 'gen.py',
  depfile : 'gen.d',
  depend_files : ['gen.cfg'],
  depends : [exe],
  console : true,
  build_always_stale : false,
  build_by_default : true,
  feed : false,
  install : true,
  install_dir : get_option('includedir'),
  install_mode : ['rw-r--r--', 'root', 'root'],
  install_tag : 'devel')
test('tap', exe, protocol : 'tap', priority : 10, workdir : meson.current_build_dir(), depends : [exe], is_parallel : false, verbose : true)
test('exitcode', exe, protocol : 'exitcode', should_fail : true)
test('gtest', exe, protocol : 'gtest')
test('rust', exe, protocol : 'rust')
declare_dependency(sources : gen, objects : objs, compile_args : ['-DX'], link_args : ['-lm'], variables : {'k': 'v'}, version : '1.0', include_directories : inc, link_whole : lib)
dependency('openssl', version : ['>=1.1', '<4'], required : false, default_options : ['x=1'], allow_fallback : true, not_found_message : 'OpenSSL missing', disabler : true)

# ── More modules and meson methods ──
keyval = import('keyval')
kv = keyval.load('config.ini')
sourceset = import('sourceset')
ss = sourceset.source_set()
ss.add(when : zlib, if_true : files('z.c'), if_false : files('noz.c'))
qt6 = import('qt6')
gnome = import('gnome')
simd = import('simd')
pkg2 = import('pkgconfig')
rust2 = import('rust')
meson.get_external_property('key', 'fallback', native : false)
meson.can_run_host_binaries()
meson.project_license_files()
meson.has_exe_wrapper()
meson.install_dependency_manifest('deps.txt')
meson.add_postconf_script('scripts/post.py')
meson.get_compiler('c', native : true)
meson.get_cross_property('x', 'y')
meson.is_unity()
meson.current_build_dir()
meson.global_source_root()
meson.project_source_root()
meson.build_options()
structured_sources(['a.rs'], {'sub': ['b.rs']})

# ── meson.options syntax (a separate file named meson.options; shown here for highlighting only) ──
if false
  option('feature_x', type : 'feature', value : 'auto', description : 'Enable X')
  option('mode', type : 'combo', choices : ['fast', 'safe'], value : 'safe', yield : true)
  option('jobs', type : 'integer', min : 1, max : 64, value : 4, deprecated : true)
  option('verbose', type : 'boolean', value : false)
  option('plugins', type : 'array', choices : ['a', 'b'], value : ['a'])
  option('prefix2', type : 'string', value : '/opt', description : 'Install prefix')
  option('old', type : 'string', deprecated : {'true': 'new_true', 'false': 'new_false'})
endif
