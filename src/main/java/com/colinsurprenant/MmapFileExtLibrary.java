package com.colinsurprenant;

import java.io.IOException;
import java.io.File;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubyFixnum;
import org.jruby.RubyInteger;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

public class MmapFileExtLibrary implements Library {
    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyClass mmapFileExtClass = runtime.defineClass("MmapFileExt", runtime.getObject(),  new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new MmapFileExt(runtime, rubyClass);
            }
        });
        mmapFileExtClass.defineAnnotatedMethods(MmapFileExt.class);
    }

    @JRubyClass(name = "MmapFileExt", parent = "Object")
    public static class MmapFileExt extends RubyObject {

        private long size;
        private FileChannel channel;
        private MappedByteBuffer buffer;

        public MmapFileExt(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        @JRubyMethod(name = "initialize", required = 2)
        public IRubyObject initialize(ThreadContext context, RubyString path, IRubyObject size)
            throws IOException
        {
            this.size = size.convertToInteger().getLongValue();
            File file = new File(path.decodeString());
            this.channel = new RandomAccessFile(file, "rw").getChannel();
            this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.size);
            return context.nil;
        }

        @JRubyMethod(name = "rewind")
        public void rewind()
            throws IOException
        {
            this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, this.size);
        }

        @JRubyMethod(name = "write", required = 1)
        public void write(RubyString data) {
            this.buffer.put(data.getByteList().bytes());
        }

        @JRubyMethod(name = "unsafe_write", required = 1)
        public void unsafe_write(RubyString data) {
            this.buffer.put(data.getByteList().unsafeBytes());
        }

        @JRubyMethod(name = "close")
        public void close()
            throws IOException
        {
            this.channel.close();
        }

    }
}