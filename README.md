# JRuby mmap benchmarks

Series of benchmarks comparing different ways of calling Java NIO mmap from JRuby for sequential writes versus stardard JRuby File IO writes.

The main "cost" of using Java NIO from JRuby is the Ruby/Java String boxing/unboxing and bytes array conversion.

- `PureMmapFile` is a Ruby implementation which just wraps the Java NIO classes and method for doing mmap.
- `MmapFile` is a Java implementation which has different strategies for handling the write method depending on the data type.

These benchmarks have been run on a MBP 13r 2.8GHz i7 with 16GB and 500GB SSD, OSX 10.9.4, JRuby 1.7.15, Java 1.7.0_11-b21

## Run

```sh
rake build
ruby mmap_test.rb
```

## Results Summary

Each test iteration writes 2G of data in 1K chunks.

```
                                                         user     system      total        real
java aliased mmap, unboxed, unsafe, ruby String      0.720000   0.810000   1.530000 (  1.594000)
pure mmap java bytes                                 0.970000   0.720000   1.690000 (  1.702000)
java mmap, unboxed, unsafe, ruby String              1.780000   1.000000   2.780000 (  2.913000)
java mmap, unboxed, safe, ruby String                2.350000   0.820000   3.170000 (  3.173000)
java mmap java bytes                                 0.790000   1.550000   2.340000 (  4.221000)
pure mmap ruby String#to_java_bytes                  4.290000   0.910000   5.200000 (  4.468000)
java mmap java String                                3.740000   1.080000   4.820000 (  4.875000)
pure mmap java String#get_bytes                      6.450000   1.030000   7.480000 (  6.872000)
java mmap boxed ruby String                          6.790000   1.110000   7.900000 (  7.923000)
File                                                 1.960000   4.140000   6.100000 (  9.394000)
```

Some of these tests are just for comparing different calling strategies but are not really useful. Below are the results for the usable strategies:

```
                                                         user     system      total        real
java aliased mmap, unboxed, unsafe, ruby String      0.720000   0.810000   1.530000 (  1.594000)
java mmap, unboxed, unsafe, ruby String              1.780000   1.000000   2.780000 (  2.913000)
java mmap, unboxed, safe, ruby String                2.350000   0.820000   3.170000 (  3.173000)
pure mmap ruby String#to_java_bytes                  4.290000   0.910000   5.200000 (  4.468000)
java mmap boxed ruby String                          6.790000   1.110000   7.900000 (  7.923000)
File                                                 1.960000   4.140000   6.100000 (  9.394000)
```

### Full Results

```
Rehearsal --------------------------------------------------------------------------------------
pure mmap ruby String#to_java_bytes                  4.790000   0.980000   5.770000 (  4.700000)
----------------------------------------------------------------------------- total: 5.770000sec

                                                         user     system      total        real
pure mmap ruby String#to_java_bytes                  4.290000   0.910000   5.200000 (  4.468000)
Rehearsal --------------------------------------------------------------------------------------
pure mmap java String#get_bytes                      6.680000   1.130000   7.810000 (  7.070000)
----------------------------------------------------------------------------- total: 7.810000sec

                                                         user     system      total        real
pure mmap java String#get_bytes                      6.450000   1.030000   7.480000 (  6.872000)
Rehearsal --------------------------------------------------------------------------------------
pure mmap java bytes                                 1.010000   0.960000   1.970000 (  1.953000)
----------------------------------------------------------------------------- total: 1.970000sec

                                                         user     system      total        real
pure mmap java bytes                                 0.970000   0.720000   1.690000 (  1.702000)
Rehearsal --------------------------------------------------------------------------------------
java mmap boxed ruby String                          7.370000   1.330000   8.700000 (  8.528000)
----------------------------------------------------------------------------- total: 8.700000sec

                                                         user     system      total        real
java mmap boxed ruby String                          6.790000   1.110000   7.900000 (  7.923000)
Rehearsal --------------------------------------------------------------------------------------
java mmap, unboxed, safe, ruby String                3.080000   4.280000   7.360000 (  8.522000)
----------------------------------------------------------------------------- total: 7.360000sec

                                                         user     system      total        real
java mmap, unboxed, safe, ruby String                2.350000   0.820000   3.170000 (  3.173000)
Rehearsal --------------------------------------------------------------------------------------
java mmap, unboxed, unsafe, ruby String              2.130000   4.400000   6.530000 (  9.889000)
----------------------------------------------------------------------------- total: 6.530000sec

                                                         user     system      total        real
java mmap, unboxed, unsafe, ruby String              1.780000   1.000000   2.780000 (  2.913000)
Rehearsal --------------------------------------------------------------------------------------
java aliased mmap, unboxed, unsafe, ruby String      0.910000   5.230000   6.140000 ( 10.172000)
----------------------------------------------------------------------------- total: 6.140000sec

                                                         user     system      total        real
java aliased mmap, unboxed, unsafe, ruby String      0.720000   0.810000   1.530000 (  1.594000)
Rehearsal --------------------------------------------------------------------------------------
java mmap java String                                4.550000   6.010000  10.560000 ( 15.453000)
---------------------------------------------------------------------------- total: 10.560000sec

                                                         user     system      total        real
java mmap java String                                3.740000   1.080000   4.820000 (  4.875000)
Rehearsal --------------------------------------------------------------------------------------
java mmap java bytes                                 1.070000   8.040000   9.110000 ( 15.867000)
----------------------------------------------------------------------------- total: 9.110000sec

                                                         user     system      total        real
java mmap java bytes                                 0.790000   1.550000   2.340000 (  4.221000)
Rehearsal --------------------------------------------------------------------------------------
File                                                 3.140000   6.370000   9.510000 ( 13.544000)
----------------------------------------------------------------------------- total: 9.510000sec

                                                         user     system      total        real
File                                                 1.960000   4.140000   6.100000 (  9.394000)
```