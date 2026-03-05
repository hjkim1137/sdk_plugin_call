import 'package:caresens_plugin/caresens_plugin.dart';
import 'package:flutter/material.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final _plugin = CaresensPlugin();
  DateTime? _lastUploadTime;
  bool _uploading = false;
  bool _exporting = false;
  String? _csvPreview;

  @override
  void initState() {
    super.initState();
    _loadLastUploadTime();
  }

  Future<void> _loadLastUploadTime() async {
    final time = await _plugin.getLastUploadTime();
    setState(() => _lastUploadTime = time);
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    final result = await _plugin.uploadData();
    setState(() {
      _uploading = false;
      if (result.success) {
        _lastUploadTime = result.uploadTime;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? '업로드 완료 (${result.recordCount}건)'
              : '업로드 실패: ${result.errorMessage}'),
        ),
      );
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final csv = await _plugin.exportToCsv(from: from, to: now);
    setState(() {
      _exporting = false;
      _csvPreview = csv.length > 500 ? '${csv.substring(0, 500)}...' : csv;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV 내보내기 완료')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('데이터 관리')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Upload section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('데이터 업로드', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastUploadTime != null
                              ? '마지막 업로드: ${_formatDateTime(_lastUploadTime!)}'
                              : '업로드 기록 없음',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _uploading ? null : _upload,
                      child: _uploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('지금 업로드'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Export section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('데이터 내보내기', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('최근 30일 데이터를 CSV로 내보냅니다.'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exporting ? null : _exportCsv,
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: const Text('CSV 내보내기'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CSV preview
          if (_csvPreview != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CSV 미리보기', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _csvPreview!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
