String toArabicDigits(Object value) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  return value.toString().replaceAllMapped(
    RegExp(r'\d'),
    (match) => arabicDigits[int.parse(match.group(0)!)],
  );
}