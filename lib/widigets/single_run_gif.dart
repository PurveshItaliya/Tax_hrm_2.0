import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A high-performance Flutter widget that plays an animated GIF exactly once
/// from start to finish without looping, and freezes on the final completed frame.
class SingleRunGif extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onComplete;

  const SingleRunGif({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onComplete,
  });

  @override
  State<SingleRunGif> createState() => _SingleRunGifState();
}

class _SingleRunGifState extends State<SingleRunGif> {
  final List<ui.Image> _frames = [];
  final List<Duration> _durations = [];
  int _currentIndex = 0;
  Timer? _timer;
  bool _isLoading = true;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _loadAndPlay(widget.assetPath);
  }

  @override
  void didUpdateWidget(covariant SingleRunGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadAndPlay(widget.assetPath);
    }
  }

  static final Map<String, Uint8List> _bytesCache = {};

  Future<void> _loadAndPlay(String path) async {
    _timer?.cancel();
    _clearFrames();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentIndex = 0;
      _loadedPath = path;
    });

    try {
      Uint8List? bytes = _bytesCache[path];
      if (bytes == null) {
        final ByteData data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
        _bytesCache[path] = bytes;
      }
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);

      final List<ui.Image> loadedFrames = [];
      final List<Duration> loadedDurations = [];

      for (int i = 0; i < codec.frameCount; i++) {
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        loadedFrames.add(frameInfo.image);
        final dur = frameInfo.duration > Duration.zero
            ? frameInfo.duration
            : const Duration(milliseconds: 60);
        loadedDurations.add(dur);
      }

      if (!mounted || _loadedPath != path) {
        for (final img in loadedFrames) {
          img.dispose();
        }
        return;
      }

      setState(() {
        _frames.addAll(loadedFrames);
        _durations.addAll(loadedDurations);
        _isLoading = false;
        _currentIndex = 0;
      });

      _scheduleNextFrame();
    } catch (e) {
      debugPrint('[SingleRunGif] Error loading gif $path: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleNextFrame() {
    _timer?.cancel();
    if (!mounted || _frames.isEmpty) return;

    if (_currentIndex >= _frames.length - 1) {
      // Reached the end! Freeze on the final frame, do not loop!
      widget.onComplete?.call();
      return;
    }

    final Duration duration = _durations[_currentIndex];
    _timer = Timer(duration, () {
      if (!mounted) return;
      if (_currentIndex < _frames.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _scheduleNextFrame();
      } else {
        // Freeze on last frame
        widget.onComplete?.call();
      }
    });
  }

  void _clearFrames() {
    for (final frame in _frames) {
      frame.dispose();
    }
    _frames.clear();
    _durations.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clearFrames();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _frames.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
      );
    }

    final safeIndex = _currentIndex.clamp(0, _frames.length - 1);
    return RawImage(
      image: _frames[safeIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
