import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class NoteItem extends StatefulWidget {
  final String content;
  final DateTime date;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;
  final TextEditingController editController;

  const NoteItem({
    super.key,
    required this.content,
    required this.date,
    required this.onDelete,
    required this.onEdit,
    required this.editController,
  });

  @override
  State<NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<NoteItem> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppHelpers.formatDate(widget.date)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      onPressed: () {
                        if (_isEditing) {
                          widget.onEdit(widget.editController.text);
                        }
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isEditing
                ? TextField(
              controller: widget.editController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            )
                : Text(widget.editController.text),
          ],
        ),
      ),
    );
  }
}