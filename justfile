set shell := ["bash", "-cu"]

postgres_connection_string = "postgres://user:password@localhost:5432/pg"
redis_connection_string = "redis://localhost:6379"

build:
	cargo build

watch:
	RUST_BACKTRACE=full cargo watch -s 'cargo test -- --nocapture'

next-watch:
	cargo watch -s 'cargo nextest run'

check-code:
	SQLX_OFFLINE=true cargo fmt --check --all
	SQLX_OFFLINE=true cargo clippy --all-features
	SQLX_OFFLINE=true cargo audit

test-in-ci:
	SQLX_OFFLINE=true DATABASE_URL="{{postgres_connection_string}}" cargo sqlx migrate run
	SQLX_OFFLINE=true cargo nextest run --verbose --locked

cli-run:
	SQLX_OFFLINE=true cargo run --bin stablesats run

build-x86_64-unknown-linux-musl-release:
	SQLX_OFFLINE=true cargo build --release --locked --target x86_64-unknown-linux-musl

build-x86_64-apple-darwin-release:
	bin/osxcross-compile.sh

start-deps:
	nix-shell -p postgresql_13 redis --run "pg_ctl start && redis-server &"

stop-deps:
	nix-shell -p postgresql_13 redis --run "pg_ctl stop && redis-cli shutdown"

reset-deps: stop-deps start-deps setup-db

setup-db:
	cargo sqlx migrate run
