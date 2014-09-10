# encoding: utf-8

require "java"
require "benchmark"
require "thread"

java_import "java.io.RandomAccessFile"
java_import "java.nio.MappedByteBuffer"
java_import "java.nio.channels.FileChannel"
java_import "org.jruby.RubyString"

$CLASSPATH << "target/classes"
java_import "com.colinsurprenant.MmapFile"

require "mmap_file_ext"

# create an alias for the MmapFile#unsafe_write method signature taking a RubyString object, this is a bit faster than using java_send
# this is required to avoid the JRuby/Java String auto conversion and access the RubyString object from within the Java class
class MmapFile
  java_alias :aliased_unsafe_write, :unsafe_write, [RubyString]
  java_alias :aliased_write, :write, [RubyString]
end

module MmapTest

  class PureMmapFile

    def initialize(path, size)
      @size = size
      @file = Java::JavaIo::File.new(path)
      @channel = RandomAccessFile.new(@file, "rw").get_channel
      @buffer = @channel.map(FileChannel::MapMode::READ_WRITE, 0, size)
    end

    def seek(pos)
      @buffer = @channel.map(FileChannel::MapMode::READ_WRITE, pos, @size)
    end

    def write(data)
      @buffer.put(data)
    end

    def close
      @channel.close
    end
  end

  BUFFERS = {
     1 => ("abcdefg\n" * ( 1 * 1024 / 8)).force_encoding(Encoding::ASCII_8BIT),
     4 => ("abcdefg\n" * ( 4 * 1024 / 8)).force_encoding(Encoding::ASCII_8BIT),
    16 => ("abcdefg\n" * (16 * 1024 / 8)).force_encoding(Encoding::ASCII_8BIT),
  }

  # I previously had tests with Java String and Java byte[] but these are not realistically usable from a JRuby
  # context so I removed them.
  #
  # JAVA_STRING_1K = Java::JavaLang::String.new(STRING_1K)
  # BYTES_1K = STRING_1K.to_java_bytes

  REPORT_WIDTH = 50
  WRITE_SIZE = 2 * 1000 * 1024 * 1024

  def self.bench(desc, writer_class, buffer, &write_block)
    raise("invalid buffer size") if WRITE_SIZE % buffer.size != 0
    buffer_count = WRITE_SIZE / buffer.size
    path =  writer_class == File ? "test_data.file" : "test_data.mmap"
    File.delete(path) rescue nil
    out = writer_class.new(path, writer_class == File ? "w+" : WRITE_SIZE)

    Benchmark.bmbm(REPORT_WIDTH) do |b|
      b.report(desc) do
        out.seek(0)
        buffer_count.times.each{|i| write_block.call(out, buffer)}
      end
    end
    out.close
  end

  TESTS = [1, 4, 16].map do |size|
    [
      {:desc => "ruby File, #{size}k String", :class => File, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.puts(buffer)}},
      {:desc => "java MmapFileExt, unboxed, unsafe, #{size}k ruby String", :class => MmapFileExt, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.unsafe_write(buffer)}},
      {:desc => "java MmapFileExt, unboxed, safe, #{size}k ruby String", :class => MmapFileExt, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.write(buffer)}},
      {:desc => "java MmapFile, unboxed, unsafe, #{size}k ruby String", :class => MmapFile, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.aliased_unsafe_write(buffer)}},
      {:desc => "java MmapFile, unboxed, safe, #{size}k ruby String", :class => MmapFile, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.aliased_write(buffer)}},
      {:desc => "java MmapFile, autoboxing, #{size}k ruby String", :class => MmapFile, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.write(buffer)}},
      {:desc => "ruby PureMmapFile, #{size}k ruby String#to_java_bytes", :class => PureMmapFile, :buffer => BUFFERS.fetch(size), :write => lambda{|out, buffer| out.write(buffer.to_java_bytes)}},
    ]
  end.flatten
end

if __FILE__ == $0
  test = MmapTest::TESTS[ARGV[0].to_i]
  MmapTest.bench(test[:desc], test[:class], test[:buffer], &test[:write])
end