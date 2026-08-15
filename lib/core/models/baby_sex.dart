/// Sexo del bebé para UI y percentiles.
///
/// [unspecified] → color azul neutro y curvas OMS mixtas (media niños/niñas).
enum BabySex {
  male,
  female,
  unspecified;

  bool? get isMaleFlag => switch (this) {
    BabySex.male => true,
    BabySex.female => false,
    BabySex.unspecified => null,
  };

  static BabySex fromIsMaleFlag(bool? isMale) => switch (isMale) {
    true => BabySex.male,
    false => BabySex.female,
    null => BabySex.unspecified,
  };
}
