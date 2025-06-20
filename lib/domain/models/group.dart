import 'package:hive/hive.dart';
import 'member.dart';
import 'group_expense.dart';

part 'group.g.dart';

@HiveType(typeId: 3)
class Group extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Member> members;

  @HiveField(2)
  List<GroupExpense> expenses;

  Group({
    required this.name,
    required this.members,
    required this.expenses,
  });

  Future<void> delete() async {
    await super.delete();
  }
} 