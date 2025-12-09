import 'package:equatable/equatable.dart';
import 'package:expense_uangku/models/user.dart';

class Expanse extends Equatable {
  final int id;
  final int userId;
  final String category;
  final String type; // "Expense" / "Income"
  final int amount;
  final String description;
  final DateTime date;
  final User? user; // nested user

  const Expanse({
    required this.id,
    required this.userId,
    required this.category,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.user,
  });

  factory Expanse.fromJson(Map<String, dynamic> json) {
    return Expanse(
      id: json["id"],
      userId: json["user_id"],
      category: json["category"],
      type: json["type"],
      amount: json["amount"],
      description: json["description"],
      date: DateTime.parse(json["date"]),
      user: json["User"] != null ? User.fromJson(json["User"]) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        type,
        amount,
        description,
        date,
        user,
      ];
}
