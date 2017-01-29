#
# longdouble.js, https://github.com/ofmlabs/longdouble.js
# 
# By Jens Nockert of OFMLabs
#
# Lemma 1. Let a and b be two p-bit floating point numbers such that |a| ≥ |b|.
#          Then |err(a + b)| ≤ |b| ≤ |a|.
# Lemma 2. Let a and b be two p-bit floating point numbers.
#          Then err(a + b) = (a + b) − fl(a + b) is representable as a p-bit
#          floating point number.

# Algorithm 4. The following algorithm computes
#                s = fl(a + b)
#                e = err(a + b).
#              This algorithm uses three more floating point operations instead
#              of a branch.
#
# Note.        I should look into if it is faster to use (3) with a branch.

two_sum = (a, b) ->
	s = a + b
	e = s - a
	
	return [s, (a - (s - e)) + (b - e)]

# Algorithm 3. The following algorithm computes
#                s = fl(a + b)
#                e = err(a + b),
#              assuming |a| ≥ |b|.

quick_two_sum = (a, b) ->
	s = a + b
	
	return [s, b - (s - a)]

# Algorithm 5. The following algorithm splits a 53-bit IEEE double precision
#              floating point number into ahi and alo, each with 26 bits of
#              significand, such that a = ahi + alo. ahi will contain the first
#              26 bits, while alo will contain the lower 26 bits.
#
# Note.        There is additional stuff in the code, that is not available in
#              the paper, I need to look into when it is needed.
#
#              Ideas: Handles denormals?

SPLITTER     =  134217729.0               # = 2^27 + 1

split = (a) ->
	temp = SPLITTER * a
	
	hi = temp - (temp - a)
	lo = a - hi
	
	return [hi, lo]

# Algorithm 6. The following algorithm computes
#                p = fl(a × b)
#                e = err(a × b).

if (!Math.fma) # Only my special build of Firefox supports FMA yet.
	two_prod = (a, b) ->
		p = a * b
		
		[a_hi, a_lo] = split(a)
		[b_hi, b_lo] = split(b)
		
		error = ((a_hi * b_hi - p) + a_hi * b_lo + a_lo * b_hi) + a_lo * b_lo
		
		return [p, error]
	
else
# Algorithm 7. The following algorithm computes
#                p = fl(a × b)
#                e = err(a × b)
#              on a browser with FMA support.
#
# Note:        FMA is never implemented in JS, but I will probably add it to
#              Spidermonkey soon, this would probably make this method much
#              faster, even without hardware support.

	two_prod = (a, b) ->
		p = a * b
		
		return [p, Math.fma(a, b, -p)]
	

# Note:        The same as (4), but with b replaced by -b.

two_diff = (a, b) ->
	s = a - b
	e = s - a
	
	return [s, (a - (s - e)) - (b + e)]

# Note:        The same as (3), but with b replaced by -b.

quick_two_diff = (a, b) ->
	s = a - b
	
	return [s, (a - s) - b]

# TODO:        Implement a sane constructor

class CSLongDouble
	constructor: (@hi, @lo) ->
#
# Imp 1:       Since a long-double is a sum of two doubles, just changing the
#              sign of both the high and the low part, we change the sign of
#              the sum itself.
#
	negate: () ->
		return new CSLongDouble(-@hi, -@lo)
#
# Imp 2:       To add a and b, we use the general structure to apply the
#              operation to first the high parts (s_hi, s_lo) and the low parts
#              (t_hi, t_lo) in separation, then we merge the results, first
#              t_hi, then t_lo.
#
	add: (other) ->
		[s_hi, s_lo] = two_sum(@hi, other.hi)
		[t_hi, t_lo] = two_sum(@lo, other.lo)
		
		s_lo += t_hi
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		s_lo += t_lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo);
	
#
# Imp 3:       The fast versions have lower precision, since it only merges in
#              the high part (t_hi) of the lower parts.
#
	addFast: (other) ->
		[s_hi, s_lo] = two_sum(@hi, other.hi)
		
		s_lo = (s_lo + @lo) + other.lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo)
	
