// Membandingkan current dengan threshold memakai operator string ("<",
// "<=", "=", ">=", ">"), sama seperti yang dipakai firmware untuk rule
// trigger/restriction.
bool evaluateOperator(double current, String operatorSymbol, double threshold) {
  switch (operatorSymbol) {
    case '<':
      return current < threshold;
    case '<=':
      return current <= threshold;
    case '>':
      return current > threshold;
    case '>=':
      return current >= threshold;
    case '=':
    case '==':
      return current == threshold;
    default:
      return false;
  }
}
