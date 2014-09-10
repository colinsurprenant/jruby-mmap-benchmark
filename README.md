# JRuby mmap benchmarks

Series of benchmarks comparing different ways of calling Java NIO mmap from JRuby for sequential writes.

While performing tests in calling into Java NIO mmap from JRuby I realized there is a substential overhead in the automatic JRuby/Java string conversions when crossing the world between JRuby and Java.
Using strings in Ruby is pretty much the only way to carry "raw data" or "byte arrays". These benchmarks explore different strategies in carrying data through strings between JRuby and Java.

What triggered these experiments was that my initial test at using mmap was performing a lot slower than using JRuby standard File IO.

These benchmarks have been run on a MBP 13r 2.8GHz i7 with 16GB and 500GB SSD, OSX 10.9.4, JRuby 1.7.15, Java 1.7.0_11-b21

## Run

```sh
rake build
rake benchmark
```

## Results Summary

Each test iteration writes 2G of data in 1K chunks. This represent my typical use-case. The full results below also includes benchmarks for 4k and 16k chunks.

- `PureMmapFile` is a Ruby implementation that just wraps the Java NIO classes and methods for doing mmap.
- `MmapFile` is a Java implementation that has different strategies for handling the write method depending on the data type.
- `MmapFileExt` is implemented as a Java extension.
- `File` is just standard Ruby File IO.

- `autoboxing` means the default JRuby/Java String conversion.
- `unboxed` means the explicit `RubyString` bytes extraction in Java, `safe` is by copying the bytes and `unsafe` is by referencing the backing bytes.

Fastest to slowest results for the realistic/usable strategies, other strategies in the full results are only for experimenting & comparison.

```
                                                        user   system    total      real
1 java MmapFileExt, unboxed, unsafe, 1k ruby String 0.920000 0.580000 1.500000 (1.466000)
2 java MmapFile, unboxed, unsafe, 1k ruby String    1.020000 0.640000 1.660000 (1.639000)
3 java MmapFileExt, unboxed, safe, 1k ruby String   1.500000 0.810000 2.310000 (2.275000)
4 java MmapFile, unboxed, safe, 1k ruby String      1.700000 0.970000 2.670000 (2.664000)
5 ruby File, 1k String                              2.190000 1.520000 3.710000 (4.198000)
6 ruby PureMmapFile, 1k ruby String#to_java_bytes   4.620000 1.010000 5.630000 (4.943000)
7 java MmapFile, autoboxing, 1k ruby String         7.200000 1.190000 8.390000 (8.457000)
```

## Observations

- JRuby/Java automatic string conversion (7) overhead makes mmap perform a lot worst than standard File IO (5).
- avoiding JRuby/Java automatic string conversion by explicit unboxing (1 & 2) is about 6x faster than autoboxing (7).
- avoiding JRuby/Java automatic string conversion by explicit unboxing (1 & 2) makes mmap perform better for sequential writes than standard File IO (5).
- Java implementations using the String backing bytes without copying ("unsafe") are obviously faster (1 vs 3) and (2 vs 4).

So from a performance perspective, when calling Java from JRuby and using strings to carry data, you basically want to avoid going through the JRuby/Java automatic String conversions.

### Full Results

- 1k String

```
Rehearsal --------------------------------------------------------------------------------------
ruby File, 1k String                                 3.560000   2.450000   6.010000 (  5.522000)
----------------------------------------------------------------------------- total: 6.010000sec

                                                         user     system      total        real
ruby File, 1k String                                 2.190000   1.520000   3.710000 (  4.198000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, unsafe, 1k ruby String    1.440000   1.000000   2.440000 (  1.999000)
----------------------------------------------------------------------------- total: 2.440000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, unsafe, 1k ruby String    0.920000   0.580000   1.500000 (  1.466000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, safe, 1k ruby String      2.050000   1.040000   3.090000 (  2.683000)
----------------------------------------------------------------------------- total: 3.090000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, safe, 1k ruby String      1.500000   0.810000   2.310000 (  2.275000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, unsafe, 1k ruby String       1.400000   0.980000   2.380000 (  2.124000)
----------------------------------------------------------------------------- total: 2.380000sec

                                                         user     system      total        real
java MmapFile, unboxed, unsafe, 1k ruby String       1.020000   0.640000   1.660000 (  1.639000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, safe, 1k ruby String         1.970000   0.950000   2.920000 (  2.773000)
----------------------------------------------------------------------------- total: 2.920000sec

                                                         user     system      total        real
java MmapFile, unboxed, safe, 1k ruby String         1.700000   0.970000   2.670000 (  2.664000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, autoboxing, 1k ruby String            8.050000   1.320000   9.370000 (  8.977000)
----------------------------------------------------------------------------- total: 9.370000sec

                                                         user     system      total        real
java MmapFile, autoboxing, 1k ruby String            7.200000   1.190000   8.390000 (  8.457000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile, 1k ruby String#to_java_bytes      5.080000   0.970000   6.050000 (  5.046000)
----------------------------------------------------------------------------- total: 6.050000sec

                                                         user     system      total        real
ruby PureMmapFile, 1k ruby String#to_java_bytes      4.620000   1.010000   5.630000 (  4.943000)
```

