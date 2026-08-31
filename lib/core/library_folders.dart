import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

const String libraryFoldersBox = 'library_folders';

enum StandardFolder { desktop, documents, downloads, pictures, videos, music }

extension StandardFolderLabel on StandardFolder {
  String get label => switch (this) {
        StandardFolder.desktop => 'Desktop',
        StandardFolder.documents => 'Documents',
        StandardFolder.downloads => 'Downloads',
        StandardFolder.pictures => 'Pictures',
        StandardFolder.videos => 'Videos',
        StandardFolder.music => 'Music',
      };
}

enum FolderAccessStatus { granted, denied, unavailable }

class AuthorizedFolder {
  final String path;
  final FolderAccessStatus status;
  const AuthorizedFolder(this.path, this.status);
}

/// Real native folder authorization — no fake permission booleans. Every
/// entry here was granted through the OS's own folder picker (desktop) or
/// verified accessible on disk (standard dirs), and is re-validated every
/// time it's read since access can be revoked outside the app.
class LibraryFoldersService {
  static Box get _box => Hive.box(libraryFoldersBox);

  static List<String> _storedPaths() => _box.get('paths', defaultValue: <String>[]).cast<String>();

  static Future<List<AuthorizedFolder>> authorizedFolders() async {
    final paths = _storedPaths();
    final out = <AuthorizedFolder>[];
    for (final p in paths) {
      final status = await _revalidate(p);
      out.add(AuthorizedFolder(p, status));
    }
    return out;
  }

  static Future<FolderAccessStatus> _revalidate(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return FolderAccessStatus.unavailable;
      // Actually attempt to list it — this is what "granted" means here,
      // not just an on/off flag we set once and trust forever.
      await dir.list().take(1).toList();
      return FolderAccessStatus.granted;
    } on FileSystemException {
      return FolderAccessStatus.denied;
    } catch (_) {
      return FolderAccessStatus.unavailable;
    }
  }

  static Future<void> addFolder(String path) async {
    final paths = _storedPaths();
    if (!paths.contains(path)) {
      paths.add(path);
      await _box.put('paths', paths);
    }
  }

  static Future<void> removeFolder(String path) async {
    final paths = _storedPaths()..remove(path);
    await _box.put('paths', paths);
  }

  /// Opens the real OS folder-selection dialog (native on desktop/Android
  /// via file_picker) and, if the user picks one, authorizes it.
  static Future<String?> pickCustomFolder() async {
    final path = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a folder for LOCORA Player to index');
    if (path != null) await addFolder(path);
    return path;
  }

  static Future<String?> standardFolderPath(StandardFolder f) async {
    try {
      switch (f) {
        case StandardFolder.desktop:
          if (Platform.isWindows) {
            final home = Platform.environment['USERPROFILE'];
            if (home == null) return null;
            final p = '$home\\Desktop';
            return await Directory(p).exists() ? p : null;
          }
          return null; // no reliable cross-platform Desktop dir elsewhere
        case StandardFolder.documents:
          return (await getApplicationDocumentsDirectory()).path;
        case StandardFolder.downloads:
          final dir = await getDownloadsDirectory();
          return dir?.path;
        case StandardFolder.pictures:
          if (Platform.isAndroid) return '/storage/emulated/0/Pictures';
          if (Platform.isWindows) {
            final home = Platform.environment['USERPROFILE'];
            return home == null ? null : '$home\\Pictures';
          }
          return null;
        case StandardFolder.videos:
          if (Platform.isAndroid) return '/storage/emulated/0/Movies';
          if (Platform.isWindows) {
            final home = Platform.environment['USERPROFILE'];
            return home == null ? null : '$home\\Videos';
          }
          return null;
        case StandardFolder.music:
          if (Platform.isAndroid) return '/storage/emulated/0/Music';
          if (Platform.isWindows) {
            final home = Platform.environment['USERPROFILE'];
            return home == null ? null : '$home\\Music';
          }
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  static bool get hasCompletedOnboarding => _box.get('onboarded', defaultValue: false);
  static Future<void> markOnboarded() => _box.put('onboarded', true);
}
