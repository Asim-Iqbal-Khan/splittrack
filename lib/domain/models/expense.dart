import 'package:hive/hive.dart';

part 'expense.g.dart'; // needed for generated file

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String category;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? note;

  Expense({
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });
}
