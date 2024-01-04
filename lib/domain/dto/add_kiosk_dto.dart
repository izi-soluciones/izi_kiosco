class AddKioskDto {
  String name;
  int branchOffice;
  int cashRegister;
  int business;

  AddKioskDto(
      {required this.branchOffice,
      required this.cashRegister,
        required this.business,
      required this.name});
  Map<String,dynamic> toJson() => {
        "nombre": name,
        "sucursal": branchOffice,
        "caja": cashRegister,
    "contribuyente": business,
        "tipo": "Kiosko",
        "activo": true
      };
}
