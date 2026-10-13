/// Validate a GS1 GTIN without guessing, padding, or changing its digits.
/// Supported representations are GTIN-8, GTIN-12, GTIN-13 and GTIN-14.
bool isValidGtin(String code) {
  if (!const {8, 12, 13, 14}.contains(code.length) ||
      !RegExp(r'^\d+$').hasMatch(code)) {
    return false;
  }
  var sum = 0;
  var weight = 3;
  for (var i = code.length - 2; i >= 0; i--) {
    sum += int.parse(code[i]) * weight;
    weight = weight == 3 ? 1 : 3;
  }
  return (10 - sum % 10) % 10 == int.parse(code[code.length - 1]);
}
