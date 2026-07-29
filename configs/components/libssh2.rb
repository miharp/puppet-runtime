#####
# libssh2 — SSH transport for libgit2, so rugged can reach SSH git remotes.
# Component release information: https://github.com/libssh2/libssh2/releases
#
# NOTE: this is the FIRST CMake-based component in puppet-runtime (curl, openssl
# etc. are autotools). The build host must therefore have `cmake` available —
# add it as a build package in the platform files, or as a build_requires, when
# wiring this into a runtime project.
#####
component 'libssh2' do |pkg, settings, platform|
  pkg.load_from_json('configs/components/libssh2.json')
  pkg.mirror "#{settings[:buildsources_url]}/libssh2-#{pkg.get_version}.tar.gz"

  # Reuse the runtime's OpenSSL rather than vendoring a second crypto stack —
  # the same one curl links.
  pkg.build_requires "openssl-#{settings[:openssl_version]}"

  pkg.environment 'PATH', "$(PATH):#{settings[:bindir]}"

  # -DCMAKE_INSTALL_LIBDIR=lib keeps libs out of a lib64 split, so rugged's one
  # RPATH entry (settings[:libdir]) finds everything.
  pkg.configure do
    ["cmake -S . -B build " \
     "-DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} " \
     "-DCMAKE_INSTALL_LIBDIR=lib " \
     "-DCMAKE_PREFIX_PATH=#{settings[:prefix]} " \
     "-DCRYPTO_BACKEND=OpenSSL " \
     "-DOPENSSL_ROOT_DIR=#{settings[:prefix]} " \
     "-DBUILD_SHARED_LIBS=ON " \
     "-DBUILD_EXAMPLES=OFF " \
     "-DBUILD_TESTING=OFF " \
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
