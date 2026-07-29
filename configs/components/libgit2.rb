#####
# libgit2 — the C library rugged binds. Built with SSH via libssh2 so the
# rugged provider works against SSH remotes.
# Component release information: https://github.com/libgit2/libgit2/releases
#
# Version tracks the rugged gem: rugged 1.9.x expects libgit2 1.9.x. PE ships
# libgit2 1.9.2 in pe-r10k, which is what this mirrors.
#####
component 'libgit2' do |pkg, settings, platform|
  pkg.load_from_json('configs/components/libgit2.json')
  pkg.mirror "#{settings[:buildsources_url]}/libgit2-#{pkg.get_version}.tar.gz"

  # The GitHub archive tarball (v#{ver}.tar.gz) extracts to libgit2-#{ver}/, but
  # vanagon derives the source dir from the URL basename (v#{ver}). Correct it.
  pkg.dirname "libgit2-#{pkg.get_version}"

  pkg.build_requires 'cmake'   # OS package; el/debian all ship cmake >= 3.20
  pkg.build_requires 'libssh2'
  pkg.build_requires "openssl-#{settings[:openssl_version]}"

  pkg.environment 'PATH', "$(PATH):#{settings[:bindir]}"

  # USE_SSH=ON is the whole point — without it rugged links a libgit2 that
  # cannot speak SSH, which is silently useless for private control repos.
  # CMAKE_PREFIX_PATH points cmake at our just-built libssh2.
  pkg.configure do
    ["cmake -S . -B build " \
     "-DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} " \
     "-DCMAKE_INSTALL_LIBDIR=lib " \
     "-DCMAKE_PREFIX_PATH=#{settings[:prefix]} " \
     "-DUSE_SSH=ON " \
     "-DUSE_HTTPS=OpenSSL " \
     # NTLM needs MD4, which the vendored OpenSSL is built without (legacy algo).
     # r10k never uses NTLM git auth, so disable the bundled ntlmclient.
     "-DUSE_NTLMCLIENT=OFF " \
     "-DOPENSSL_ROOT_DIR=#{settings[:prefix]} " \
     "-DBUILD_SHARED_LIBS=ON " \
     "-DBUILD_TESTS=OFF " \
     "-DBUILD_CLI=OFF " \
     "-DCMAKE_C_FLAGS='#{settings[:cflags]}' " \
     "-DCMAKE_EXE_LINKER_FLAGS='#{settings[:ldflags]}' " \
     "-DCMAKE_SHARED_LINKER_FLAGS='#{settings[:ldflags]}'"]
  end

  pkg.build do
    ["cmake --build build -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  pkg.install do
    ["cmake --install build"]
  end
end
