import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('歩数データ一覧'),
        ),
        body: const StepCounter(),
      ),
    );
  }
}

class StepCounter extends StatefulWidget {
  const StepCounter({super.key});

  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  // 歩数に関する情報を格納する配列
  List<HealthDataPoint> _healthDataList = [];

  // 歩数情報へのアクセス許可状態
  bool _isAuthorized = false;

  // healthパッケージのインスタンス
  final health = HealthFactory();

  // 取得する健康情報のType（歩数）
  final types = [HealthDataType.STEPS];

  @override
  void initState() {
    super.initState();
    _authorizeHealthData();
  }

  /// ActivityRecognitionPermissionの許可リクエスト
  Future<bool> _requestActivityRecognitionPermission() async {
    PermissionStatus status = await Permission.activityRecognition.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      PermissionStatus newStatus =
          await Permission.activityRecognition.request();

      if (newStatus.isGranted) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  /// 健康情報へのアクセス許可リクエスト
  Future<void> _authorizeHealthData() async {
    final isPermissionGranted = await _requestActivityRecognitionPermission();
    _isAuthorized = await health.requestAuthorization(types);

    if (Platform.isAndroid) {
      if (_isAuthorized && isPermissionGranted) {
        _fetchHealthData();
      } else {
        print('権限エラー');
        print(_isAuthorized);
        print(isPermissionGranted);
      }
    } else {
      if (_isAuthorized) {
        _fetchHealthData();
      } else {
        print('権限エラー');
      }
    }
  }

  /// 歩数情報の取得
  Future<void> _fetchHealthData() async {
    print('fetchHandleData');
    DateTime startDate = DateTime.now().subtract(const Duration(days: 31));
    DateTime endDate = DateTime.now();

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      startDate,
      endDate,
      types,
    );

    print(healthData);

    setState(() {
      _healthDataList = healthData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('歩数: ${_healthDataList[index].value}'),
          subtitle: Text(
              '日付: ${_healthDataList[index].dateFrom} - ${_healthDataList[index].dateTo}'),
        );
      },
    );
  }
}
