Array.prototype.remove = function(from, to) {
  var rest = this.slice((to || from) + 1 || this.length)
  this.length = from < 0 ? this.length + from : from
  return this.push.apply(this, rest)
}

Array.prototype.unique = function() {
  var a = [], i, l = this.length
  for (i = 0; i < l; i++) {
    if ($.inArray(this[i], a) < 0) { a.push(this[i]) }
  }
  return a
}

Array.prototype.each = function(op) {
  var l = this.length
  
  for (var i = 0; i < l; i++) {
    op(this[i])
  }
}

Array.prototype.dup = function() {
  return this.slice(0)
}

Array.prototype.sel = function(op) {
  var a = []
  var l = this.length
  
  for (var i = 0; i < l; i++) {
    if (op(this[i])) a.push(this[i])
  }
  
  return a
}

Array.prototype.map = function(op) {
  var a = []
  var l = this.length
  
  for (var i = 0; i < l; i++) {
    a.push(op(this[i]))
  }
  
  return a
}

Array.prototype.arr_eql = function(array2) {
  if ((!this[0]) || (!array2[0])) {
    return false
  }
  if (this.length != array2.length) {
    return false
  }
  
  for (var i = 0; i < this.length; i++) {
    if (this[i] != array2[i]) return false
  }
  
  return true
}

Array.prototype.index_of_coords = function(coords) {
  var l = this.length
  
  for (var i = 0; i < l; i++) {
    if (coords.arr_eql(this[i])) return i
  }
  
  return -1
}

function obj_keys(o) {
  var accumulator = []
  for (var propertyName in o) {
    if (propertyName != 'keys') accumulator.push(propertyName)
  }
  return accumulator
}

JS.Ext = true;
