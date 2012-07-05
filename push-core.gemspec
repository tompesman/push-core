$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "push/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "push-core"
  s.version     = Push::VERSION
  s.authors     = ["Tom Pesman"]
  s.email       = ["tom@tnux.net"]
  s.homepage    = "https://github.com/tompesman/push-core"
  s.summary     = "Core of the push daemon."
  s.description = "Push daemon for push notification services like APNS (iOS/Apple) and GCM/C2DM (Android)."

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.files         = `git ls-files lib`.split("\n") + ["README.md", "MIT-LICENSE"]
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 3.2.1"
  s.add_development_dependency "sqlite3"
end
