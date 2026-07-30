# This branch is superseded

**Do not build on `add-r10k-runtime`.** It added a standalone `r10k-runtime`
project (its own Ruby + OpenSSL + gem closure) so a separate `openvox-r10k`
package could bake in a self-contained runtime tarball.

That approach was **over-built.** `openvox-agent` already ships Ruby 3.2 and
OpenSSL 3 (libs, headers, pkgconfig) at `/opt/puppetlabs/puppet`, so r10k does
not need a second copy. The work moved to a **thin overlay on `openvox-agent`**
(the pe-r10k model): build `libssh2 → libgit2 → rugged` against the agent's own
Ruby+OpenSSL, install r10k's gem closure into the agent gempath, and ship only
the native `.so`s — a ~10 MB package that `Requires: openvox-agent`, vs the
~20 MB standalone runtime.

The overlay needs **no puppet-runtime changes** — the agent runtime is only a
build input. So this branch is no longer needed.

**Current work:** https://github.com/miharp/openvox-r10k (PR #1,
`reshape-agent-overlay`).

Kept for provenance: the vanagon `libssh2` / `libgit2` / `rubygem-rugged`
components here are correct and were carried over to openvox-r10k unchanged.
