#####
# rugged — Ruby binding for libgit2, built against the vendored libgit2/libssh2
# rather than the copy the gem vendors. This is the piece that gives r10k its
# fast Git provider without a compiler on the target.
#
# Component release information:
#   https://rubygems.org/gems/rugged
#####
component 'rubygem-rugged' do |pkg, settings, platform|
  ### Maintained by update_gems automation ###
  pkg.version '1.9.4'
  pkg.sha256sum '5876152be06568b413eb7eaccf3932a5b011a139fcf9330a680abdf16859dcd3'
  ### End automated maintenance section ###

  # The native lib must exist before the gem's extension can link it.
  pkg.build_requires 'libgit2'
  pkg.build_requires 'libssh2'

  # rugged's extconf finds the system libgit2 via pkg-config; point it at ours.
  # Without this it silently falls back to building its vendored libgit2 — which
  # is the no-SSH failure this whole effort exists to prevent.
  pkg.environment 'PKG_CONFIG_PATH', File.join(settings[:libdir], 'pkgconfig')

  # Extra args passed through to rugged's extconf (after the `--`). _base-rubygem
  # appends the value of settings[:"<component>_gem_install_options"] to the
  # gem install command.
  #   --use-system-libraries : link the vendored libgit2 instead of building one
  #   --with-git2-include/lib: point at our lib/ (rugged defaults to lib64 and
  #                            would otherwise miss it) — verified in a container
  #   -rpath                  : bake the lib location into rugged.so so it loads
  #                             with no LD_LIBRARY_PATH (PE's exact linkage)
  settings[:'rubygem-rugged_gem_install_options'] =
    "-- --use-system-libraries " \
    "--with-git2-include=#{settings[:includedir]} " \
    "--with-git2-lib=#{settings[:libdir]} " \
    "--with-ldflags='-Wl,-rpath,#{settings[:libdir]}'"

  instance_eval File.read('configs/components/_base-rubygem.rb')

  # Build-time gate: a rugged without :ssh is worse than no rugged, so fail the
  # build here rather than shipping a silently broken provider. (Skip on
  # cross-compiled targets where the just-built ruby can't run on the builder.)
  #
  # %q{} keeps #{...} literal so it is evaluated by the inner `ruby -e` at build
  # time, not interpolated when vanagon loads this component.
  unless platform.is_cross_compiled?
    ruby_bin = File.join(settings[:ruby_bindir], 'ruby')
    # Concatenate with + (adjacent %q{} literals parse as modulo). %q keeps the
    # inner #{...} literal so the build-time ruby -e evaluates them, not vanagon.
    verify = %q{require "rugged"; f = Rugged.features; } +
             %q{abort("FATAL: rugged built without :ssh (got #{f.inspect})") unless f.include?(:ssh); } +
             %q{abort("FATAL: rugged built without :https (got #{f.inspect})") unless f.include?(:https); } +
             %q{STDERR.puts("rugged #{Rugged::VERSION} features: #{f.inspect}")}
    pkg.install do
      ["#{ruby_bin} -e '#{verify}'"]
    end
  end
end
