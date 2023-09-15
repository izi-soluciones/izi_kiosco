class LoginRequest{
  String cadena;
  String contrasena;
  String correoElectronico;

  LoginRequest({
    required this.cadena,
    required this.contrasena,
    required this.correoElectronico
  });

  Map<String,dynamic> toJson()=>{
    "cadena":cadena,
    "contrasena":contrasena,
    "correoElectronico":correoElectronico,
  };

  factory LoginRequest.init()=>
      LoginRequest(
          cadena: "Chrome",
          contrasena: "",
          correoElectronico: ""
      );

}