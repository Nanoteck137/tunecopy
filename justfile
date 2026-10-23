default:
    just -l

gen-api *args:
    ./scripts/gen-api.sh {{args}}

test-build:
    nix build --no-link .#
