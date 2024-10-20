/// @func compose(_f, _g)
/// @desc Composes two functions together
function compose(_f, _g) {
  return method({_f, _g}, function(/*...*/) {
    return _f(method_call(_g, argument ?? []));
  });
}
