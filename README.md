# JRuby mmap benchmarks

Series of benchmarks comparing different ways of calling Java NIO mmap from JRuby for sequential writes.

While performing tests in calling into Java NIO mmap from JRuby I realized there is a substential overhead in the automatic JRuby/Java string conversions when crossing the world between JRuby and Java.
Using strings in Ruby is pretty much the only way to carry "raw data" or "byte arrays". These benchmarks explore different strategies in carrying data through strings between JRuby and Java.

What triggered these experiments was that my initial test at using mmap was performing a lot slower than using JRuby standard File IO.

These benchmarks have been run on a MBP 13r 2.8GHz i7 with 16GB and 500GB SSD, OSX 10.9.4, JRuby 1.7.15, Java 1.7.0_11-b21

## Run

```sh
rake build
rake benchmarks
```

## Results Summary

Each test iteration writes 2G of data in 1K chunks. This represent my typical use-case but I will also add benchmarks for 4/8/16K chunks.

- `PureMmapFile` is a Ruby implementation that just wraps the Java NIO classes and methods for doing mmap.
- `MmapFile` is a Java implementation that has different strategies for handling the write method depending on the data type.
- `MmapFileExt` is a Java extension implementation
- `File` is just standard Ruby File IO.

Fastest to slowest results for the realistic/usable strategies, other strategies in the full results are only for experimenting & comparison.

```
                                                       user   system    total      real
1 java MmapFileExt, unsafe, ruby String              0.690000 0.700000 1.390000 (1.308000)
2 java MmapFile, alias, unboxed, unsafe, ruby String 0.880000 0.660000 1.540000 (1.480000)
3 java MmapFileExt, ruby String                      1.360000 0.820000 2.180000 (2.120000)
4 java MmapFile, unboxed, unsafe, ruby String        1.740000 0.810000 2.550000 (2.472000)
5 java MmapFile, unboxed, safe, ruby String          2.380000 0.810000 3.190000 (3.123000)
6 ruby File                                          2.040000 1.580000 3.620000 (3.910000)
7 ruby PureMmapFile ruby String#to_java_bytes        4.340000 1.000000 5.340000 (4.604000)
8 java MmapFile boxed ruby String                    7.150000 1.120000 8.270000 (8.234000)
```

## Observations

- JRuby/Java automatic string conversion (8) overhead makes mmap perform a lot worst than File IO (6).
- avoiding JRuby/Java automatic string conversion (1 & 2) is about 6x faster than (8).
- avoiding JRuby/Java automatic string conversion (1 & 2) makes mmap perform better for sequential writes (for my use-case) than standard File IO (6).
- Java implementations using the String backing bytes without copying ("unsafe") are faster (4 vs 5) and as an extension it is the fastest (1 vs 3)

So from a performance perspective, when calling Java from JRuby and using strings to carry data, you basically want to avoid going through the JRuby/Java automatic String conversions.

### Full Results

```
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unsafe, ruby String                0.840000   0.960000   1.800000 (  1.610000)
----------------------------------------------------------------------------- total: 1.800000sec

                                                         user     system      total        real
java MmapFileExt, unsafe, ruby String                0.690000   0.700000   1.390000 (  1.308000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, ruby String                        1.600000   1.020000   2.620000 (  2.329000)
----------------------------------------------------------------------------- total: 2.620000sec

                                                         user     system      total        real
java MmapFileExt, ruby String                        1.360000   0.820000   2.180000 (  2.120000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile ruby String#to_java_bytes          4.810000   0.950000   5.760000 (  4.730000)
----------------------------------------------------------------------------- total: 5.760000sec

                                                         user     system      total        real
ruby PureMmapFile ruby String#to_java_bytes          4.340000   1.000000   5.340000 (  4.604000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile java String#get_bytes              7.050000   1.090000   8.140000 (  7.185000)
----------------------------------------------------------------------------- total: 8.140000sec

                                                         user     system      total        real
ruby PureMmapFile java String#get_bytes              6.750000   1.100000   7.850000 (  7.141000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile java bytes                         1.360000   0.890000   2.250000 (  1.999000)
----------------------------------------------------------------------------- total: 2.250000sec

                                                         user     system      total        real
ruby PureMmapFile java bytes                         1.120000   0.860000   1.980000 (  2.592000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile boxed ruby String                      7.880000   1.280000   9.160000 (  8.660000)
----------------------------------------------------------------------------- total: 9.160000sec

                                                         user     system      total        real
java MmapFile boxed ruby String                      7.150000   1.120000   8.270000 (  8.234000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, safe, ruby String            3.170000   0.960000   4.130000 (  3.641000)
----------------------------------------------------------------------------- total: 4.130000sec

                                                         user     system      total        real
java MmapFile, unboxed, safe, ruby String            2.380000   0.810000   3.190000 (  3.123000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, unsafe, ruby String          2.580000   0.990000   3.570000 (  3.068000)
----------------------------------------------------------------------------- total: 3.570000sec

                                                         user     system      total        real
java MmapFile, unboxed, unsafe, ruby String          1.740000   0.810000   2.550000 (  2.472000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, alias, unboxed, unsafe, ruby String   1.170000   1.090000   2.260000 (  1.982000)
----------------------------------------------------------------------------- total: 2.260000sec

                                                         user     system      total        real
java MmapFile, alias, unboxed, unsafe, ruby String   0.880000   0.660000   1.540000 (  1.480000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile java String                            4.550000   1.070000   5.620000 (  5.302000)
----------------------------------------------------------------------------- total: 5.620000sec

                                                         user     system      total        real
java MmapFile java String                            4.240000   1.150000   5.390000 (  5.344000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile java bytes                             1.120000   1.030000   2.150000 (  1.892000)
----------------------------------------------------------------------------- total: 2.150000sec

                                                         user     system      total        real
java MmapFile java bytes                             0.870000   0.830000   1.700000 (  1.630000)
Rehearsal --------------------------------------------------------------------------------------
ruby File                                            2.940000   3.280000   6.220000 (  6.272000)
----------------------------------------------------------------------------- total: 6.220000sec

                                                         user     system      total        real
ruby File                                            2.040000   1.580000   3.620000 (  3.910000)
```