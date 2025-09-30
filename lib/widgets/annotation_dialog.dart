import 'package:book_reader/models/annotation.dart';
import 'package:flutter/material.dart';

class AnnotationDialog extends StatefulWidget {
  final int pageNumber;

  const AnnotationDialog({super.key, required this.pageNumber});

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Annotation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Page ${widget.pageNumber}'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter your note...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class AnnotationsDialog extends StatelessWidget {
  final List<Annotation> annotations;
  final Function(Annotation) onAnnotationSelected;
  final Function(Annotation) onAnnotationDeleted;

  const AnnotationsDialog({
    super.key,
    required this.annotations,
    required this.onAnnotationSelected,
    required this.onAnnotationDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Annotations'),
      content: annotations.isEmpty
          ? const Center(
              child: Text('No annotations yet'),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: annotations.length,
                itemBuilder: (context, index) {
                  final annotation = annotations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.note),
                      title: Text('Page ${annotation.pageNumber}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (annotation.selectedText.isNotEmpty)
                            Text(
                              '"${annotation.selectedText}"',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          Text(annotation.note),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(annotation.dateCreated),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onAnnotationDeleted(annotation),
                      ),
                      onTap: () => onAnnotationSelected(annotation),
                    ),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
