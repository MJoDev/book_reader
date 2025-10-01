import 'package:flutter/material.dart';

class DocxReader extends StatelessWidget {
  const DocxReader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'DOCX Reader',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'To be implemented with docx_to_text package',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
