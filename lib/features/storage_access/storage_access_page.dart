import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../core/library_folders.dart';

/// Real native folder authorization screen. Every folder listed here was
/// either verified to exist on disk (standard dirs) or picked through the
/// OS's own native folder dialog (file_picker) — never a fake toggle.
class StorageAccessPage extends StatefulWidget {
  final VoidCallback? onDone;
  const StorageAccessPage({super.key, this.onDone});

  @override
  State<StorageAccessPage> createState() => _StorageAccessPageState();
}

class _StorageAccessPageState extends State<StorageAccessPage> {
  List<AuthorizedFolder> _authorized = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await LibraryFoldersService.authorizedFolders();
    setState(() {
      _authorized = list;
      _loading = false;
    });
  }

  Future<void> _addStandard(StandardFolder f) async {
    final path = await LibraryFoldersService.standardFolderPath(f);
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label} is not available on this platform.'), backgroundColor: AppColors.danger));
      return;
    }
    await LibraryFoldersService.addFolder(path);
    _refresh();
  }

  Future<void> _addCustom() async {
    final path = await LibraryFoldersService.pickCustomFolder();
    if (path != null) _refresh();
  }

  Future<void> _remove(String path) async {
    await LibraryFoldersService.removeFolder(path);
    _refresh();
  }

  bool _isAuthorized(String? path) => path != null && _authorized.any((a) => a.path == path);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Storage & Library Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('LOCORA Player only indexes folders you explicitly choose. Nothing is scanned automatically.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: StandardFolder.values.map((f) {
              return FutureBuilder<String?>(
                future: LibraryFoldersService.standardFolderPath(f),
                builder: (context, snap) {
                  final path = snap.data;
                  final authorized = _isAuthorized(path);
                  final available = snap.connectionState == ConnectionState.done && path != null;
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: authorized,
                    onSelected: available ? (_) => authorized ? _remove(path) : _addStandard(f) : null,
                    avatar: available ? null : const Icon(Icons.block, size: 14),
                    disabledColor: AppColors.card,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _addCustom, icon: const Icon(Icons.create_new_folder_outlined, size: 18), label: const Text('Add Custom Folder')),
          const SizedBox(height: 28),
          const Text('Authorized Locations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.accent)))
          else if (_authorized.isEmpty)
            const Text('No folders authorized yet. Add one above to start indexing.', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
          else
            ..._authorized.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      Icon(Icons.folder, size: 18, color: f.status == FolderAccessStatus.granted ? AppColors.accent : AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.path, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            Text(_statusLabel(f.status), style: TextStyle(fontSize: 11, color: f.status == FolderAccessStatus.granted ? AppColors.success : AppColors.danger)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: () => _remove(f.path), child: const Text('Remove')),
                    ],
                  ),
                )),
          if (widget.onDone != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await LibraryFoldersService.markOnboarded();
                widget.onDone?.call();
              },
              child: const Text('Continue'),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(FolderAccessStatus s) => switch (s) {
        FolderAccessStatus.granted => 'Access: Granted',
        FolderAccessStatus.denied => 'Access: Denied — tap Remove and re-add to re-authorize',
        FolderAccessStatus.unavailable => 'Access: Unavailable — folder no longer exists',
      };
}
