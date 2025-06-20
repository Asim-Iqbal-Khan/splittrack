import 'package:hive/hive.dart';

part 'member.g.dart';

@HiveType(typeId: 1)
class Member extends HiveObject {
  @HiveField(0)
  String name;

  Member({required this.name});
} 