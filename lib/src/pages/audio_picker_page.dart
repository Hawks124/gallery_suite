import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../gallery_suite.dart';
import '../../gallery_suite.dart' as my_models;

class AudioPickerPage extends StatefulWidget {
  final PickerConfig config;

  const AudioPickerPage({super.key, required this.config});

  @override
  State<AudioPickerPage> createState() => _AudioPickerPageState();
}

class _AudioPickerPageState extends State<AudioPickerPage> {
  final MediaService _service = MediaService();
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];
  AssetEntity? _playingAsset;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _permissionDenied = false;
  int _page = 0;
  static const int _pageSize = 50;

  // Search State
  bool _isSearching = false;
  String _searchQuery = '';
  List<AssetEntity> _searchResults = [];
  bool _isSearchLoading = false;
  Timer? _searchDebounce;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  late PickerTheme _theme;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    _player.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
    _scrollController.addListener(_onScroll);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = widget.config.brightness == Brightness.dark ||
        (widget.config.brightness == null &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    _theme = PickerTheme(isDark, widget.config.themeData);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _isSearchLoading = false;
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _searchQuery = trimmed;
        _isSearchLoading = true;
        _isSearching = true;
      });

      try {
        final albums = await _service.getAlbums(widget.config.requestType);
        if (albums.isNotEmpty) {
          final results = await _service.searchAssets(albums.first, trimmed);
          if (mounted && _searchQuery == trimmed) {
            setState(() {
              _searchResults = results;
              _isSearchLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Search error: $e');
        if (mounted) setState(() => _isSearchLoading = false);
      }
    });
  }

  Future<void> _initialize() async {
    final granted = await _service.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
      }
      return;
    }
    await _loadAssets(reset: true);
  }

  Future<void> _loadAssets({bool reset = false}) async {
    if (reset) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() => reset ? _isLoading = true : _isLoadingMore = true);

    final albums = await _service.getAlbums(widget.config.requestType);
    if (albums.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      return;
    }

    final all = albums.first;
    final assets = await _service.getAssets(
      album: all,
      page: _page,
      pageSize: _pageSize,
    );

    if (!mounted) return;
    setState(() {
      if (reset) {
        _assets = assets;
        _isLoading = false;
      } else {
        _assets.addAll(assets);
        _isLoadingMore = false;
      }
      _hasMore = assets.length >= _pageSize;
      _page++;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadAssets();
      }
    }
  }

  Future<void> _playAsset(AssetEntity asset) async {
    final isSame = _playingAsset?.id == asset.id;

    if (isSame) {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    HapticFeedback.selectionClick();

    File? file;
    try {
      file = await asset.file;
    } catch (_) {}
    if (file == null || !file.existsSync()) return;

    setState(() => _playingAsset = asset);

    try {
      await _player.setAudioSource(AudioSource.uri(Uri.file(file.path)));
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingAsset = null);
    }
  }

  void _selectAsset(AssetEntity asset) {
    HapticFeedback.selectionClick();
    setState(() {
      final idx = _selected.indexWhere((e) => e.id == asset.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        if (_selected.length >= widget.config.maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Vous ne pouvez sélectionner que ${widget.config.maxSelection} élément(s).'),
              backgroundColor: _theme.elevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selected.add(asset);
      }
    });
  }

  Future<void> _handleExit() async {
    final hasChanges = _selected.isNotEmpty;
    if (!hasChanges || widget.config.exitConfirmation == null) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
      return;
    }

    final shouldExit = await widget.config.exitConfirmation!.show(
      context,
      widget.config.primaryColor,
    );

    if (!mounted) return;
    if (shouldExit) {
      Navigator.of(context).pop(null);
    }
  }

  void _onConfirm() {
    if (_selected.isEmpty) return;
    _player.stop();

    final items = _selected.map((asset) {
      return my_models.MediaItem(
        asset: asset,
        useOriginalFile: widget.config.useOriginalFile,
      );
    }).toList();

    Navigator.of(context).pop(items);
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _selected.isNotEmpty;
    final canPop = !hasChanges || widget.config.exitConfirmation == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _theme.overlayStyle,
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final shouldExit = await widget.config.exitConfirmation!.show(
            context,
            widget.config.primaryColor,
          );

          if (!context.mounted) return;
          if (shouldExit) {
            Navigator.of(context).pop(null);
          }
        },
        child: Scaffold(
          backgroundColor: _theme.background,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: _theme.surface,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: TextButton(
                    onPressed: _handleExit,
                    style: TextButton.styleFrom(
                      foregroundColor: _theme.secondaryText,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      widget.config.textDelegate.cancel,
                      style: TextStyle(
                          color: _theme.secondaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
                Text(
                  widget.config.textDelegate.audio,
                  style: TextStyle(
                    color: _theme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                Positioned(
                  right: 4,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                          parent: anim, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _selected.isNotEmpty
                        ? SendButton(
                            key: const ValueKey('send'),
                            label: widget.config.textDelegate.confirm,
                            count: widget.config.maxSelection > 1
                                ? _selected.length
                                : null,
                            color: widget.config.primaryColor,
                            onTap: _onConfirm,
                          )
                        : const SizedBox(key: ValueKey('empty'), width: 80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) return _buildPermissionDenied();

    return Column(
      children: [
        Container(height: 0.5, color: _theme.separator),
        _buildInlineSearchBar(),
        Expanded(child: _buildList()),
        if (_playingAsset != null) _buildMiniPlayer(),
      ],
    );
  }

  Widget _buildInlineSearchBar() {
    return Container(
      color: _theme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: _theme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style: TextStyle(color: _theme.primaryText, fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom...',
            hintStyle:
                TextStyle(color: _theme.secondaryText.withValues(alpha: 0.5)),
            prefixIcon:
                Icon(Icons.search, color: _theme.secondaryText, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel,
                        color: _theme.secondaryText, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      _searchFocus.unfocus();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: _theme.elevated),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 9.5),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading || (_isSearching && _isSearchLoading)) {
      return Center(
        child: CircularProgressIndicator(
            color: widget.config.primaryColor, strokeWidth: 2),
      );
    }

    if (_isSearching && _searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: _theme.secondaryText),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$_searchQuery"',
              style: TextStyle(
                  color: _theme.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final displayAssets =
        (_isSearching && _searchQuery.isNotEmpty) ? _searchResults : _assets;

    if (!_isSearching && _assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music_outlined,
                size: 56, color: _theme.secondaryText),
            const SizedBox(height: 16),
            Text(
              widget.config.textDelegate.noMediaFound,
              style: TextStyle(
                  color: _theme.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final bool isLoadingMoreAssets = _isSearching ? false : _isLoadingMore;

    return ListView.separated(
      controller: _scrollController,
      itemCount: displayAssets.length + (isLoadingMoreAssets ? 1 : 0),
      separatorBuilder: (_, __) =>
          Divider(height: 0.5, color: _theme.divider, indent: 82),
      itemBuilder: (_, i) {
        if (i >= displayAssets.length) {
          return SizedBox(
            height: 72,
            child: Center(
              child: CircularProgressIndicator(
                  color: widget.config.primaryColor, strokeWidth: 2),
            ),
          );
        }
        final asset = displayAssets[i];
        return AudioTile(
          asset: asset,
          isPlaying: _playingAsset?.id == asset.id && _isPlaying,
          isCurrentTrack: _playingAsset?.id == asset.id,
          isSelected: _selected.any((e) => e.id == asset.id),
          primaryColor: widget.config.primaryColor,
          theme: _theme,
          service: _service,
          onPlay: () => _playAsset(asset),
          onSelect: () => _selectAsset(asset),
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    final asset = _playingAsset;
    if (asset == null) return const SizedBox.shrink();

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: _theme.surface.withValues(alpha: 0.75),
            border:
                Border(top: BorderSide(color: _theme.separator, width: 0.5)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Animated music icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.config.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.music_note_rounded,
                      color: widget.config.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cleanTitle(asset.title ?? 'Audio'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _theme.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(_position)} / ${_fmt(_duration)}',
                    style: TextStyle(color: _theme.secondaryText, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _playAsset(asset),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.config.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _player.stop();
                      setState(() {
                        _playingAsset = null;
                        _position = Duration.zero;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _theme.elevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          color: _theme.secondaryText, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Seek bar
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  activeTrackColor: widget.config.primaryColor,
                  inactiveTrackColor: _theme.elevated,
                  thumbColor: widget.config.primaryColor,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: progress.toDouble(),
                  onChanged: (v) {
                    final ms = (v * _duration.inMilliseconds).round();
                    _player.seek(Duration(milliseconds: ms));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(color: _theme.elevated, shape: BoxShape.circle),
              child: Icon(Icons.music_off_outlined,
                  size: 38, color: _theme.secondaryText),
            ),
            const SizedBox(height: 24),
            Text(
              'Accès refusé',
              style: TextStyle(
                color: _theme.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Autorisez l\'accès dans les réglages pour continuer.',
              style: TextStyle(
                  color: _theme.secondaryText, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => PhotoManager.openSetting(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.config.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Ouvrir les réglages',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(
            RegExp(r'\.(mp3|wav|aac|flac|ogg|m4a|opus)$', caseSensitive: false),
            '')
        .trim();
  }
}
