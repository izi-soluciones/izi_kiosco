class Category{
  int id;
  String name;
  String? image;
  Category(this.name,this.image,this.id);
  factory Category.fromJson(Map json){
    return Category(json["nombre"]??"" , json["custom"] is Map && json["custom"]["imagen"] is String?json["custom"]["imagen"]:null,json["id"]);
  }
}