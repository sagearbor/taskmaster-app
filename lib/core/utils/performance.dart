import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Lazy loading mixin for stateful widgets
mixin LazyLoadMixin<T extends StatefulWidget> on State<T> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  
  ScrollController get scrollController => _scrollController;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  
  // Override these in your widget
  Future<void> loadMore();
  double get scrollThreshold => 200.0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_isLoading || !_hasMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll - currentScroll <= scrollThreshold) {
      _loadMoreData();
    }
  }
  
  Future<void> _loadMoreData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void setHasMore(bool value) {
    setState(() {
      _hasMore = value;
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Debouncer for search inputs
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  void cancel() {
    _timer?.cancel();
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// Throttler for high-frequency events
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isReady = true;
  
  Throttler({this.delay = const Duration(milliseconds: 100)});
  
  void run(VoidCallback action) {
    if (!_isReady) return;
    
    _isReady = false;
    action();
    
    _timer = Timer(delay, () {
      _isReady = true;
    });
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

// Image cache manager
class ImageCacheManager {
  static final Map<String, ImageProvider> _cache = {};
  static const int maxCacheSize = 50;
  
  static ImageProvider getCachedImage(String url) {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }
    
    final provider = NetworkImage(url);
    
    if (_cache.length >= maxCacheSize) {
      // Remove oldest entry (simple FIFO)
      _cache.remove(_cache.keys.first);
    }
    
    _cache[url] = provider;
    return provider;
  }
  
  static void clearCache() {
    _cache.clear();
  }
  
  static void precacheImages(BuildContext context, List<String> urls) {
    for (final url in urls) {
      precacheImage(getCachedImage(url), context);
    }
  }
}

// Performance monitoring widget
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  
  const PerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = false,
  });
  
  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final _fpsCounter = FPSCounter();
  double _fps = 60.0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }
  
  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _fps = _fpsCounter.fps;
        _fpsCounter.reset();
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }
  
  void _onFrame(Duration timestamp) {
    if (!widget.enabled) return;
    
    _fpsCounter.tick();
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _fps < 30 
                  ? Colors.red.withOpacity(0.8)
                  : _fps < 50
                      ? Colors.orange.withOpacity(0.8)
                      : Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'FPS: ${_fps.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FPSCounter {
  int _frameCount = 0;
  DateTime _lastReset = DateTime.now();
  
  void tick() {
    _frameCount++;
  }
  
  double get fps {
    final elapsed = DateTime.now().difference(_lastReset).inMilliseconds;
    if (elapsed == 0) return 60.0;
    return (_frameCount / elapsed) * 1000;
  }
  
  void reset() {
    _frameCount = 0;
    _lastReset = DateTime.now();
  }
}

// Widget visibility detector for analytics
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final void Function(bool isVisible)? onVisibilityChanged;
  final String? analyticsName;
  
  const VisibilityDetector({
    super.key,
    required this.child,
    this.onVisibilityChanged,
    this.analyticsName,
  });
  
  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  bool _isVisible = false;
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkVisibility();
        });
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkVisibility();
          });
          return widget.child;
        },
      ),
    );
  }
  
  void _checkVisibility() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null) return;
    
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(renderObject);
    final RevealedOffset offsetToReveal = viewport.getOffsetToReveal(renderObject, 0.0);
    final Size size = renderObject.semanticBounds.size;
    
    final double vpHeight = viewport.paintBounds.height;
    final double scrollOffset = offsetToReveal.offset;
    
    final bool isVisible = scrollOffset < vpHeight && scrollOffset + size.height > 0;
    
    if (isVisible != _isVisible) {
      _isVisible = isVisible;
      widget.onVisibilityChanged?.call(isVisible);
      
      if (isVisible && widget.analyticsName != null) {
        // Log view event
        debugPrint('View: ${widget.analyticsName}');
      }
    }
  }
}

// Memory leak detector
class MemoryLeakDetector {
  static final Map<String, WeakReference<Object>> _trackedObjects = {};
  
  static void track(String id, Object object) {
    _trackedObjects[id] = WeakReference(object);
  }
  
  static void checkLeaks() {
    final leaks = <String>[];
    
    _trackedObjects.forEach((id, ref) {
      if (ref.target != null) {
        leaks.add(id);
      }
    });
    
    if (leaks.isNotEmpty) {
      debugPrint('⚠️ Potential memory leaks detected: ${leaks.join(", ")}');
    }
  }
  
  static void clear() {
    _trackedObjects.clear();
  }
}