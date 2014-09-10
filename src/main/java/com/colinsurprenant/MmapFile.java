package com.colinsurprenant;

import java.io.IOException;
import java.io.File;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

import org.jruby.RubyString;

public class MmapFile {
  private final long size;
  private final FileChannel channel;
  private MappedByteBuffer buffer;

  public MmapFile(String path, long size)
    throws IOException
  {
    this.size = size;
    File file = new File(path);
    this.channel = new RandomAccessFile(file, "rw").getChannel();
    this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, 0, size);
  }

  public void seek(long pos)
    throws IOException
  {
    this.buffer = this.channel.map(FileChannel.MapMode.READ_WRITE, pos, this.size);
  }

  public void write(RubyString data) {
    this.buffer.put(data.getByteList().bytes());
  }

  public void write(String data) {
    this.buffer.put(data.getBytes());
  }

  public void write(byte[] data) {
    this.buffer.put(data);
  }

  public void unsafe_write(RubyString data) {
    this.buffer.put(data.getByteList().unsafeBytes());
  }

  public void close()
    throws IOException
  {
    this.channel.close();
  }
}
