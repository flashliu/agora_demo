import 'dart:convert';
import 'dart:io';

import 'package:agora_demo/authpack.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const rtcAppId = 'ad19cdb0ccbd40f99fa3f81839100633';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final RtcEngine _rtcEngine;
  late final RtcEngineEventHandler _rtcEngineEventHandler;

  bool _isReadyPreview = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  initialize() async {
    _rtcEngine = createAgoraRtcEngine();

    await _rtcEngine.initialize(
      const RtcEngineContext(
        appId: rtcAppId,
        logConfig: LogConfig(level: LogLevel.logLevelNone),
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _rtcEngineEventHandler = RtcEngineEventHandler(
      onExtensionStarted: (provider, extension) {
        if (provider == 'FaceUnity' && extension == 'Effect') {
          _initFUExtension();
        }
      },
    );

    _rtcEngine.registerEventHandler(_rtcEngineEventHandler);

    await _rtcEngine.enableExtension(
      provider: "FaceUnity",
      extension: "Effect",
      enable: true,
    );

    await _rtcEngine.enableVideo();
    await _rtcEngine.startPreview();

    setState(() {
      _isReadyPreview = true;
    });
  }

  _initFUExtension() async {
    await _rtcEngine.setExtensionProperty(
      provider: 'FaceUnity',
      extension: 'Effect',
      key: 'fuSetup',
      value: jsonEncode({'authdata': gAuthPackage}),
    );

    final aiBeautyProcessorPath =
        await _copyAsset('Resource/graphics/face_beautification.bundle');
    await _rtcEngine.setExtensionProperty(
        provider: 'FaceUnity',
        extension: 'Effect',
        key: 'fuCreateItemFromPackage',
        value: jsonEncode({'data': aiBeautyProcessorPath}));
  }

  Future<String> _copyAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    Directory appDocDir = await getApplicationDocumentsDirectory();

    final dirname = path.dirname(assetPath);

    Directory dstDir = Directory(path.join(appDocDir.path, dirname));
    if (!(await dstDir.exists())) {
      await dstDir.create(recursive: true);
    }

    String p = path.join(appDocDir.path, path.basename(assetPath));
    final file = File(p);
    if (!(await file.exists())) {
      await file.create();
      await file.writeAsBytes(bytes);
    }

    return file.absolute.path;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReadyPreview) {
      return Container();
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Demo Home Page'),
        ),
        body: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _rtcEngine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),
      ),
    );
  }
}