# Imp 4:       Essentially equivalent to the addFast method, but with some
#              optimizations due to the other.lo being 0.
#
	addDouble: (other) ->
		[s_hi, s_lo] = two_sum(@hi, other)
		
		s_lo += @lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo)
	
# Imp 5:       Equivalent to (2), but with the other replaced by -other.
#              That is, the first two two_sum operations in the network are
#              replaced by two_diff, the merging is done in the same way.
#
	sub: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other.hi)
		[t_hi, t_lo] = two_diff(@lo, other.lo)
		
		s_lo += t_hi
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		s_lo += t_lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo)
	
# Imp 5:       Equivalent to (3), but with the other replaced by -other.
#              That is, the first two_sum operation in the network is
#              replaced by two_diff, and the optimized second add is replaced
#              by a difference.
#
	subFast: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other.hi)
		
		s_lo = (s_lo + @lo) - other.lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo)
	
# Imp 6:       Equivalent to (4), but with the other replaced by -other.
#              That is, the first two_sum operation is replaced by two_diff,
#              and just like in (5), but since the low part of other is 0, we
#              do not need the second difference.
#
	subDouble: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other)
		
		s_lo += @lo
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		return new CSLongDouble(s_hi, s_lo)
	
# Imp 7:       Multiplication uses a similar network to the fast
#              implementations, due to the nature of floating point.
#              We know that the a_lo * b_lo will never end up in the final
#              product, which allows us to do some optimizations.
#
	mul: (other) ->
		[p_hi, p_lo] = two_prod(@hi, other.hi)
		
		p_lo += (@hi * other.lo + other.hi * @lo)
		
		[p_hi, p_lo] = quick_two_sum(p_hi, p_lo)
		
		return new CSLongDouble(p_hi, p_lo)
	
# Imp 8:       The same as (7), but since b_lo is 0, we can optimize a bit.
#
	mulDouble: (other) ->
		[p_hi, p_lo] = two_prod(@hi, other)
		
		p_lo += (@lo * other)
		
		[p_hi, p_lo] = quick_two_sum(p_hi, p_lo)
		
		return new CSLongDouble(p_hi, p_lo)
	
# Imp 9:       Implementing division is 
#
	div: (other) ->
		q_hi = @hi / other.hi
		
		r = this.sub(other.mulDouble(q_hi))
		
		q_lo = r.hi / other.hi
		
		r.decrement(other.mulDouble(q_lo))
		
		q_vlo = r.hi / other.hi
		
		[q_hi, q_lo] = quick_two_sum(q_hi, q_lo)
		
		r = new CSLongDouble(q_hi, q_lo)
		
		return r.addDouble(q_vlo)
	
# Imp 10:      TODO
	divFast: (other) ->
		q_hi = @hi / other.hi
		
		r = other.mulDouble(q_hi)
		
		[s_hi, s_lo] = two_diff(@hi, r.hi)
		
		s_lo = (s_lo - r.lo) + @lo
		
		q_lo = (s_hi + s_lo) / other.hi
		
		[r.hi, r.lo] = quick_two_sum(q_hi, q_lo)
		
		return r
	
# Imp 11:      The same as (10), but with b_lo being 0.
#
	divDouble: (other) ->
		q_hi = @hi / other
		
		[p_hi, p_lo] = two_prod(q_hi, other)
		
		[s_hi, s_lo] = two_diff(@hi, p_hi)
		
		s_lo = (s_lo + @lo) - p_lo
		
		q_lo = (s_hi + s_lo) / other
		
		[q_hi, q_lo] = quick_two_sum(q_hi, q_lo)
		
		return new CSLongDouble(q_hi, q_lo)
	
# Imp 12:      See (2).
#
	increment: (other) ->
		[s_hi, s_lo] = two_sum(@hi, other.hi)
		[t_hi, t_lo] = two_sum(@lo, other.lo)
		
		s_hi += t_hi
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		s_hi += t_lo;
		
		[@hi, @lo] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 13:      See (3).
