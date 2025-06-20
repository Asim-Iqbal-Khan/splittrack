import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../domain/models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;
  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';

  late AnimationController _animController;
  late Animation<Offset> _slideIn;

  final List<String> _categories = [
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Expense>('expenses');
      final newExpense = Expense(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim(),
      );
      await box.add(newExpense);
      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideIn,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF7FA),
        appBar: AppBar(
          title: const Text('Add Expense'),
          backgroundColor: const Color(0xFF90CAF9),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField(
                  controller: _amountController,
                  label: 'Amount (Rs)',
                  hint: 'e.g. 1200',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildDropdown(),
                const SizedBox(height: 16),
                _buildDateSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'Optional',
                  validator: (val) => null,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveExpense,
          icon: const Icon(Icons.check),
          label: const Text('Save'),
          backgroundColor: const Color(0xFF64B5F6),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? ((val) =>
          (val == null || val.trim().isEmpty) ? 'Required' : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories
          .map((c) =>
              DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() {
        _selectedCategory = val!;
      }),
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMM, yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
