import 'package:hive/hive.dart';
import 'member.dart';

part 'group_expense.g.dart';

@HiveType(typeId: 2)
class GroupExpense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  Member whoPaid;

  @HiveField(4)
  List<Member> forWhom;

  @HiveField(5)
  String? note;

  GroupExpense({
    required this.title,
    required this.amount,
    required this.date,
    required this.whoPaid,
    required this.forWhom,
    this.note,
  });
} 