#
	incrementFast: (other) ->
		[s_hi, s_lo] = two_sum(@sum, other.sum)
		
		s_lo = (s_lo + @lo) - other.lo
		
		[@hi, @lo] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 14:      See (4).
#
	incrementDouble: (other) ->
		[s_hi, s_lo] = two_sum(@hi, other)
		
		s_lo += @lo
		
		[@hi, @lo] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 15:      See (5).
#
	decrement: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other.hi)
		[t_hi, t_lo] = two_diff(@lo, other.lo)
		
		s_lo += t_hi
		
		[s_hi, s_lo] = quick_two_sum(s_hi, s_lo)
		
		s_lo += t_lo
		
		[@hi, @lo] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 16:      See (6).
#
	decrementFast: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other.lo)
		
		lo = (s_lo + @lo) - other.lo
		
		[@sum, @error] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 17:      See (7).
#
	decrementDouble: (other) ->
		[s_hi, s_lo] = two_diff(@hi, other)
		
		s_lo += @lo
		
		[@hi, @lo] = quick_two_sum(s_hi, s_lo)
		
		return this
	
# Imp 18:      Trivial
#
	equal: (other) ->
		return @hi == other.hi && @lo == other.lo
	
# Imp 19:      Trivial
#
	equalDouble: (other) ->
		return @hi == other && @lo == 0.0
	
# Imp 20:      Trivial
#
	notEqual: (other) ->
		return @hi != other.hi || @lo != other.lo
	
# Imp 21:      Trivial
#
	notEqualDouble: (other) ->
		return @hi != other || @lo != 0.0
	
# Imp 22:      Trivial
#
	greaterThan: (other) ->
		return @hi > other.hi || (@hi == other.hi && @lo > other.lo)
	
# Imp 23:      Trivial
#
	greaterThanDouble: (other) ->
		return @hi > other || (@hi == other && @lo > 0.0)
	
# Imp 24:      Trivial
#
	greaterEqualThan: (other) ->
		return @hi > other.hi || (@hi == other.hi && @lo >= other.lo)
	
# Imp 25:      Trivial
#
	greaterEqualThanDouble: (other) ->
		return @hi > other || (@hi == other && @lo >= 0.0)
	
# Imp 26:      Trivial
#
	lessThan: (other) ->
		return @hi < other.hi || (@hi == other.hi && @lo < other.lo)
	
# Imp 27:      Trivial
#
	lessThanDouble: (other) ->
		return @hi < other || (@hi == other && @lo < 0.0)
	
# Imp 28:      Trivial
#
	lessEqualThan: (other) ->
		return @hi < other.hi || (@hi == other.hi && @lo <= other.lo)
	
# Imp 29:      Trivial
#
	lessEqualThanDouble: (other) ->
		return @hi < other || (@hi == other && @lo <= 0.0)
	
# Imp 30:      Trivial
#
	abs: () ->
		if this.lessThanDouble(0.0)
			return this.negate()
		else
			return new CSLongDouble(@hi, @lo)
		
	
# Imp 31:      TODO but trivial
#
	pow: (n) ->
		if n == 0
			if this.zero()
				return new CSLongDouble(0.0 / 0.0, 0.0 / 0.0)
			
			return new CSLongDouble(1.0, 0.0)
		
		r = new CSLongDouble(@hi, @lo)
		s = new CSLongDouble(1.0, 0.0)
		
		p = Math.abs(n)
		
		if p > 1.0
			while p > 0.0
				if p % 2 == 1
					s = s.mul(r)
				
				p = Math.floor(p / 2.0)
				
				if p > 0.0
					r = r.mul(r)
				
			
		else
			s = r
		
		if n < 0.0
			return new CSLongDouble(1.0, 0.0).div(s)
		else
			return s
		
	
# Helper 1:    Trivial
#
	zero: () ->
		return @hi == 0.0 && @lo == 0.0
	
# Helper 2:    Trivial
#
	notZero: () ->
		return @hi != 0.0 || @lo != 0.0
	
# Helper 3:    Trivial
#
	one: () ->
		return @hi == 1.0 && @lo == 0.0
	

window.CSLongDouble = CSLongDouble
