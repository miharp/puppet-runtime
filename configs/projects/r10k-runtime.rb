# r10k-runtime — a self-contained vendored-deps tarball for the openvox-r10k
# package: Ruby + r10k + a rugged Git provider linked against a bundled libgit2.
#
# Modeled on openbolt-runtime.rb, trimmed to r10k's exact dependency closure
# (derived from r10k's own Gemfile.lock: 19 gem components + the 8 gems that
# ship with Ruby). Its own prefix (/opt/puppetlabs/r10k) keeps it entirely
# separate from the agent runtime, so leaf agents are untouched — that is the
# whole point of building this as a dedicated runtime rather than extending the
# agent.
#
# Place at: configs/projects/r10k-runtime.rb in a puppet-runtime fork.
project 'r10k-runtime' do |proj|
  proj.setting(:runtime_project, 'r10k')
  proj.setting(:ruby_version, '3.2')  # Leave the .Z out for Ruby 3.2
  proj.setting(:openssl_version, '3.0')

  platform = proj.get_platform

  proj.version_from_git
  proj.generate_archives true    # produce the tarball the package consumes
  proj.generate_packages false   # this runtime is not itself a package

  proj.description 'Third-party components needed for openvox-r10k: Ruby, r10k, and a rugged Git provider'
  proj.license 'See components'
  proj.vendor 'Vox Pupuli <openvox@voxpupuli.org>'
  proj.homepage 'https://github.com/OpenVoxProject'
  proj.identifier 'org.voxpupuli'

  # A dedicated prefix — r10k gets its own Ruby, fully isolated from the agent.
  proj.setting(:prefix, '/opt/puppetlabs/r10k')

  ruby_base_version = proj.ruby_version.gsub(/(\d+)\.(\d+)(\.\d+)?/, '\1.\2.0')

  proj.setting(:ruby_dir, proj.prefix)
  proj.setting(:bindir, File.join(proj.prefix, 'bin'))
  proj.setting(:ruby_bindir, proj.bindir)
  proj.setting(:libdir, File.join(proj.prefix, 'lib'))
  proj.setting(:includedir, File.join(proj.prefix, 'include'))
  proj.setting(:datadir, File.join(proj.prefix, 'share'))
  proj.setting(:mandir, File.join(proj.datadir, 'man'))
  proj.setting(:ruby_dir_base, File.join(proj.libdir, 'ruby'))
  proj.setting(:ruby_dir_base_version, File.join(proj.ruby_dir_base, ruby_base_version))
  proj.setting(:rubygems_dir, File.join(proj.ruby_dir_base_version, 'rubygems'))
  proj.setting(:rubygems_ssl_dir, File.join(proj.rubygems_dir, 'ssl_certs'))

  proj.setting(:host_ruby, File.join(proj.ruby_bindir, 'ruby'))
  proj.setting(:host_gem, File.join(proj.ruby_bindir, 'gem'))
  proj.setting(:gem_home, File.join(proj.libdir, 'ruby', 'gems', ruby_base_version))
  proj.setting(:gem_install, "#{proj.host_gem} install --no-document --local --bindir=#{proj.ruby_bindir}")

  # These are set on Windows only; on Linux Ruby defines them as nil at parse
  # time, which is what the settings below expect. r10k is Linux-only for now.
  proj.setting(:platform_triple, nil)
  proj.setting(:host, nil)

  # Default CFLAGS/LDFLAGS, including the -rpath into libdir that lets rugged.so
  # find the bundled libgit2 at load time.
  instance_eval File.read('configs/projects/_shared-compiler-settings.rb')

  if platform.is_macos?
    proj.setting(:deployment_target, '13.0')
    targeting_flags = "-target #{platform.architecture}-apple-darwin22 -arch #{platform.architecture} -mmacos-version-min=13.0"
    proj.setting(:cflags, "#{targeting_flags} #{proj.cflags}")
    proj.setting(:cppflags, "#{targeting_flags} #{proj.cppflags}")
    proj.setting(:cc, 'clang')
    proj.setting(:cxx, 'clang++')
    proj.setting(:ldflags, "-L#{proj.libdir}")
  end

  proj.setting(:openssl_extra_configure_flags, %w[no-dtls no-dtls1 no-idea no-seed no-weak-ssl-ciphers])

  ########
  # Components — full blocks so update automation can insert lines.
  ########

  # Ruby build dependencies
  proj.component 'libffi'
  proj.component 'libyaml'
  proj.component "openssl-#{proj.openssl_version}"
  proj.component 'puppet-ca-bundle'   # faraday/puppet_forge need a CA bundle for HTTPS
  proj.component 'runtime-r10k'       # gcc runtime shim; every gem build-requires it
  proj.component "ruby-#{proj.ruby_version}"

  # The rugged Git provider and its C libraries (NEW components).
  # Order matters: libssh2 -> libgit2 -> rugged.
  proj.component 'libssh2'
  proj.component 'libgit2'
  proj.component 'rubygem-rugged'

  # r10k and its runtime gem closure (from r10k's Gemfile.lock; the remaining
  # 8 deps — fiddle, forwardable, json, logger, prime, racc, singleton, uri —
  # ship with Ruby and need no component).
  proj.component 'rubygem-base64'
  proj.component 'rubygem-colored2'
  proj.component 'rubygem-cri'
  proj.component 'rubygem-erubi'
  proj.component 'rubygem-faraday'
  proj.component 'rubygem-faraday-follow_redirects'
  proj.component 'rubygem-faraday-net_http'
  proj.component 'rubygem-fast_gettext'
  proj.component 'rubygem-gettext'
  proj.component 'rubygem-gettext-setup'
  proj.component 'rubygem-jwt'
  proj.component 'rubygem-locale'
  proj.component 'rubygem-log4r'
  proj.component 'rubygem-minitar'
  proj.component 'rubygem-multi_json'
  proj.component 'rubygem-net-http'
  proj.component 'rubygem-puppet_forge'
  proj.component 'rubygem-semantic_puppet'
  proj.component 'rubygem-text'
  proj.component 'rubygem-r10k'

  # Directories to pack into the runtime archive. WITHOUT these, vanagon only
  # captures explicitly-declared files (not the compiled trees), producing an
  # almost-empty tarball. Mirrors openbolt-runtime.
  proj.directory proj.prefix
  proj.directory proj.libdir
  proj.directory proj.includedir
  proj.directory proj.datadir
  proj.directory proj.mandir
  proj.directory proj.ruby_dir_base
  proj.directory proj.ruby_dir_base_version
  proj.directory proj.rubygems_dir
  proj.directory proj.rubygems_ssl_dir

  # Emit <name>-<version>.<platform>.settings.yaml (+ .sha1) so the consuming
  # openvox-r10k package can inherit_yaml_settings from it. Without this the
  # runtime builds but the package can't resolve prefix/bindir/etc. Both
  # openbolt-runtime and the agent runtimes do the same.
  proj.publish_yaml_settings
end
