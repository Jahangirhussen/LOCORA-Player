import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../core/file_scanner.dart';
import 'pdf_models.dart';

const String pdfIndexBox = 'pdf_index';
const String pdfStateBox = 'pdf_state';
const _pdfExts = {'.pdf'};

class PdfIndexService {
  static Box get _box => Hive.box(pdfIndexBox);
  static Box get stateBox => Hive.box(pdfStateBox);

  static List<PdfEntry> cached() {
    final raw = _box.get('entries') as List?;
    if (raw == null) return [];
    return raw.map((e) => PdfEntry.fromJson(Map.from(e))).toList();
  }

  static Future<List<PdfEntry>> rescan() async {
    final hits = await scanForExtensions(_pdfExts);
    final pdfs = hits.map((h) => PdfEntry(path: h.path, name: pathFileName(h.path), sizeBytes: h.sizeBytes, modified: h.modified)).toList();
    await _box.put('entries', pdfs.map((e) => e.toJson()).toList());
    return pdfs;
  }

  static bool isFavorite(String path) => stateBox.get('fav:$path', defaultValue: false);
  static void toggleFavorite(String path) => stateBox.put('fav:$path', !isFavorite(path));

  static void recordOpened(String path) => stateBox.put('lastOpened:$path', DateTime.now().toIso8601String());
  static DateTime? lastOpened(String path) {
    final iso = stateBox.get('lastOpened:$path');
    return iso == null ? null : DateTime.tryParse(iso);
  }

  static int lastPage(String path) => stateBox.get('lastPage:$path', defaultValue: 0);
  static void saveLastPage(String path, int page) => stateBox.put('lastPage:$path', page);
}
