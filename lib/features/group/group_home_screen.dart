import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/models/group.dart';
import '../../domain/models/member.dart';
import '../../domain/models/group_expense.dart';
import '../../main.dart';

class GroupHomeScreen extends StatefulWidget {
  const GroupHomeScreen({super.key});

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  void _refresh() => setState(() {});

  void _showGroupOptions(BuildContext context, Group group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Group'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditGroupScreen(group: group),
                  ),
                );
                _refresh();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Group'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Group'),
                    content: Text('Are you sure you want to delete "${group.name}"? This will also delete all expenses in this group.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await group.delete();
                  _refresh();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = Hive.box<Group>('groups').values.cast<Group>().toList();
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FA),
      appBar: AppBar(
        title: const Text('Group Splits'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: groups.isEmpty
          ? const Center(
              child: Text('No groups yet.\nTap + to create one!', textAlign: TextAlign.center),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final group = groups[index];
                return Dismissible(
                  key: Key(group.key.toString()),
                  background: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.white, size: 30),
                        const SizedBox(width: 10),
                        const Text('EDIT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('DELETE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        const Icon(Icons.delete, color: Colors.white, size: 30),
                      ],
                    ),
                  ),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    print('Swipe direction: $direction'); // Debug print
                    if (direction == DismissDirection.startToEnd) {
                      // Edit group (swipe right)
                      print('Opening edit screen for group: ${group.name}'); // Debug print
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditGroupScreen(group: group),
                        ),
                      );
                      _refresh();
                      return false;
                    } else {
                      // Delete group (swipe left)
                      print('Opening delete dialog for group: ${group.name}'); // Debug print
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Group'),
                          content: Text('Are you sure you want to delete "${group.name}"? This will also delete all expenses in this group.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        print('Deleting group: ${group.name}'); // Debug print
                        await group.delete();
                        _refresh();
                        return true;
                      }
                      return false;
                    }
                  },
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(group.name),
                      subtitle: Text('${group.members.length} members'),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(group: group),
                          ),
                        );
                        _refresh();
                      },
                      onLongPress: () {
                        print('Long press detected on group: ${group.name}'); // Debug print
                        _showGroupOptions(context, group);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64B5F6),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGroupScreen()),
          );
          _refresh();
        },
      ),
    );
  }
}

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [TextEditingController()];

  @override
  void dispose() {
    _groupNameController.dispose();
    for (var c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length > 1) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      final members = _memberControllers
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .map((name) => Member(name: name))
          .toList();
      final group = Group(
        name: _groupNameController.text.trim(),
        members: members,
        expenses: [],
      );
      final box = Hive.box<Group>('groups');
      await box.add(group);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter group name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._memberControllers.asMap().entries.map((entry) {
                final idx = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Member ${idx + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Enter name' : null,
                      ),
                    ),
                    if (_memberControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeMemberField(idx),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Member'),
                  onPressed: _addMemberField,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Create Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final memberNames = _memberControllers
                        .map((c) => c.text.trim())
                        .where((name) => name.isNotEmpty)
                        .toSet();
                    if (memberNames.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add at least 2 unique members.')),
                      );
                      return;
                    }
                    _saveGroup();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditGroupScreen extends StatefulWidget {
  final Group group;
  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];

  @override
  void initState() {
    super.initState();
    _groupNameController.text = widget.group.name;
    for (final member in widget.group.members) {
      _memberControllers.add(TextEditingController(text: member.name));
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (var c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length > 1) {
      setState(() {
        _memberControllers[index].dispose();
        _memberControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveGroup() async {
    if (_formKey.currentState!.validate()) {
      final memberNames = _memberControllers
          .map((c) => c.text.trim())
          .where((name) => name.isNotEmpty)
          .toSet();
      
      if (memberNames.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least 2 unique members.')),
        );
        return;
      }

      final members = memberNames.map((name) => Member(name: name)).toList();
      
      // Update the group
      widget.group.name = _groupNameController.text.trim();
      widget.group.members = members;
      
      await widget.group.save();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Group')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter group name' : null,
              ),
              const SizedBox(height: 24),
              const Text('Members', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._memberControllers.asMap().entries.map((entry) {
                final idx = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Member ${idx + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? 'Enter name' : null,
                      ),
                    ),
                    if (_memberControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeMemberField(idx),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Member'),
                  onPressed: _addMemberField,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  List<_Settlement> _calculateSettlements(Group group) {
    final members = group.members;
    final balances = {for (var m in members) m.name: 0.0};
    for (final e in group.expenses) {
      final split = e.amount / e.forWhom.length;
      for (final m in e.forWhom) {
        balances[m.name] = (balances[m.name] ?? 0) - split;
      }
      balances[e.whoPaid.name] = (balances[e.whoPaid.name] ?? 0) + e.amount;
    }
    // Greedy settlement
    final settlements = <_Settlement>[];
    final debtors = <String, double>{};
    final creditors = <String, double>{};
    balances.forEach((name, bal) {
      if (bal < -0.01) debtors[name] = -bal;
      if (bal > 0.01) creditors[name] = bal;
    });
    final debtorList = debtors.entries.toList();
    final creditorList = creditors.entries.toList();
    int i = 0, j = 0;
    while (i < debtorList.length && j < creditorList.length) {
      final d = debtorList[i];
      final c = creditorList[j];
      final minAmt = d.value < c.value ? d.value : c.value;
      settlements.add(_Settlement(from: d.key, to: c.key, amount: minAmt));
      debtorList[i] = MapEntry(d.key, d.value - minAmt);
      creditorList[j] = MapEntry(c.key, c.value - minAmt);
      if (debtorList[i].value < 0.01) i++;
      if (creditorList[j].value < 0.01) j++;
    }
    return settlements;
  }

  void _editExpense(GroupExpense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddGroupExpenseScreen(group: widget.group, expenseToEdit: expense),
      ),
    );
    setState(() {});
  }

  void _deleteExpense(int idx) async {
    widget.group.expenses.removeAt(idx);
    await widget.group.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final settlements = _calculateSettlements(group);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Members:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: group.members.map((m) => Chip(label: Text(m.name))).toList(),
            ),
            const SizedBox(height: 24),
            Text('Expenses:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: group.expenses.isEmpty
                  ? const Center(child: Text('No expenses yet.'))
                  : ListView.separated(
                      itemCount: group.expenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final e = group.expenses[idx];
                        final forWhom = e.forWhom.map((m) => m.name).join(', ');
                        return Dismissible(
                          key: Key('${e.title}_${e.amount}_${e.date}_${e.whoPaid.name}'),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Expense'),
                                content: const Text('Are you sure you want to delete this expense?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _deleteExpense(idx);
                              return true;
                            }
                            return false;
                          },
                          child: Card(
                            child: ListTile(
                              title: Text('${e.title} - ${formatCurrency(e.amount, selectedCurrency)}'),
                              subtitle: Text('Paid by: ${e.whoPaid.name}\nFor: $forWhom'),
                              trailing: Text('${e.date.day}/${e.date.month}'),
                              onTap: () => _editExpense(e),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text('Settlement Summary:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            settlements.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('All settled up!'),
                    ),
                  )
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: settlements
                            .map((s) => Text('${s.from} pays ${s.to}: ${formatCurrency(s.amount, selectedCurrency)}'))
                            .toList(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64B5F6),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddGroupExpenseScreen(group: group),
            ),
          );
          setState(() {}); // Refresh after returning
        },
      ),
    );
  }
}

class _Settlement {
  final String from;
  final String to;
  final double amount;
  _Settlement({required this.from, required this.to, required this.amount});
}

class AddGroupExpenseScreen extends StatefulWidget {
  final Group group;
  final GroupExpense? expenseToEdit;
  const AddGroupExpenseScreen({super.key, required this.group, this.expenseToEdit});

  @override
  State<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends State<AddGroupExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Member? _selectedPayer;
  final Set<Member> _selectedForWhom = {};

  @override
  void initState() {
    super.initState();
    if (widget.group.members.isNotEmpty) {
      if (widget.expenseToEdit != null) {
        final e = widget.expenseToEdit!;
        _titleController.text = e.title;
        _amountController.text = e.amount.toString();
        _noteController.text = e.note ?? '';
        _selectedDate = e.date;
        _selectedPayer = widget.group.members.firstWhere((m) => m.name == e.whoPaid.name, orElse: () => widget.group.members.first);
        _selectedForWhom.clear();
        for (final m in e.forWhom) {
          final match = widget.group.members.firstWhere((mem) => mem.name == m.name, orElse: () => m);
          _selectedForWhom.add(match);
        }
      } else {
        _selectedPayer = widget.group.members.first;
        _selectedForWhom.addAll(widget.group.members);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate() && _selectedPayer != null && _selectedForWhom.isNotEmpty) {
      final newExpense = GroupExpense(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        whoPaid: _selectedPayer!,
        forWhom: _selectedForWhom.toList(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (widget.expenseToEdit != null) {
        final idx = widget.group.expenses.indexOf(widget.expenseToEdit!);
        if (idx != -1) {
          widget.group.expenses[idx] = newExpense;
        }
      } else {
        widget.group.expenses.add(newExpense);
      }
      await widget.group.save();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Member>(
                value: _selectedPayer,
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayer = val),
                decoration: const InputDecoration(
                  labelText: 'Who Paid?',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Select payer' : null,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'For Whom?',
                  border: OutlineInputBorder(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: members
                      .map((m) => CheckboxListTile(
                            value: _selectedForWhom.contains(m),
                            title: Text(m.name),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedForWhom.add(m);
                                } else {
                                  _selectedForWhom.remove(m);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
              if (_selectedForWhom.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Select at least one member', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedPayer != null && _selectedForWhom.isNotEmpty) {
                    _saveExpense();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 