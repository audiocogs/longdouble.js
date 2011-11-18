(function() {
  var CSLongDouble, SPLITTER, quick_two_diff, quick_two_sum, split, two_diff, two_prod, two_sum;

  two_sum = function(a, b) {
    var e, s;
    s = a + b;
    e = s - a;
    return [s, (a - (s - e)) + (b - e)];
  };

  quick_two_sum = function(a, b) {
    var s;
    s = a + b;
    return [s, b - (s - a)];
  };

  SPLITTER = 134217729.0;

  split = function(a) {
    var hi, lo, temp;
    temp = SPLITTER * a;
    hi = temp - (temp - a);
    lo = a - hi;
    return [hi, lo];
  };

  if (!Math.fma) {
    two_prod = function(a, b) {
      var a_hi, a_lo, b_hi, b_lo, error, p, _ref, _ref2;
      p = a * b;
      _ref = split(a), a_hi = _ref[0], a_lo = _ref[1];
      _ref2 = split(b), b_hi = _ref2[0], b_lo = _ref2[1];
      error = ((a_hi * b_hi - p) + a_hi * b_lo + a_lo * b_hi) + a_lo * b_lo;
      return [p, error];
    };
  } else {
    two_prod = function(a, b) {
      var p;
      p = a * b;
      return [p, Math.fma(a, b, -p)];
    };
  }

  two_diff = function(a, b) {
    var e, s;
    s = a - b;
    e = s - a;
    return [s, (a - (s - e)) - (b + e)];
  };

  quick_two_diff = function(a, b) {
    var s;
    s = a - b;
    return [s, (a - s) - b];
  };

  CSLongDouble = (function() {

    function CSLongDouble(hi, lo) {
      this.hi = hi;
      this.lo = lo;
    }

    CSLongDouble.prototype.negate = function() {
      return new CSLongDouble(-this.hi, -this.lo);
    };

    CSLongDouble.prototype.add = function(other) {
      var s_hi, s_lo, t_hi, t_lo, _ref, _ref2, _ref3, _ref4;
      _ref = two_sum(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      _ref2 = two_sum(this.lo, other.lo), t_hi = _ref2[0], t_lo = _ref2[1];
      s_lo += t_hi;
      _ref3 = quick_two_sum(s_hi, s_lo), s_hi = _ref3[0], s_lo = _ref3[1];
      s_lo += t_lo;
      _ref4 = quick_two_sum(s_hi, s_lo), s_hi = _ref4[0], s_lo = _ref4[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.addFast = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_sum(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      s_lo = (s_lo + this.lo) + other.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), s_hi = _ref2[0], s_lo = _ref2[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.addDouble = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_sum(this.hi, other), s_hi = _ref[0], s_lo = _ref[1];
      s_lo += this.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), s_hi = _ref2[0], s_lo = _ref2[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.sub = function(other) {
      var s_hi, s_lo, t_hi, t_lo, _ref, _ref2, _ref3, _ref4;
      _ref = two_diff(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      _ref2 = two_diff(this.lo, other.lo), t_hi = _ref2[0], t_lo = _ref2[1];
      s_lo += t_hi;
      _ref3 = quick_two_sum(s_hi, s_lo), s_hi = _ref3[0], s_lo = _ref3[1];
      s_lo += t_lo;
      _ref4 = quick_two_sum(s_hi, s_lo), s_hi = _ref4[0], s_lo = _ref4[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.subFast = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_diff(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      s_lo = (s_lo + this.lo) - other.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), s_hi = _ref2[0], s_lo = _ref2[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.subDouble = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_diff(this.hi, other), s_hi = _ref[0], s_lo = _ref[1];
      s_lo += this.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), s_hi = _ref2[0], s_lo = _ref2[1];
      return new CSLongDouble(s_hi, s_lo);
    };

    CSLongDouble.prototype.mul = function(other) {
      var p_hi, p_lo, _ref, _ref2;
      _ref = two_prod(this.hi, other.hi), p_hi = _ref[0], p_lo = _ref[1];
      p_lo += this.hi * other.lo + other.hi * this.lo;
      _ref2 = quick_two_sum(p_hi, p_lo), p_hi = _ref2[0], p_lo = _ref2[1];
      return new CSLongDouble(p_hi, p_lo);
    };

    CSLongDouble.prototype.mulDouble = function(other) {
      var p_hi, p_lo, _ref, _ref2;
      _ref = two_prod(this.hi, other), p_hi = _ref[0], p_lo = _ref[1];
      p_lo += this.lo * other;
      _ref2 = quick_two_sum(p_hi, p_lo), p_hi = _ref2[0], p_lo = _ref2[1];
      return new CSLongDouble(p_hi, p_lo);
    };

    CSLongDouble.prototype.div = function(other) {
      var q_hi, q_lo, q_vlo, r, _ref;
      q_hi = this.hi / other.hi;
      r = this.sub(other.mulDouble(q_hi));
      q_lo = r.hi / other.hi;
      r.decrement(other.mulDouble(q_lo));
      q_vlo = r.hi / other.hi;
      _ref = quick_two_sum(q_hi, q_lo), q_hi = _ref[0], q_lo = _ref[1];
      r = new CSLongDouble(q_hi, q_lo);
      return r.addDouble(q_vlo);
    };

    CSLongDouble.prototype.divFast = function(other) {
      var q_hi, q_lo, r, s_hi, s_lo, _ref, _ref2;
      q_hi = this.hi / other.hi;
      r = other.mulDouble(q_hi);
      _ref = two_diff(this.hi, r.hi), s_hi = _ref[0], s_lo = _ref[1];
      s_lo = (s_lo - r.lo) + this.lo;
      q_lo = (s_hi + s_lo) / other.hi;
      _ref2 = quick_two_sum(q_hi, q_lo), r.hi = _ref2[0], r.lo = _ref2[1];
      return r;
    };

    CSLongDouble.prototype.divDouble = function(other) {
      var p_hi, p_lo, q_hi, q_lo, s_hi, s_lo, _ref, _ref2, _ref3;
      q_hi = this.hi / other;
      _ref = two_prod(q_hi, other), p_hi = _ref[0], p_lo = _ref[1];
      _ref2 = two_diff(this.hi, p_hi), s_hi = _ref2[0], s_lo = _ref2[1];
      s_lo = (s_lo + this.lo) - p_lo;
      q_lo = (s_hi + s_lo) / other;
      _ref3 = quick_two_sum(q_hi, q_lo), q_hi = _ref3[0], q_lo = _ref3[1];
      return new CSLongDouble(q_hi, q_lo);
    };

    CSLongDouble.prototype.increment = function(other) {
      var s_hi, s_lo, t_hi, t_lo, _ref, _ref2, _ref3, _ref4;
      _ref = two_sum(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      _ref2 = two_sum(this.lo, other.lo), t_hi = _ref2[0], t_lo = _ref2[1];
      s_hi += t_hi;
      _ref3 = quick_two_sum(s_hi, s_lo), s_hi = _ref3[0], s_lo = _ref3[1];
      s_hi += t_lo;
      _ref4 = quick_two_sum(s_hi, s_lo), this.hi = _ref4[0], this.lo = _ref4[1];
      return this;
    };

    CSLongDouble.prototype.incrementFast = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_sum(this.sum, other.sum), s_hi = _ref[0], s_lo = _ref[1];
      s_lo = (s_lo + this.lo) - other.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), this.hi = _ref2[0], this.lo = _ref2[1];
      return this;
    };

    CSLongDouble.prototype.incrementDouble = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_sum(this.hi, other), s_hi = _ref[0], s_lo = _ref[1];
      s_lo += this.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), this.hi = _ref2[0], this.lo = _ref2[1];
      return this;
    };

    CSLongDouble.prototype.decrement = function(other) {
      var s_hi, s_lo, t_hi, t_lo, _ref, _ref2, _ref3, _ref4;
      _ref = two_diff(this.hi, other.hi), s_hi = _ref[0], s_lo = _ref[1];
      _ref2 = two_diff(this.lo, other.lo), t_hi = _ref2[0], t_lo = _ref2[1];
      s_lo += t_hi;
      _ref3 = quick_two_sum(s_hi, s_lo), s_hi = _ref3[0], s_lo = _ref3[1];
      s_lo += t_lo;
      _ref4 = quick_two_sum(s_hi, s_lo), this.hi = _ref4[0], this.lo = _ref4[1];
      return this;
    };

    CSLongDouble.prototype.decrementFast = function(other) {
      var lo, s_hi, s_lo, _ref, _ref2;
      _ref = two_diff(this.hi, other.lo), s_hi = _ref[0], s_lo = _ref[1];
      lo = (s_lo + this.lo) - other.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), this.sum = _ref2[0], this.error = _ref2[1];
      return this;
    };

    CSLongDouble.prototype.decrementDouble = function(other) {
      var s_hi, s_lo, _ref, _ref2;
      _ref = two_diff(this.hi, other), s_hi = _ref[0], s_lo = _ref[1];
      s_lo += this.lo;
      _ref2 = quick_two_sum(s_hi, s_lo), this.hi = _ref2[0], this.lo = _ref2[1];
      return this;
    };

    CSLongDouble.prototype.equal = function(other) {
      return this.hi === other.hi && this.lo === other.lo;
    };

    CSLongDouble.prototype.equalDouble = function(other) {
      return this.hi === other && this.lo === 0.0;
    };

    CSLongDouble.prototype.notEqual = function(other) {
      return this.hi !== other.hi || this.lo !== other.lo;
    };

    CSLongDouble.prototype.notEqualDouble = function(other) {
      return this.hi !== other || this.lo !== 0.0;
    };

    CSLongDouble.prototype.greaterThan = function(other) {
      return this.hi > other.hi || (this.hi === other.hi && this.lo > other.lo);
    };

    CSLongDouble.prototype.greaterThanDouble = function(other) {
      return this.hi > other || (this.hi === other && this.lo > 0.0);
    };

    CSLongDouble.prototype.greaterEqualThan = function(other) {
      return this.hi >= other.hi || (this.hi === other.hi && this.lo >= other.lo);
    };

    CSLongDouble.prototype.greaterEqualThanDouble = function(other) {
      return this.hi >= other || (this.hi === other && this.lo >= 0.0);
    };

    CSLongDouble.prototype.lessThan = function(other) {
      return this.hi < other.hi || (this.hi === other.hi && this.lo < other.lo);
    };

    CSLongDouble.prototype.lessThanDouble = function(other) {
      return this.hi < other || (this.hi === other && this.lo < 0.0);
    };

    CSLongDouble.prototype.lessEqualThan = function(other) {
      return this.hi <= other.hi || (this.hi === other.hi && this.lo <= other.lo);
    };

    CSLongDouble.prototype.lessEqualThanDouble = function(other) {
      return this.hi <= other || (this.hi === other && this.lo <= 0.0);
    };

    CSLongDouble.prototype.abs = function() {
      if (this.lessThanDouble(0.0)) {
        return this.negate();
      } else {
        return new CSLongDouble(this.hi, this.lo);
      }
    };

    CSLongDouble.prototype.zero = function() {
      return this.hi === 0.0 && this.lo === 0.0;
    };

    CSLongDouble.prototype.notZero = function() {
      return this.hi !== 0.0 || this.lo !== 0.0;
    };

    CSLongDouble.prototype.one = function() {
      return this.hi === 1.0 && this.lo === 0.0;
    };

    return CSLongDouble;

  })();

  window.CSLongDouble = CSLongDouble;

}).call(this);
