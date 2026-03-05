import 'dart:async';

import 'package:caresens_plugin/caresens_plugin.dart';
import 'package:flutter/material.dart';

class MeterConnectionScreen extends StatefulWidget {
  const MeterConnectionScreen({super.key});

  @override
  State<MeterConnectionScreen> createState() => _MeterConnectionScreenState();
}

class _MeterConnectionScreenState extends State<MeterConnectionScreen> {
  final _plugin = CaresensPlugin();
  final List<BloodGlucoseMeter> _meters = [];
  List<BloodGlucoseMeter> _connectedMeters = [];
  bool _scanning = false;
  StreamSubscription? _scanSub;

  @override
  void initState() {
    super.initState();
    _loadConnectedMeters();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _loadConnectedMeters() async {
    final meters = await _plugin.getConnectedMeters();
    setState(() => _connectedMeters = meters);
  }

  void _startScan() {
    setState(() {
      _meters.clear();
      _scanning = true;
    });
    _scanSub?.cancel();
    _scanSub = _plugin.scanForMeters().listen((meter) {
      setState(() {
        _meters.removeWhere((m) => m.deviceId == meter.deviceId);
        _meters.add(meter);
      });
    });
  }

  void _stopScan() {
    _scanSub?.cancel();
    setState(() => _scanning = false);
  }

  Future<void> _connectMeter(String meterId) async {
    final success = await _plugin.connectMeter(meterId);
    if (success) {
      await _loadConnectedMeters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('측정기 연결 완료')),
        );
      }
    }
  }

  Future<void> _disconnectMeter(String meterId) async {
    await _plugin.disconnectMeter(meterId);
    await _loadConnectedMeters();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('측정기 연결 해제')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('혈당 측정기 연결')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connected meters
          if (_connectedMeters.isNotEmpty) ...[
            Text('연결된 측정기', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._connectedMeters.map((meter) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices, color: Colors.blue),
                    title: Text(meter.name),
                    subtitle: Text(_meterTypeLabel(meter.type)),
                    trailing: TextButton(
                      onPressed: () => _disconnectMeter(meter.deviceId),
                      child: const Text('해제'),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Scan section
          Row(
            children: [
              Text('주변 측정기 검색', style: theme.textTheme.titleMedium),
              const Spacer(),
              _scanning
                  ? FilledButton.tonal(
                      onPressed: _stopScan,
                      child: const Text('중지'),
                    )
                  : FilledButton(
                      onPressed: _startScan,
                      child: const Text('스캔'),
                    ),
            ],
          ),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: 8),
          if (_meters.isEmpty && !_scanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('스캔을 시작하여 측정기를 검색하세요.'),
              ),
            ),
          ..._meters.map((meter) => Card(
                child: ListTile(
                  leading: Icon(
                    meter.type == MeterType.bluetooth
                        ? Icons.bluetooth
                        : Icons.devices,
                  ),
                  title: Text(meter.name),
                  subtitle: Text(_meterTypeLabel(meter.type)),
                  trailing: meter.isConnected
                      ? const Chip(label: Text('연결됨'))
                      : FilledButton(
                          onPressed: () => _connectMeter(meter.deviceId),
                          child: const Text('연결'),
                        ),
                ),
              )),
        ],
      ),
    );
  }

  String _meterTypeLabel(MeterType type) {
    return switch (type) {
      MeterType.standard => '개인용 혈당 측정기',
      MeterType.bluetooth => '블루투스 혈당 측정기',
    };
  }
}
