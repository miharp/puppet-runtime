# This component exists to link in the gcc runtime libraries, mirroring
# runtime-openbolt/runtime-agent. On Linux it is effectively a no-op (the
# Windows branches do the DLL bundling); it exists because every rubygem
# component build_requires "runtime-#{runtime_project}", i.e. runtime-r10k.
component 'runtime-r10k' do |pkg, _settings, _platform|
  pkg.environment 'PROJECT_SHORTNAME', 'r10k'
end
