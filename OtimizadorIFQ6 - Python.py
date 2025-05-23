---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
/usr/local/lib/python3.11/dist-packages/pandas/core/ops/array_ops.py in _na_arithmetic_op(left, right, op, is_cmp)
    217     try:
--> 218         result = func(left, right)
    219     except TypeError:

11 frames
TypeError: unsupported operand type(s) for /: 'float' and 'str'

During handling of the above exception, another exception occurred:

TypeError                                 Traceback (most recent call last)
/usr/local/lib/python3.11/dist-packages/pandas/core/ops/array_ops.py in _masked_arith_op(x, y, op)
    161         # See GH#5284, GH#5035, GH#19448 for historical reference
    162         if mask.any():
--> 163             result[mask] = op(xrav[mask], yrav[mask])
    164 
    165     else:

TypeError: unsupported operand type(s) for /: 'float' and 'str
