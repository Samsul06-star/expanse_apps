class User {
  final int id;
  final String name; // mapped from "full_name"
  final String email;
  final String? avatar;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.birthDate,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return User(
      id: json["id"] ?? 0,
      name: (json["full_name"] ?? json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      avatar: json["avatar"] != null ? json["avatar"].toString() : null,
      birthDate: parseDate(json["birth_date"]),
      createdAt: parseDate(json["created_at"] ?? json["CreatedAt"]),
      updatedAt: parseDate(json["updated_at"] ?? json["UpdatedAt"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "full_name": name,
      "email": email,
      "avatar": avatar,
      "birth_date": birthDate?.toIso8601String(),
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}
