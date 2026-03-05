import 'package:caresens_plugin/caresens_plugin.dart';
import 'package:flutter/material.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _plugin = CaresensPlugin();
  final _controller = TextEditingController();
  DateTime? _lastCalibrationTime;
  bool _loading = false;
  CalibrationResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadLastCalibrationTime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLastCalibrationTime() async {
    final time = await _plugin.getLastCalibrationTime();
    setState(() => _lastCalibrationTime = time);
  }

  Future<void> _calibrate() async {
    final value = double.tryParse(_controller.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 혈당값을 입력하세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await _plugin.calibrate(value);
    setState(() {
      _lastResult = result;
      _lastCalibrationTime = result.calibrationTime;
      _loading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? '보정 완료' : '보정 실패: ${result.errorMessage}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('보정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('마지막 보정 시간', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      _lastCalibrationTime != null
                          ? _formatDateTime(_lastCalibrationTime!)
                          : '보정 기록 없음',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('핑거스틱 혈당값 입력 (mg/dL)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '예: 120',
                      suffixText: 'mg/dL',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _calibrate,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('보정'),
                ),
              ],
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _lastResult!.success
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _lastResult!.success ? Icons.check_circle : Icons.error,
                        color: _lastResult!.success ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(_lastResult!.success ? '보정 성공' : '보정 실패'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
