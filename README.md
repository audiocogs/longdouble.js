Long-Double
================================================================================

Have you ever felt that 64-bit was not enough for you?

The answer is here, at least for basic arithmetic. longdouble.js implements
double-double arithmetic which represents numbers as a sum of two javascript
64-bit floats.

This representation allows us to be reasonably fast and still be high-precision.


Documentation
---------------------------------------------------------------------------------

TODO: Check the code out, it is not dangerous.


Credit
--------------------------------------------------------------------------------

Based on the ideas in the qd paper and library, available at, http://crd.lbl.gov/~dhbailey/mpdist/qd-2.3.12.tar.gz

Also, thanks to @antirez (Salvatore Sanfilippo) on Twitter for inspiring the
idea.


Bugs
---------------------------------------------------------------------------------

There are no bugs, only unintended features breaking every expectation of what
the library should do. If you find one of these unintended features, do not
hesitate to scream at me in an issue (or mail me at jens@ofmlabs.org).
