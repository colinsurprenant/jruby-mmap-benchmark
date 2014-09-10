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

class MmapFile
  java_alias :aliased_unsafe_write, :unsafe_write, [RubyString]
end

module MmapTest

  class PureMmapFile

    def initialize(path, size)
      @size = size
      @file = Java::JavaIo::File.new(path)
      @channel = RandomAccessFile.new(@file, "rw").get_channel
      @buffer = @channel.map(FileChannel::MapMode::READ_WRITE, 0, size)
    end

    def rewind
      @buffer = @channel.map(FileChannel::MapMode::READ_WRITE, 0, @size)
    end

    def write(data)
      @buffer.put(data)
    end

    def close
      @channel.close
    end
  end

  BUFFER_SIZE = 1024
  STRING_1K = ("abcdefg\n" * (BUFFER_SIZE / 8)).force_encoding(Encoding::ASCII_8BIT)
  JAVA_STRING_1K = Java::JavaLang::String.new(STRING_1K)
  BYTES_1K = STRING_1K.to_java_bytes
  BUFFER_COUNT = 2 * 1000 * 1024
  REPORT_WIDTH = 50

  TESTS = [
    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFileExt.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFileExt, unsafe, ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.unsafe_write(STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFileExt.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFileExt, ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = PureMmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("ruby PureMmapFile ruby String#to_java_bytes") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(STRING_1K.to_java_bytes)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = PureMmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("ruby PureMmapFile java String#get_bytes") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(JAVA_STRING_1K.get_bytes)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = PureMmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("ruby PureMmapFile java bytes") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(BYTES_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile boxed ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile, unboxed, safe, ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.java_send(:write, [RubyString], STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile, unboxed, unsafe, ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.java_send(:unsafe_write, [RubyString], STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,


    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile, alias, unboxed, unsafe, ruby String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.aliased_unsafe_write(STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile java String") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(JAVA_STRING_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      File.delete("test_data.mmap") rescue nil
      mmaped_file = MmapFile.new("test_data.mmap", BUFFER_COUNT * BUFFER_SIZE)
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("java MmapFile java bytes") do
          mmaped_file.rewind

          BUFFER_COUNT.times.each do |i|
            mmaped_file.write(BYTES_1K)
          end
        end
      end
      mmaped_file.close
    end,

    lambda do
      file = File.new("test_data.file", "w+")
      Benchmark.bmbm(REPORT_WIDTH) do |b|
        b.report("ruby File") do
          file.seek(0)

          BUFFER_COUNT.times.each do |i|
            file.puts(STRING_1K)
          end
        end
      end
      file.close
    end,
  ]
end

MmapTest::TESTS[ARGV[0].to_i].call if __FILE__==$0