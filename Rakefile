require 'rubygems/package_task'

GEMSPEC = Gem::Specification.load('ruby-lint.gemspec')

Dir['./task/*.rake'].each do |task|
  import(task)
end

Gem::PackageTask.new(GEMSPEC) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end

task :default => :test
