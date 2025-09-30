# Book Reader

A cross-platform e-book reader built with Flutter.  
Supports PDF, EPUB, and DOCX formats, with features like bookmarks, annotations, and reading progress tracking.

## Features

- 📚 Import and read PDF, EPUB, and DOCX files
- 🔖 Add and manage bookmarks
- 📝 Annotate pages and view annotations
- 📈 Track reading progress
- 🌙 Light and dark themes
- 🖥️ Runs on Android and Windows

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart 3.x
- For desktop: platform-specific requirements ([Flutter Desktop Docs](https://docs.flutter.dev/desktop))

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/book_reader.git
   cd book_reader

Install dependencies:

Run the app:

For mobile:
For desktop (e.g., Windows):
For web:
Project Structure
lib — Main Dart source code
views/ — UI screens (library, reader, etc.)
models/ — Data models (Book, Bookmark, Annotation)
services/ — File/database/epub handling
widgets/ — Reusable UI components
android, ios, macos, linux, windows, web — Platform-specific code
Dependencies
file_picker
sqflite
path_provider
syncfusion_flutter_pdfviewer
epub_view
docx_to_text
shared_preferences
See pubspec.yaml for the full list.

Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

License
MIT License

Copyright (c) 2024 Moises David Jimenez Ortiz (MJDev)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.