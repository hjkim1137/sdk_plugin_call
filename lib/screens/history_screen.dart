import 'package:caresens_plugin/caresens_plugin.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _plugin = CaresensPlugin();
  List<GlucoseRecord>? _records;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final records = await _plugin.fetchHistory();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('측정 이력')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records == null || _records!.isEmpty
              ? const Center(child: Text('측정 이력이 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = _records![index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _glucoseColor(r.value).withValues(alpha: 0.2),
                            child: Text(
                              r.value.toStringAsFixed(0),
                              style: TextStyle(
                                color: _glucoseColor(r.value),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            '${r.value.toStringAsFixed(r.unit == "mg/dL" ? 0 : 1)} ${r.unit}  ${_trendArrow(r.trend)}',
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            '${_formatDate(r.timestamp)}  •  ${_mealTagLabel(r.mealTag)}  •  ${_trendLabel(r.trend)}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _glucoseColor(double value) {
    if (value < 70) return Colors.orange;
    if (value > 180) return Colors.red;
    return Colors.green;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _mealTagLabel(String tag) {
    return switch (tag) {
      'fasting' => '공복',
      'before_meal' => '식전',
      'after_meal' => '식후',
      'bedtime' => '취침 전',
      _ => '임의',
    };
  }

  String _trendArrow(GlucoseTrend trend) {
    return switch (trend) {
      GlucoseTrend.rapidlyRising => '↑↑',
      GlucoseTrend.rising => '↑',
      GlucoseTrend.stable => '→',
      GlucoseTrend.falling => '↓',
      GlucoseTrend.rapidlyFalling => '↓↓',
      GlucoseTrend.unknown => '?',
    };
  }

  String _trendLabel(GlucoseTrend trend) {
    return switch (trend) {
      GlucoseTrend.rapidlyRising => '급상승',
      GlucoseTrend.rising => '상승',
      GlucoseTrend.stable => '안정',
      GlucoseTrend.falling => '하강',
      GlucoseTrend.rapidlyFalling => '급하강',
      GlucoseTrend.unknown => '-',
    };
  }
}
