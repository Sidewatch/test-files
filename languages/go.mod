module github.com/example/inventory

go 1.23

require (
	github.com/jackc/pgx/v5 v5.7.1
	github.com/spf13/cobra v1.8.1
	golang.org/x/sync v0.8.0
)

require (
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
)

replace github.com/example/shared => ../shared

exclude golang.org/x/sync v0.7.0
