import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../theme/app_colors.dart';
import '../../core/file_scanner.dart';
import 'image_index.dart';
import 'image_models.dart';

class ImageViewerPage extends StatefulWidget {
  final List<ImageEntry> items;
  final int startIndex;
  const ImageViewerPage({super.key, required this.items, required this.startIndex});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late final PageController _pageController;
  late int _index;
  bool _controlsVisible = true;
  int _rotation = 0;
  Timer? _slideshowTimer;
  bool _slideshowOn = false;

  ImageEntry get _current => widget.items[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _pageController = PageController(initialPage: _index);
    ImageIndexService.recordViewed(_current.path);
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSlideshow() {
    setState(() => _slideshowOn = !_slideshowOn);
    if (_slideshowOn) {
      _slideshowTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_index + 1 < widget.items.length) {
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        } else {
          setState(() => _slideshowOn = false);
          _slideshowTimer?.cancel();
        }
      });
    } else {
      _slideshowTimer?.cancel();
    }
  }

  void _showInfo() {
    final img = _current;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(img.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${humanSize(img.sizeBytes)}'),
            Text('Modified: ${img.modified}'),
            const SizedBox(height: 8),
            Text('Location:\n${img.path}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (i) {
                setState(() {
                  _index = i;
                  _rotation = 0;
                });
                ImageIndexService.recordViewed(_current.path);
              },
              itemBuilder: (context, i) {
                final rotation = i == _index ? _rotation : 0;
                return RotatedBox(
                  quarterTurns: rotation ~/ 90,
                  child: PhotoView(
                    imageProvider: FileImage(File(widget.items[i].path)),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    backgroundDecoration: const BoxDecoration(color: Colors.black),
                    basePosition: Alignment.center,
                  ),
                );
              },
            ),
            if (_controlsVisible) ...[
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      Expanded(child: Text(_current.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(
                          ImageIndexService.isFavorite(_current.path) ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                        ),
                        onPressed: () {
                          ImageIndexService.toggleFavorite(_current.path);
                          setState(() {});
                        },
                      ),
                      IconButton(icon: const Icon(Icons.rotate_right, color: Colors.white), onPressed: () => setState(() => _rotation = (_rotation + 90) % 360)),
                      IconButton(
                        icon: Icon(_slideshowOn ? Icons.pause : Icons.slideshow, color: Colors.white),
                        onPressed: _toggleSlideshow,
                      ),
                      IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: _showInfo),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    onPressed: _index > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut) : null,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                    onPressed: _index < widget.items.length - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut) : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