- 4k String

```
Rehearsal --------------------------------------------------------------------------------------
ruby File, 4k String                                 2.550000   2.570000   5.120000 (  4.971000)
----------------------------------------------------------------------------- total: 5.120000sec

                                                         user     system      total        real
ruby File, 4k String                                 1.550000   1.550000   3.100000 (  3.440000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, unsafe, 4k ruby String    1.150000   1.020000   2.170000 (  1.739000)
----------------------------------------------------------------------------- total: 2.170000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, unsafe, 4k ruby String    0.690000   0.600000   1.290000 (  1.258000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, safe, 4k ruby String      1.710000   1.070000   2.780000 (  2.351000)
----------------------------------------------------------------------------- total: 2.780000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, safe, 4k ruby String      1.260000   0.800000   2.060000 (  2.013000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, unsafe, 4k ruby String       1.220000   1.060000   2.280000 (  1.857000)
----------------------------------------------------------------------------- total: 2.280000sec

                                                         user     system      total        real
java MmapFile, unboxed, unsafe, 4k ruby String       0.740000   0.510000   1.250000 (  1.223000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, safe, 4k ruby String         1.490000   1.070000   2.560000 (  2.421000)
----------------------------------------------------------------------------- total: 2.560000sec

                                                         user     system      total        real
java MmapFile, unboxed, safe, 4k ruby String         1.320000   0.840000   2.160000 (  2.122000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, autoboxing, 4k ruby String            7.900000   1.360000   9.260000 (  8.943000)
----------------------------------------------------------------------------- total: 9.260000sec

                                                         user     system      total        real
java MmapFile, autoboxing, 4k ruby String            7.160000   1.180000   8.340000 (  8.313000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile, 4k ruby String#to_java_bytes      2.600000   0.860000   3.460000 (  2.921000)
----------------------------------------------------------------------------- total: 3.460000sec

                                                         user     system      total        real
ruby PureMmapFile, 4k ruby String#to_java_bytes      2.110000   0.840000   2.950000 (  2.732000)
```

- 16k String

```
Rehearsal --------------------------------------------------------------------------------------
ruby File, 16k String                                3.190000   1.520000   4.710000 (  4.049000)
----------------------------------------------------------------------------- total: 4.710000sec

                                                         user     system      total        real
ruby File, 16k String                                1.030000   0.780000   1.810000 (  2.779000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, unsafe, 16k ruby String   0.820000   1.000000   1.820000 (  1.589000)
----------------------------------------------------------------------------- total: 1.820000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, unsafe, 16k ruby String   0.600000   0.700000   1.300000 (  1.266000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFileExt, unboxed, safe, 16k ruby String     1.360000   0.860000   2.220000 (  2.054000)
----------------------------------------------------------------------------- total: 2.220000sec

                                                         user     system      total        real
java MmapFileExt, unboxed, safe, 16k ruby String     1.300000   0.840000   2.140000 (  2.028000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, unsafe, 16k ruby String      0.960000   1.000000   1.960000 (  1.721000)
----------------------------------------------------------------------------- total: 1.960000sec

                                                         user     system      total        real
java MmapFile, unboxed, unsafe, 16k ruby String      0.610000   0.710000   1.320000 (  1.275000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, unboxed, safe, 16k ruby String        1.470000   1.080000   2.550000 (  2.359000)
----------------------------------------------------------------------------- total: 2.550000sec

                                                         user     system      total        real
java MmapFile, unboxed, safe, 16k ruby String        1.300000   0.830000   2.130000 (  2.111000)
Rehearsal --------------------------------------------------------------------------------------
java MmapFile, autoboxing, 16k ruby String           7.550000   1.350000   8.900000 (  8.585000)
----------------------------------------------------------------------------- total: 8.900000sec

                                                         user     system      total        real
java MmapFile, autoboxing, 16k ruby String           7.090000   1.190000   8.280000 (  8.204000)
Rehearsal --------------------------------------------------------------------------------------
ruby PureMmapFile, 16k ruby String#to_java_bytes     1.950000   1.030000   2.980000 (  2.541000)
----------------------------------------------------------------------------- total: 2.980000sec

                                                         user     system      total        real
ruby PureMmapFile, 16k ruby String#to_java_bytes     1.450000   0.670000   2.120000 (  2.021000)
```
