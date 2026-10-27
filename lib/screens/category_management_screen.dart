import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../widgets/category_icon.dart';
import '../widgets/confirm_dialog.dart';

/// Screen allowing users to manage, rename, add, and archive income and expense categories.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(
      BuildContext context, IncomeExpenseType defaultType) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController();
    IncomeExpenseType selectedType = defaultType;
    String selectedIcon = 'more_horiz';
    int selectedColor = 0xFF2563EB; // Blue default

    final List<String> availableIcons = <String>[
      'work',
      'laptop',
      'trending_up',
      'card_giftcard',
      'wallet',
      'restaurant',
      'home',
      'lightbulb',
      'directions_car',
      'shopping_bag',
      'movie',
      'local_hospital',
      'school',
      'spa',
      'more_horiz',
    ];

    final List<int> availableColors = <int>[
      0xFF10B981, // Emerald
      0xFF0D9488, // Teal
      0xFF2563EB, // Blue
      0xFF4F46E5, // Indigo
      0xFF7C3AED, // Violet
      0xFFDB2777, // Pink
      0xFFEA580C, // Orange
      0xFFCA8A04, // Amber
      0xFFDC2626, // Red
      0xFF64748B, // Slate
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g. Gym, Books, Subscriptions',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (String? val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<IncomeExpenseType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            IncomeExpenseType.values.map((IncomeExpenseType t) {
                          return DropdownMenuItem<IncomeExpenseType>(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: (IncomeExpenseType? val) {
                          if (val != null) {
                            setModalState(() => selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose Icon',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((String iconKey) {
                          final bool isSelected = selectedIcon == iconKey;
                          return InkWell(
                            onTap: () =>
                                setModalState(() => selectedIcon = iconKey),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Color(selectedColor).withOpacity(0.2)
                                    : Colors.transparent,
                                border: isSelected
                                    ? Border.all(
                                        color: Color(selectedColor), width: 2)
                                    : Border.all(color: Colors.grey.shade300),
                              ),
                              child: CategoryIcon(
                                iconData: _getIconData(iconKey),
                                color: Color(selectedColor),
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose Color',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableColors.map((int colorVal) {
                          final bool isSelected = selectedColor == colorVal;
                          return InkWell(
                            onTap: () =>
                                setModalState(() => selectedColor = colorVal),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(colorVal),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.black, width: 2.5)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<FinanceProvider>().addCategory(
                          name: nameController.text.trim(),
                          type: selectedType,
                          iconKey: selectedIcon,
                          colorValue: selectedColor,
                        );
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, Category category) {
    final TextEditingController controller =
        TextEditingController(text: category.name);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            validator: (String? val) {
              if (val == null || val.trim().isEmpty) return 'Please enter name';
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final Category updated =
                  category.copyWith(name: controller.text.trim());
              await context.read<FinanceProvider>().updateCategory(updated);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleArchiveOrDelete(
      BuildContext context, Category category) async {
    final bool confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Archive Category',
      message:
          'Archive "${category.name}"? Existing past records will remain safe, '
          'but this category will no longer appear when recording new transactions.',
      confirmLabel: 'Archive',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await context
          .read<FinanceProvider>()
          .archiveOrDeleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder:
            (BuildContext context, FinanceProvider finance, Widget? child) {
          final List<Category> expenseCats = finance.categories
              .where((Category c) =>
                  c.incomeOrExpense == IncomeExpenseType.expense)
              .toList();

          final List<Category> incomeCats = finance.categories
              .where(
                  (Category c) => c.incomeOrExpense == IncomeExpenseType.income)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildCategoryList(expenseCats),
              _buildCategoryList(incomeCats),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final IncomeExpenseType currentType = _tabController.index == 0
              ? IncomeExpenseType.expense
              : IncomeExpenseType.income;
          _showAddCategoryDialog(context, currentType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        final Category cat = list[index];
        return ListTile(
          leading: CategoryIcon(
            iconData: cat.iconData,
            color: cat.color,
            size: 38,
          ),
          title: Row(
            children: <Widget>[
              Text(
                cat.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration:
                      cat.isArchived ? TextDecoration.lineThrough : null,
                  color: cat.isArchived ? Colors.grey : null,
                ),
              ),
              if (cat.isArchived) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Archived',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (String action) {
              if (action == 'rename') {
                _showRenameDialog(context, cat);
              } else if (action == 'archive') {
                _handleArchiveOrDelete(context, cat);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'rename',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              if (!cat.isArchived)
                const PopupMenuItem<String>(
                  value: 'archive',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.archive_outlined, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Archive', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static IconData _getIconData(String key) {
    switch (key) {
      case 'work':
        return Icons.work_outline;
      case 'laptop':
        return Icons.laptop_mac;
      case 'trending_up':
        return Icons.trending_up;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'restaurant':
        return Icons.restaurant;
      case 'home':
        return Icons.home_outlined;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'spa':
        return Icons.spa_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
