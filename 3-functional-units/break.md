Troubleshooting Exercise
========================
All breaks focused on the multiplier_iterative module. Made changes (with some
potentially unintended consequences ;) ) to the testbench, as well as added bugs
to all version of multiplier iterative.

Good luck xx

Fixes made
------------------------
**multiplier_iterative_v0**
- Fixed conditions where ``i!=31`` was meant to be ``i!=32`` as we need to continously perform the multiplication for all 32 bits not just the first 31.
- Fixed condition on when to update the result ``r`` and ``valid_out`` to ``i_next==32`` from ``i_next==31``

**multiplier_iterative_v1**
- Noticed that ``mc`` was the one being right shifted yet it has a size of ``[31:0]`` instead of ``[63:0]`` this would cause the overflow to get cut off. Hence the operations for mc and mp we exchanged. RealizedI could've just fixed the port widths but already changed it the other way so ya.

**multiplier_iterative_v2**
-In the ``always_ff`` loop, the ``valid_out`` values were being changed incorrectly. When the counter ``i_next`` is 8, ``valid_out`` should be ``TRUE`` otherwise it should be ``FALSE`` as the multiplication has no yet finished and the input is invalid. So that was ammended.

**multiplier_iterative_v3**
- Changed ``r[63:1] to r[63:0]`` as we need 64 bits for wrap-around not 63

**multiplier_iterative_tb**
- In order to see what was wrong with the testbench I decided to run the test_multiplier_iterative.sh script. In doing so I notice a couple of things, it starts both multiplicands at 0 but then assigns them random values. Inspecting the testench we see that between after a test cycle, instead of being incremented by a fixed amount the inputs to the multiplier ``a`` and ``b`` are assigned random values using the ``$urandom_range(0, 31'hfffffff)`` function. Not sure if I need to change this but it can be easily ammended.
-Second, we see that it fails due to timing out without a positive exit. This tells us that there is probably an issue with the clock. Simon for some reason used ``LOCALPARAM`` to declare values for ``TESTCYCLE`` and ``TIMEOUTCYCLES``??? This caused for the last multiplication to not have enough cycles hence the simulation timeting out. I reverted it back to the arguments of the ``repeat`` blocks to 10000 for the clock-generating block and 100 for the testing block. Not 100% sure about the logic behind this though (like why those specific values).
