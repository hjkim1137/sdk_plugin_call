import 'dart:async';

import 'package:caresens_plugin/caresens_plugin.dart';
import 'package:flutter/material.dart';

import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _plugin = CaresensPlugin();

  final List<CaresensDevice> _devices = [];
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  String? _connectedDeviceId;
  GlucoseRecord? _latestGlucose;
  DeviceInfo? _deviceInfo;
  bool _scanning = false;

  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _glucoseSub;

  @override
  void initState() {
    super.initState();
    _connectionSub = _plugin.connectionState.listen((state) {
      setState(() => _connectionState = state);
    });
    _glucoseSub = _plugin.glucoseData.listen((record) {
      setState(() => _latestGlucose = record);
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _glucoseSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
    });
    _scanSub?.cancel();
    _scanSub = _plugin.scanResults.listen((device) {
      setState(() {
        _devices.removeWhere((d) => d.deviceId == device.deviceId);
        _devices.add(device);
      });
    });
    await _plugin.startScan(timeout: 5000);
  }

  Future<void> _stopScan() async {
    await _plugin.stopScan();
    _scanSub?.cancel();
    setState(() => _scanning = false);
  }

  Future<void> _connect(String deviceId) async {
    await _stopScan();
    final success = await _plugin.connect(deviceId);
    if (success) {
      _connectedDeviceId = deviceId;
      final info = await _plugin.getDeviceInfo();
      setState(() => _deviceInfo = info);
    }
  }

  Future<void> _disconnect() async {
    await _plugin.disconnect();
    setState(() {
      _connectedDeviceId = null;
      _latestGlucose = null;
      _deviceInfo = null;
    });
  }

  bool get _isConnected => _connectionState == BleConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareSens Air'),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: '측정 이력',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: _isConnected ? Colors.blue : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectionState.name.toUpperCase(),
                          style: theme.textTheme.titleMedium,
                        ),
                        if (_connectedDeviceId != null) Text('Device: $_connectedDeviceId', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (_isConnected)
                    FilledButton.tonal(
                      onPressed: _disconnect,
                      child: const Text('연결 해제'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Device info
          if (_deviceInfo != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('디바이스 정보', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _infoRow('모델', _deviceInfo!.modelName),
                    _infoRow('시리얼', _deviceInfo!.serialNumber),
                    _infoRow('펌웨어', _deviceInfo!.firmwareVersion),
                    _infoRow('배터리', '${_deviceInfo!.batteryLevel}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Latest glucose reading
          if (_latestGlucose != null) ...[
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('혈당 측정값', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      _latestGlucose!.value.toStringAsFixed(_latestGlucose!.unit == "mg/dL" ? 0 : 1),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _glucoseColor(_latestGlucose!.value),
                      ),
                    ),
                    Text(_latestGlucose!.unit, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Chip(label: Text(_mealTagLabel(_latestGlucose!.mealTag))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Scan section
          if (!_isConnected) ...[
            Row(
              children: [
                Text('주변 디바이스', style: theme.textTheme.titleMedium),
                const Spacer(),
                _scanning
                    ? FilledButton.tonal(
                        onPressed: _stopScan,
                        child: const Text('스캔 중지'),
                      )
                    : FilledButton(
                        onPressed: _startScan,
                        child: const Text('스캔 시작'),
                      ),
              ],
            ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 8),
            if (_devices.isEmpty && !_scanning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('스캔을 시작하여 디바이스를 검색하세요.'),
                ),
              ),
            ..._devices.map((device) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(device.name),
                    subtitle: Text('${device.mac}  •  RSSI: ${device.rssi}'),
                    trailing: _connectionState == BleConnectionState.connecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton(
                            onPressed: () => _connect(device.deviceId),
                            child: const Text('연결'),
                          ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value),
        ],
      ),
    );
  }

  Color _glucoseColor(double value) {
    if (value < 70) return Colors.orange;
    if (value > 180) return Colors.red;
    return Colors.green;
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
}
