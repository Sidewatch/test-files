<?php
// One problem per run, for error_log.php: PHP itself reports it to the error_log that run was given.
//
//   php trigger.php <case>

function load_order($id) { throw new RuntimeException("order $id not found"); }
function controller($id) { return load_order($id); }

switch ($argv[1]) {
    case 'warning':     echo $undefinedVariable; break;
    case 'warning2':    $a = []; echo $a['missing_key']; break;
    case 'warning3':    fopen('/nonexistent/app/cache.json', 'r'); break;
    case 'uwarning':    trigger_error('payment gateway slow: 2300ms', E_USER_WARNING); break;
    case 'notice':      trigger_error('cache miss for key user:1042', E_USER_NOTICE); break;
    case 'deprecated':  trigger_error('Config option "legacy_mode" is deprecated', E_USER_DEPRECATED); break;
    case 'deprecated2': strlen(null); break;
    case 'fatal':       controller(7731); break;                        // uncaught exception, with a stack trace
    case 'fatal2':      $x = null; $x->method(); break;                 // Error: call on null
    case 'typeerror':   (function (int $n) { return $n; })('forty-two'); break;
    case 'memory':      ini_set('memory_limit', '4M'); str_repeat('x', 8 * 1024 * 1024); break;
}
