import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_constants.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final List<GroupMember> members;
  final Expense? expense;

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.members,
    this.expense,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _amountController;
  late String _paidBy;
  late DateTime _selectedDate;
  late bool _isEqualSplit;
  late Map<String, bool> _checked;
  late Map<String, TextEditingController> _splitControllers;
  final Map<String, FocusNode> _splitFocusNodes = {};
  final Set<String> _lockedUserIds = {};
  bool _isAutoFilling = false;
  ExpenseCategory _selectedCategory = ExpenseCategory.all.last;
  bool _userEditedTitle = false;
  bool _userSelectedCategory = false;

  @override
  void initState() {
    super.initState();
    final active = widget.members.where((m) => m.leftAt == null).toList();

    if (widget.expense != null) {
      final e = widget.expense!;
      _titleController = TextEditingController(text: e.title);
      _descController = TextEditingController(text: e.description);
      _amountController = TextEditingController(text: AppFormat.number(e.amount));
      _paidBy = e.paidById;
      _selectedDate = e.date;
      _isEqualSplit = e.splitType == 'equal';
      _selectedCategory = ExpenseCategory.fromId(e.category);
      _userEditedTitle = e.title.isNotEmpty && e.title != _selectedCategory.defaultTitle;
      _userSelectedCategory = e.category.isNotEmpty;

      _checked = {};
      _splitControllers = {};
      for (final m in active) {
        final split = e.splits.where((s) => s.userId == m.userId).firstOrNull;
        _checked[m.userId] = split != null;
        _splitControllers[m.userId] = TextEditingController(
          text: split != null ? AppFormat.number(split.amount) : '',
        );
        _splitFocusNodes[m.userId] = FocusNode();
      }
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _amountController = TextEditingController();
      _selectedDate = DateTime.now();
      _isEqualSplit = true;
      _checked = {};
      _splitControllers = {};

      if (active.isNotEmpty) _paidBy = active.first.userId;
      for (final m in active) {
        _checked[m.userId] = true;
        _splitControllers[m.userId] = TextEditingController(text: '');
        _splitFocusNodes[m.userId] = FocusNode();
      }
    }

    _titleController.addListener(() {
      _userEditedTitle = true;
      if (!_userSelectedCategory) {
        final detected = ExpenseCategory.detectCategory(_titleController.text);
        if (detected.id != _selectedCategory.id) {
          setState(() => _selectedCategory = detected);
        }
      }
    });

    _amountController.addListener(() {
      _resetSplitState();
      setState(() {});
      _autoFillRemaining();
    });
    for (final c in _splitControllers.values) {
      c.addListener(_onSplitChanged);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    for (final f in _splitFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isEditing => widget.expense != null;

  void _resetSplitState() {
    _lockedUserIds.clear();
    _isAutoFilling = true;
    for (final m in _active) {
      _checked[m.userId] = true;
      _splitControllers[m.userId]!.text = '';
    }
    _isAutoFilling = false;
  }

  void _onSplitChanged() {
    if (_isAutoFilling) return;
    for (final entry in _splitFocusNodes.entries) {
      if (entry.value.hasFocus) {
        final val = double.tryParse(_splitControllers[entry.key]!.text.trim()) ?? 0;
        if (val > 0) _lockedUserIds.add(entry.key);
        break;
      }
    }
    _autoFillRemaining();
  }

  void _selectCategory() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final crossAxisCount = screenWidth < 360 ? 3 : 4;
        final itemWidth = (screenWidth - 32 - (crossAxisCount - 1) * 10) / crossAxisCount;
        final itemHeight = itemWidth * 1.15;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).brightness == Brightness.dark ? textPrimaryDark : textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: itemWidth / itemHeight,
                    ),
                    itemCount: ExpenseCategory.all.length,
                    itemBuilder: (_, i) {
                      final cat = ExpenseCategory.all[i];
                      final isSelected = cat.id == _selectedCategory.id;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _userSelectedCategory = true;
                          });
                          if (!_userEditedTitle) {
                            _titleController.text = cat.defaultTitle;
                          }
                          Navigator.pop(ctx);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(color: cat.color, width: 2)
                                    : null,
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 20),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? cat.color : (Theme.of(ctx).brightness == Brightness.dark ? textPrimaryDark : textPrimary),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<GroupMember> get _active =>
      widget.members.where((m) => m.leftAt == null).toList();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _autoFillRemaining() {
    if (_isAutoFilling || _isEqualSplit) return;
    final total = double.tryParse(_amountController.text.trim()) ?? 0;
    if (total <= 0) return;

    final checkedMembers = _active.where((m) => _checked[m.userId] == true).toList();
    if (checkedMembers.isEmpty) return;

    final lockedIds = _lockedUserIds.where((id) =>
      _checked[id] == true
    ).toSet();

    final autoMembers = checkedMembers.where((m) => !lockedIds.contains(m.userId)).toList();
    if (autoMembers.isEmpty) return;

    double lockedSum = 0;
    for (final id in lockedIds) {
      lockedSum += double.tryParse(_splitControllers[id]!.text.trim()) ?? 0;
    }

    final remaining = total - lockedSum;
    if (remaining <= 0) return;

    _isAutoFilling = true;
    final share = double.parse((remaining / autoMembers.length).toStringAsFixed(2));
    for (final m in autoMembers) {
      _splitControllers[m.userId]!.text = AppFormat.number(share);
    }
    _isAutoFilling = false;
    setState(() {});
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${widget.expense!.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(expenseProvider.notifier).deleteExpense(
                    widget.groupId,
                    widget.expense!.id,
                  );
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final checkedMembers = _active.where((m) => _checked[m.userId] == true).toList();
    if (checkedMembers.isEmpty) return;

    List<Map<String, dynamic>> splits;
    if (_isEqualSplit) {
      splits = checkedMembers.map((m) => {'user': m.userId, 'value': 1}).toList();
    } else {
      splits = checkedMembers.map((m) {
        final v = double.tryParse(_splitControllers[m.userId]!.text.trim()) ?? 0;
        return {'user': m.userId, 'value': v, 'amount': v};
      }).toList();
    }

    if (_isEditing) {
      ref.read(expenseProvider.notifier).updateExpense(
            widget.groupId,
            widget.expense!.id,
            title: title.isEmpty ? _selectedCategory.defaultTitle : title,
            description: '',
            category: _selectedCategory.id,
            amount: amount,
            paidBy: _paidBy,
            splitType: _isEqualSplit ? 'equal' : 'custom',
            splits: splits,
            date: _selectedDate.toIso8601String(),
          );
    } else {
      ref.read(expenseProvider.notifier).createExpense(
            widget.groupId,
            title: title.isEmpty ? _selectedCategory.defaultTitle : title,
            description: '',
            category: _selectedCategory.id,
            amount: amount,
            paidBy: _paidBy,
            splitType: _isEqualSplit ? 'equal' : 'custom',
            splits: splits,
            date: _selectedDate.toIso8601String(),
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currentCurrencyProvider);
    final active = _active;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 22),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          autofocus: !_isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Dinner',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _selectCategory,
                        child: Container(
                          width: 52,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _selectedCategory.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedCategory.color.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _selectedCategory.icon,
                            color: _selectedCategory.color,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Total Amount',
                            prefixText: '${currency.symbol} ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<String>(
                          value: _paidBy,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Paid by'),
                          items: active
                              .map((m) => DropdownMenuItem<String>(
                                    value: m.userId,
                                    child: Text(m.name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _paidBy = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      decoration: BoxDecoration(
                        color: isDark ? surfaceBgDark : surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? borderDark : borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: isDark ? textSecondaryDark : textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? textPrimaryDark : textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down,
                              color: isDark ? textSecondaryDark : textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(color: isDark ? borderDark : borderLight, height: 1),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 18,
                          color: isDark ? textSecondaryDark : textSecondary),
                      const SizedBox(width: 8),
                      Text('Split',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? textPrimaryDark : textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? surfaceBgDark : surfaceBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Equally')),
                              ButtonSegment(value: false, label: Text('By Amount')),
                            ],
                            selected: {_isEqualSplit},
                            onSelectionChanged: (v) {
                              setState(() => _isEqualSplit = v.first);
                              _resetSplitState();
                              if (!v.first) _autoFillRemaining();
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return accent;
                                return Colors.transparent;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return Colors.white;
                                return isDark ? textPrimaryDark : textPrimary;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Divider(color: isDark ? borderDark : borderLight, height: 1, indent: 8, endIndent: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Row(
                            children: [
                              Text('Members',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? textSecondaryDark : textSecondary)),
                              const Spacer(),
                              Text('Amount',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? textSecondaryDark : textSecondary)),
                            ],
                          ),
                        ),
                        ...active.map((m) {
                    final checked = _checked[m.userId] ?? true;
                    final ctrl = _splitControllers[m.userId]!;
                    final total = double.tryParse(_amountController.text.trim()) ?? 0.0;
                    final checkedCount = active.where((x) => _checked[x.userId] == true).length;
                    final equalAmount = checkedCount > 0 ? total / checkedCount : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: checked,
                            activeColor: accent,
                            onChanged: (v) {
                              setState(() => _checked[m.userId] = v!);
                              if (!v!) _lockedUserIds.remove(m.userId);
                              _autoFillRemaining();
                            },
                          ),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: accent.withValues(alpha: 0.08),
                            backgroundImage: m.avatar.isNotEmpty
                                ? NetworkImage(m.avatar)
                                : null,
                            child: m.avatar.isEmpty
                                ? Text(m.name[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(m.name,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? textPrimaryDark : textPrimary)),
                          ),
                          SizedBox(
                            width: 100,
                            child: _isEqualSplit
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: (isDark ? borderDark : borderLight).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      checked
                                          ? currency.format(equalAmount)
                                          : '—',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? textSecondaryDark : textSecondary),
                                    ),
                                  )
                                : TextField(
                                    controller: ctrl,
                                    focusNode: _splitFocusNodes[m.userId],
                                    decoration: InputDecoration(
                                      hintText: currency.symbol,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                    keyboardType: TextInputType.number,
                                    enabled: checked,
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? cardBgDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? borderDark : borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Update Expense' : 'Add Expense'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
