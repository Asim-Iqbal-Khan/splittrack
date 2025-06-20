import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'domain/models/expense.dart';
import 'domain/models/member.dart';
import 'domain/models/group_expense.dart';
import 'domain/models/group.dart';
import 'features/personal/add_expense_screen.dart';
import 'features/group/group_home_screen.dart';
import 'features/auth/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Currency configuration
class Currency {
  final String code;
  final String symbol;
  final String name;
  
  Currency({required this.code, required this.symbol, required this.name});
}

final List<Currency> availableCurrencies = [
  Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
];

final selectedCurrencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(availableCurrencies[0]) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('selected_currency') ?? 'INR';
    final currency = availableCurrencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => availableCurrencies[0],
    );
    state = currency;
  }

  Future<void> setCurrency(Currency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency.code);
    state = currency;
  }
}

String formatCurrency(double amount, Currency currency) {
  return '${currency.symbol}${amount.toStringAsFixed(2)}';
}

Future<File> exportExpensesToPDF(List<Expense> expenses, Currency currency) async {
  final pdf = pw.Document();
  
  // Add a page
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => [
        // Header
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SplitTrack - Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generated: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Summary
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Total Expenses: ${expenses.length}'),
              pw.Text('Total Amount: ${formatCurrency(expenses.fold(0.0, (sum, e) => sum + e.amount), currency)}'),
              pw.Text('Currency: ${currency.name} (${currency.code})'),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Category breakdown
        pw.Text(
          'Expenses by Category',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        
        // Category table
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header row
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Category data rows
            ..._getCategoryBreakdown(expenses).entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.value['count'].toString()),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(formatCurrency(entry.value['amount'], currency)),
                ),
              ],
            )),
          ],
        ),
        
        pw.SizedBox(height: 20),
        
        // Detailed expenses
        pw.Text(
          'Detailed Expenses',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        
        // Expenses table
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header row
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Expense data rows
            ...expenses.map((expense) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(expense.category),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(formatCurrency(expense.amount, currency)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(expense.note ?? '-'),
                ),
              ],
            )),
          ],
        ),
      ],
    ),
  );
  
  // Save the PDF
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
  await file.writeAsBytes(await pdf.save());
  
  return file;
}

Map<String, Map<String, dynamic>> _getCategoryBreakdown(List<Expense> expenses) {
  final breakdown = <String, Map<String, dynamic>>{};
  
  for (final expense in expenses) {
    if (!breakdown.containsKey(expense.category)) {
      breakdown[expense.category] = {'count': 0, 'amount': 0.0};
    }
    breakdown[expense.category]!['count'] = breakdown[expense.category]!['count'] + 1;
    breakdown[expense.category]!['amount'] = breakdown[expense.category]!['amount'] + expense.amount;
  }
  
  return breakdown;
}

enum AppThemeMode { system, light, dark }

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';
    state = AppThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => AppThemeMode.system,
    );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    state = mode;
  }
}

ThemeMode getFlutterThemeMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
    default:
      return ThemeMode.system;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(MemberAdapter());
  Hive.registerAdapter(GroupExpenseAdapter());
  Hive.registerAdapter(GroupAdapter());
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Group>('groups');

  runApp(const ProviderScope(child: SplitTrackApp()));
}

