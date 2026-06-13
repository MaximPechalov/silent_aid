import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _currentFilePath;
  
  AudioService() {
    _recorder = FlutterSoundRecorder();
  }
  
  Future<bool> checkPermission() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  Future<void> initRecorder() async {
    await _recorder?.openRecorder();
  }
  
  Future<void> disposeRecorder() async {
    await _recorder?.closeRecorder();
  }
  
  Future<String?> startRecording() async {
    if (!await checkPermission()) return null;
    
    await initRecorder();
    
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '${appDir.path}/silent_$timestamp.m4a';
    
    await _recorder?.startRecorder(
      toFile: filePath,
      codec: Codec.aacMP4,
    );
    
    _isRecording = true;
    _currentFilePath = filePath;
    return filePath;
  }
  
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    
    final String? path = await _recorder?.stopRecorder();
    _isRecording = false;
    return path;
  }
  
  bool get isRecording => _isRecording;
}