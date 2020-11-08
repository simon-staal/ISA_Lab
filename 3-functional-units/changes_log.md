The errors introduced to the code are located in the iterative implementations of the multiplier. The files were changes were staged are the following:
1. ``multiplier_iterative_v1.v``
Found error with i_next, conditional was incorrect and did not reflect desired value of 32.
Had to rewrite the conditional statement, wouldnt compile for some reason.
made last always comb block to an ff block
flipped the shift signs for mp and mc. Jesus this took way too long to realise.
changed i to i next in last conditional. Also took a long time.
2. ``multiplier_iterative_v2.v``
mp_nibble length 5 bits instead of 4. Changed to 3 to avoid calculation errors.
compilation error line 34, removed irrelevant "end"
compilation error line 8, removed extra ","
made valid out = 1 and valid in = 0 in the last ff block
added ">" prefix to "=" signs in ff block
made mc <= mc_next
made mp <= mp_next
3. ``multiplier_iterative_v3.v``
removed assign in the always block
included the assign operator "<"
4. ``multiplier_iterative_tb.v``
Decided to debug this first in order to effectively test the other components.
changed ~clk to !clk so bitwise inverse is not taken. I doubt this wouldve hampered performance though.
added the mappings to the module instance "m"./

Happy debugging! - ty :)

Salman