class SplitTrackApp extends ConsumerWidget {
  const SplitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SplitTrack',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF90CAF9),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: getFlutterThemeMode(appThemeMode),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavScreen(),
      },
    );
  }
}

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    GroupHomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Personal',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Cache expensive calculations
  List<Expense>? _cachedAllExpenses;
  List<Expense>? _cachedFilteredExpenses;
  Map<String, double>? _cachedCategoryTotals;
  List<String>? _cachedCategories;

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses.where((e) {
      final matchesCategory = _selectedCategory == null || e.category == _selectedCategory;
      final matchesStart = _startDate == null || !e.date.isBefore(_startDate!);
      final matchesEnd = _endDate == null || !e.date.isAfter(_endDate!);
      return matchesCategory && matchesStart && matchesEnd;
    }).toList();
  }

  Map<String, double> _categoryTotals(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void _updateCachedData(List<Expense> allExpenses) {
    final now = DateTime.now();
    final thisMonthExpenses = allExpenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    
    _cachedAllExpenses = allExpenses;
    _cachedFilteredExpenses = _filterExpenses(allExpenses);
    _cachedCategoryTotals = _categoryTotals(thisMonthExpenses);
    _cachedCategories = allExpenses.map((e) => e.category).toSet().toList();
  }

  void _updateFilters() {
    if (_cachedAllExpenses != null) {
      _cachedFilteredExpenses = _filterExpenses(_cachedAllExpenses!);
      setState(() {}); // Trigger rebuild with new filtered data
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _updateFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FA),
      appBar: AppBar(
        title: const Text('SplitTrack'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, Box<Expense> box, __) {
          final allExpenses = box.values.toList().reversed.toList();
          
          // Only update cache if data actually changed
          if (_cachedAllExpenses != allExpenses) {
            _updateCachedData(allExpenses);
          }

          if (allExpenses.isEmpty) {
            return const Center(
              child: Text('No expenses yet.\nTap + to add one!', textAlign: TextAlign.center),
            );
          }

          return Column(
            children: [
              // App bar with export button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Expenses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      onPressed: () async {
                        try {
                          final file = await exportExpensesToPDF(allExpenses, selectedCurrency);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('PDF exported successfully!\nSaved to: ${file.path}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to export PDF: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      tooltip: 'Export to PDF',
                    ),
                  ],
                ),
              ),
              // Pie chart for this month
              if (_cachedCategoryTotals!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 200,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('This Month by Category (${selectedCurrency.symbol})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    for (final entry in _cachedCategoryTotals!.entries)
                                      PieChartSectionData(
                                        value: entry.value,
                                        title: '${entry.key}\n${formatCurrency(entry.value, selectedCurrency)}',
                                        color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: const Text('Category'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                          ..._cachedCategories!.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                          _updateFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_startDate != null && _endDate != null
                          ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                          : 'Date Range'),
                      onPressed: () => _pickDateRange(context),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _updateFilters();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Filtered expense list
              Expanded(
                child: _cachedFilteredExpenses!.isEmpty
                    ? const Center(child: Text('No expenses match the filter.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cachedFilteredExpenses!.length,
                        itemBuilder: (context, index) {
                          final e = _cachedFilteredExpenses![index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Dismissible(
                              key: Key(e.key.toString()),
                              background: swipeActionLeft(),
                              secondaryBackground: swipeActionRight(),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  return await _confirmDelete(context, e);
                                } else {
                                  _editExpense(context, e);
                                  return false;
                                }
                              },
                              child: _ExpenseTile(expense: e),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF64B5F6),
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),
    );
  }

  Widget swipeActionLeft() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        color: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      );

  Widget swipeActionRight() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      );

  Future<bool> _confirmDelete(BuildContext context, Expense expense) async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Expense"),
            content: const Text("Are you sure you want to delete this?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () {
                    expense.delete();
                    Navigator.pop(context, true);
                  },
                  child: const Text("Delete")),
            ],
          ),
        ) ??
        false;
  }

  void _editExpense(BuildContext context, Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(expenseToEdit: expense),
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const _ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long_rounded),
        title: Text('${expense.category} - ${formatCurrency(expense.amount, selectedCurrency)}'),
        subtitle: Text(expense.note ?? ''),
        trailing: Text(
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(selectedCurrencyProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FA),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF90CAF9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Currency',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Currency>(
                      value: selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Select Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text('${currency.symbol} ${currency.name} (${currency.code})'),
                        );
                      }).toList(),
                      onChanged: (currency) {
                        if (currency != null) {
                          ref.read(selectedCurrencyProvider.notifier).setCurrency(currency);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Example: ${formatCurrency(1234.56, selectedCurrency)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AppThemeMode>(
                      value: ref.watch(themeModeProvider),
                      decoration: const InputDecoration(
                        labelText: 'App Theme',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AppThemeMode.system,
                          child: Text('System Default'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setTheme(mode);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.description_outlined),
                      title: Text('SplitTrack'),
                      subtitle: Text('Personal & Group Expense Tracker'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
