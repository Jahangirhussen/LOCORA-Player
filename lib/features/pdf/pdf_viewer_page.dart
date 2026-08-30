import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../theme/app_colors.dart';
import '../../core/file_scanner.dart';
import 'pdf_index.dart';
import 'pdf_models.dart';

class PdfViewerPage extends StatefulWidget {
  final PdfEntry entry;
  const PdfViewerPage({super.key, required this.entry});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final PdfViewerController _controller;
  final TextEditingController _searchCtrl = TextEditingController();
  late final PdfTextSearcher _searcher;
  bool _searchOpen = false;
  int _pageCount = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _searcher = PdfTextSearcher(_controller);
    PdfIndexService.recordOpened(widget.entry.path);
  }

  @override
  void dispose() {
    _searcher.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showInfo() {
    final p = widget.entry;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${humanSize(p.sizeBytes)}'),
            Text('Pages: $_pageCount'),
            Text('Modified: ${p.modified}'),
            const SizedBox(height: 8),
            Text('Location:\n${p.path}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = PdfIndexService.isFavorite(widget.entry.path);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.entry.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(fav ? Icons.star : Icons.star_border, color: AppColors.accent),
            onPressed: () {
              PdfIndexService.toggleFavorite(widget.entry.path);
              setState(() {});
            },
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _searchOpen = !_searchOpen)),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfo),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search in document...',
                  suffixIcon: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _searchOpen = false)),
                ),
                onSubmitted: (v) => _searcher.startTextSearch(v),
              ),
            ),
          Expanded(
            child: PdfViewer.file(
              widget.entry.path,
              controller: _controller,
              params: PdfViewerParams(
                onDocumentChanged: (doc) {
                  if (doc != null) setState(() => _pageCount = doc.pages.length);
                },
                onPageChanged: (page) {
                  if (page != null) {
                    setState(() => _currentPage = page);
                    PdfIndexService.saveLastPage(widget.entry.path, page);
                  }
                },
              ),
            ),
          ),
          Container(
            height: 48,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _currentPage > 1 ? () => _controller.goToPage(pageNumber: _currentPage - 1) : null,
                ),
                Text('$_currentPage / $_pageCount', style: const TextStyle(fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _currentPage < _pageCount ? () => _controller.goToPage(pageNumber: _currentPage + 1) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
