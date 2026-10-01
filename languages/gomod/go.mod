// Module file for the inventory service.
// Comments use C++ style; block comments are not supported.

module github.com/example/inventory

go 1.23.0

toolchain go1.23.4

godebug default=go1.21
godebug (
	panicnil = 1
	httplaxcontentlength = 1
)

// A single-line require.
require github.com/google/uuid v1.6.0

// A block of requires, including pre-release, pseudo-version and +incompatible forms.
require (
	github.com/jackc/pgx/v5 v5.7.1
	github.com/spf13/cobra v1.8.1
	golang.org/x/sync v0.8.0
	golang.org/x/text v0.14.1-0.20240101000000-abcdef123456
	github.com/legacy/lib v2.3.4+incompatible
	example.com/beta/pkg v0.0.0-20240102030405-0123456789ab
	gopkg.in/yaml.v3 v3.0.1
	rsc.io/quote v1.5.2-rc.1
)

// Indirect dependencies are marked with a trailing comment.
require (
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
)

// Replace directives: module to path, module to module, versioned.
replace github.com/example/shared => ../shared

replace github.com/example/other v1.2.3 => github.com/example/fork v1.2.4

replace (
	golang.org/x/net => golang.org/x/net v0.24.0
	example.com/local/pkg v0.1.0 => ./third_party/pkg
	"example.com/quoted/path" => "../quoted path"
)

// Exclude directives.
exclude golang.org/x/sync v0.7.0

exclude (
	github.com/bad/module v1.0.0
	github.com/bad/other v2.0.0+incompatible
)

// Retract directives: single, range, with rationale.
retract v1.0.1 // Published accidentally.

retract [v1.0.0, v1.0.5] // Contains a data-loss bug.

retract (
	v1.1.0 // Withdrawn.
	[v1.2.0, v1.2.9]
)

// Tool directives (Go 1.24).
tool golang.org/x/tools/cmd/stringer

tool (
	github.com/golangci/golangci-lint/cmd/golangci-lint
	honnef.co/go/tools/cmd/staticcheck
)

// Ignore directive (Go 1.25).
ignore ./node_modules

// Quoted and raw-string module paths are allowed.
require "example.com/quoted/module" v1.0.0

require (
	"example.com/quoted/in-block" v1.2.3
	`example.com/raw/string` v0.1.0
)

replace "example.com/quoted/module" => `../raw/path`

exclude "example.com/quoted/module" v0.9.0
