import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../widgets/loading_widgets.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final Group? group;
  final String? initialName;
  final String? initialDescription;

  const CreateGroupScreen({
    super.key,
    this.group,
    this.initialName,
    this.initialDescription,
  });

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? widget.group?.name ?? '',
    );
    _descController = TextEditingController(
      text: widget.initialDescription ?? widget.group?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.group != null;

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Group' : 'New Group'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'e.g. Trip to Goa',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add a short description (optional)',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const Spacer(),
            LoadingButton(
              isLoading: groupState.isCreating,
              label: _isEditing ? 'Update Group' : 'Create Group',
              loadingLabel: _isEditing ? 'Updating...' : 'Creating...',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (_isEditing) {
      ref.read(groupProvider.notifier).updateGroup(
            widget.group!.id,
            name,
            _descController.text.trim(),
          );
    } else {
      ref.read(groupProvider.notifier).createGroup(
            name,
            _descController.text.trim(),
          );
    }
    Navigator.pop(context);
  }
}
