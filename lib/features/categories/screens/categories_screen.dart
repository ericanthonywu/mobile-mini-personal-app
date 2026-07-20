import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/features/categories/providers/category_provider.dart';
import 'package:expense_tracker/features/categories/models/category_model.dart';
import 'package:expense_tracker/shared/widgets/app_error_widget.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final rulesAsync = ref.watch(merchantRulesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text('Categories', style: Theme.of(context).textTheme.headlineSmall),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Categories section
                Text('My Categories', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )),
                  error: (e, _) => AppErrorWidget(
                    error: e,
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                  data: (categories) => Column(
                    children: categories.map((cat) => _CategoryTile(category: cat)).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Merchant rules section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Merchant Rules', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () => _showAddRuleDialog(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically categorize transactions by merchant name',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                rulesAsync.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )),
                  error: (e, _) => AppErrorWidget(
                    error: e,
                    onRetry: () => ref.invalidate(merchantRulesProvider),
                  ),
                  data: (rules) => rules.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No rules yet. Tap + to add one.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : Column(
                          children: rules.map((rule) => _MerchantRuleTile(rule: rule)).toList(),
                        ),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddCategorySheet(ref: ref),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a category first before adding rules')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddRuleSheet(ref: ref, categories: categories),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final CategoryModel category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: category.colorValue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CircleAvatar(radius: 8, backgroundColor: category.colorValue),
          ),
        ),
        title: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: category.isDefault
            ? Text('Default', style: Theme.of(context).textTheme.labelSmall)
            : null,
        trailing: category.isDefault
            ? null
            : PopupMenuButton<String>(
                color: AppColors.surfaceVariant,
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditDialog(context, ref, category);
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref, category);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, CategoryModel cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddCategorySheet(ref: ref, existing: cat),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Category?'),
        content: Text('Delete "${cat.name}"? Transactions assigned to this category will lose their category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(categoriesProvider.notifier).delete(cat.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MerchantRuleTile extends ConsumerWidget {
  final MerchantRule rule;

  const _MerchantRuleTile({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = Color(
      int.parse('FF${rule.categoryColor.replaceAll('#', '')}', radix: 16),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
        title: Text(
          '"${rule.merchantPattern}"',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        subtitle: Row(
          children: [
            const Text('→ ', style: TextStyle(color: AppColors.textSecondary)),
            CircleAvatar(radius: 5, backgroundColor: categoryColor),
            const SizedBox(width: 4),
            Text(rule.categoryName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: categoryColor)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
          onPressed: () async {
            try {
              await ref.read(merchantRulesProvider.notifier).delete(rule.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final WidgetRef ref;
  final CategoryModel? existing;

  const _AddCategorySheet({required this.ref, this.existing});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  Color _selectedColor = AppColors.primary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _selectedColor = widget.existing!.colorValue;
    }
  }

  String get _colorHex => '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (widget.existing != null) {
        await widget.ref.read(categoriesProvider.notifier).update(
          widget.existing!.id,
          name: _nameController.text.trim(),
          color: _colorHex,
        );
      } else {
        await widget.ref.read(categoriesProvider.notifier).create(
          _nameController.text.trim(),
          _colorHex,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing != null ? 'Edit Category' : 'Add Category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          const SizedBox(height: 16),
          Text('Select Color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          // Color presets
          Wrap(
            spacing: 8,
            children: AppColors.categoryPresets.map((c) {
              final isSelected = _selectedColor.value == c.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _AddRuleSheet extends StatefulWidget {
  final WidgetRef ref;
  final List<CategoryModel> categories;

  const _AddRuleSheet({required this.ref, required this.categories});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  final _patternController = TextEditingController();
  CategoryModel? _selectedCategory;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_patternController.text.trim().isEmpty || _selectedCategory == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.ref.read(merchantRulesProvider.notifier).create(
        _patternController.text.trim(),
        _selectedCategory!.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Merchant Rule', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Automatically assign a category whenever merchant name contains this keyword.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _patternController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Merchant Keyword (e.g. SUPERINDO)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CategoryModel>(
            value: _selectedCategory,
            dropdownColor: AppColors.surfaceVariant,
            decoration: const InputDecoration(labelText: 'Category'),
            items: widget.categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: cat.colorValue),
                  const SizedBox(width: 8),
                  Text(cat.name),
                ],
              ),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Rule'),
          ),
        ],
      ),
    );
  }
}
