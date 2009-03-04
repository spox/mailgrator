spec = Gem::Specification.new do |s|
  s.name              = 'mailgrator'
  s.author            = %q(spox)
  s.email             = %q(spox@modspox.com)
  s.version           = '0.0.1'
  s.summary           = %q(Mail Migrator)
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.rdoc_options      = %w(--title MailGrator --main README --line-numbers)
  s.extra_rdoc_files  = %w(README)
  s.files             = Dir['**/*']
  s.executables = %w(mailgrator)
  s.require_paths = %w(lib)
  s.homepage          = %q(http://github.com/spox/mailgrator/tree)
  description         = []
  File.open("README") do |file|
    file.each do |line|
      line.chomp!
      break if line.empty?
      description << "#{line.gsub(/\[\d\]/, '')}"
    end
  end
  s.description = description[1..-1].join(" ")
end