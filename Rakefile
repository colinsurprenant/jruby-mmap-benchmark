begin
  require 'ant'
rescue
  puts("error: unable to load Ant, make sure Ant is installed, in your PATH and $ANT_HOME is defined properly")
  puts("\nerror details:\n#{$!}")
  exit(1)
end

require 'jruby/jrubyc'
require 'open3'

task :setup do
  ant.mkdir 'dir' => "target/classes"
  ant.path 'id' => 'classpath' do
    fileset 'dir' => "target/classes"
  end
end

desc "compile JRuby and Java proxy classes"
task :build => [:setup] do |t, args|
  ant.javac(
    'srcdir' => "src/",
    'destdir' => "target/classes/",
    'classpathref' => 'classpath',
    'debug' => "yes",
    'includeantruntime' => "no",
    'verbose' => false,
    'listfiles' => true
  ) {}
end

desc "run benchmark"
task :benchmark do
  require "mmap_test"

  # run each test in a fresh VM
  MmapTest::TESTS.size.times.each do |i|
    out = IO.popen("ruby mmap_test.rb #{i} 2>&1")
    puts(out.readlines)
    out.close
  end
end
