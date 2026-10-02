import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/colors.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import '../widgets/adblock_rules.dart';

class PlayerScreen extends StatefulWidget {
  final StreamLink stream;

  const PlayerScreen({super.key, required this.stream});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 13; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFullscreen = false;
  bool _firstLoadDone = false;
  int _sourceIndex = 0;
  bool? _lastAdBlockState;
  DateTime _lastBlockedNotice = DateTime.fromMillisecondsSinceEpoch(0);
  int _blockedCount = 0;

  List<StreamMirror> get _sources => widget.stream.allSources;
  String get _currentUrl => _sources[_sourceIndex].url;

  @override
  void initState() {
    super.initState();
    final settings = _settings();
    _lastAdBlockState = settings.$1;
    if (settings.$3) WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    _restoreSystemUi();
    super.dispose();
  }

  /// (adBlock, popupBlock, keepScreenOn) read live from the cubit.
  (bool, bool, bool) _settings() {
    final state = context.read<SettingsCubit>().state;
    if (state is SettingsLoaded) {
      final s = state.settings;
      return (s.adBlockEnabled, s.popupBlockEnabled, s.keepScreenOn);
    }
    return (true, true, true);
  }

  // ---------------------------------------------------------------------------
  // Fullscreen
  // ---------------------------------------------------------------------------

  Future<void> _setFullscreen(bool value) async {
    if (_isFullscreen == value) return;
    setState(() => _isFullscreen = value);
    if (value) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _restoreSystemUi();
    }
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
  }

  // ---------------------------------------------------------------------------
  // Sources
  // ---------------------------------------------------------------------------

  void _switchSource(int index) {
    if (index == _sourceIndex) return;
    setState(() {
      _sourceIndex = index;
      _errorMessage = null;
      _isLoading = true;
      _progress = 0;
      _firstLoadDone = false;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_sources[index].url)),
    );
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _firstLoadDone = false;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_currentUrl)),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isFullscreen) _setFullscreen(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<SettingsCubit, SettingsState>(
          listenWhen: (prev, curr) => curr is SettingsLoaded,
          listener: (context, settingsState) {
            if (settingsState is SettingsLoaded) {
              _updateWebViewSettings(
                settingsState.settings.adBlockEnabled,
                settingsState.settings.popupBlockEnabled,
              );
            }
          },
          builder: (context, settingsState) {
            final isAdBlock = settingsState is SettingsLoaded
                ? settingsState.settings.adBlockEnabled
                : true;
            final isPopupBlock = settingsState is SettingsLoaded
                ? settingsState.settings.popupBlockEnabled
                : true;

            return SafeArea(
              top: !_isFullscreen,
              bottom: !_isFullscreen,
              left: !_isFullscreen,
              right: !_isFullscreen,
              child: Column(
                children: [
                  if (!_isFullscreen) _buildHeader(context, isAdBlock),
                  if (!_isFullscreen)
                    SizedBox(
                      height: 2,
                      child: _isLoading && _progress < 1
                          ? LinearProgressIndicator(
                              value: _progress > 0 ? _progress : null,
                            )
                          : null,
                    ),
                  Expanded(child: _buildPlayerArea(isAdBlock, isPopupBlock)),
                  if (!_isFullscreen && _sources.length > 1)
                    _buildSourceSelector(),
                  if (!_isFullscreen)
                    _buildControlDeck(context, isAdBlock, isPopupBlock),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerArea(bool isAdBlock, bool isPopupBlock) {
    return Stack(
      children: [
        Positioned.fill(
          child: InAppWebView(
            key: _webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
            initialUserScripts: UnmodifiableListView<UserScript>([
              UserScript(
                source: """
                  // Block scripted popups and annoying dialogs
                  window.open = function() { return null; };
                  window.alert = function() {};
                  window.confirm = function() { return false; };
                """,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
              ),
            ]),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
              iframeAllowFullscreen: true,
              javaScriptCanOpenWindowsAutomatically: !isPopupBlock,
              // Always true so popups are intercepted in onCreateWindow.
              supportMultipleWindows: true,
              useShouldOverrideUrlLoading: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              contentBlockers: isAdBlock ? getAdBlockerRules() : [],
              userAgent: _userAgent,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onProgressChanged: (controller, progress) {
              if (!mounted) return;
              setState(() {
                _progress = progress / 100;
                if (progress == 100) _isLoading = false;
              });
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) async {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _firstLoadDone = true;
              });
            },
            onReceivedError: (controller, request, error) {
              // Ignore sub-resource errors (blocked ads, cancelled requests).
              if (request.isForMainFrame != true) return;
              if (error.type == WebResourceErrorType.CANCELLED) return;
              if (!mounted) return;
              setState(() {
                _errorMessage = error.description;
                _isLoading = false;
              });
            },
            onEnterFullscreen: (controller) => _setFullscreen(true),
            onExitFullscreen: (controller) => _setFullscreen(false),
            shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
            onCreateWindow: _onCreateWindow,
          ),
        ),
        if (_errorMessage != null) Positioned.fill(child: _buildError()),
        if (_isFullscreen)
          PositionedDirectional(
            top: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'خروج من ملء الشاشة',
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: () => _setFullscreen(false),
              ),
            ),
          ),
      ],
    );
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final requestUrl = navigationAction.request.url;
    if (requestUrl == null) return NavigationActionPolicy.ALLOW;
    final targetUrl = requestUrl.toString();
    final (liveAdBlock, livePopupBlock, _) = _settings();

    // Ads love intent:// and market:// links that try to leave the app.
    if (isExternalSchemeUrl(targetUrl)) {
      if (livePopupBlock) _notifyBlocked();
      return NavigationActionPolicy.CANCEL;
    }

    if (!navigationAction.isForMainFrame) return NavigationActionPolicy.ALLOW;

    if ((liveAdBlock || livePopupBlock) && isAdOrPopupUrl(targetUrl)) {
      _notifyBlocked();
      return NavigationActionPolicy.CANCEL;
    }

    if (livePopupBlock) {
      // Server redirects while the stream is first loading are legitimate
      // (short links, CDN hand-offs) and must not be treated as hijacks.
      final isInitialRedirect =
          !_firstLoadDone && (navigationAction.isRedirect ?? false);
      final currentUri = await controller.getUrl();
      if (!isInitialRedirect &&
          currentUri != null &&
          isRedirectToDifferentDomain(currentUri.toString(), targetUrl)) {
        _notifyBlocked();
        return NavigationActionPolicy.CANCEL;
      }
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    final popupUrl = createWindowAction.request.url?.toString() ?? '';

    // Always silently drop known ad/tracker popups.
    if (popupUrl.isNotEmpty && isAdOrPopupUrl(popupUrl)) return true;

    final (_, livePopupBlock, _) = _settings();
    if (livePopupBlock) {
      _notifyBlocked();
      return true;
    }

    // Popup blocking is off: open same-site popups in the current view only.
    final streamHost = Uri.tryParse(_currentUrl)?.host ?? '';
    final popupHost = Uri.tryParse(popupUrl)?.host ?? '';
    if (streamHost.isNotEmpty &&
        popupHost.isNotEmpty &&
        baseDomain(streamHost) == baseDomain(popupHost)) {
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(popupUrl)));
    }
    return true; // Never open separate windows.
  }

  Widget _buildError() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 56),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'تعذر تشغيل البث',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
              if (_sources.length > 1)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 48),
                  ),
                  onPressed: () =>
                      _switchSource((_sourceIndex + 1) % _sources.length),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('السيرفر التالي'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdBlock) {
    final shieldColor = isAdBlock ? AppColors.success : AppColors.warning;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stream.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isAdBlock ? Icons.shield : Icons.shield_outlined,
                      size: 12,
                      color: shieldColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _isLoading
                          ? 'جاري التحميل ${(_progress * 100).toInt()}%'
                          : (isAdBlock
                              ? (_blockedCount > 0
                                  ? 'الحماية مفعّلة • تم حظر $_blockedCount'
                                  : 'الحماية مفعّلة')
                              : 'الحماية متوقفة'),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isLoading ? AppColors.textSecondary : shieldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ الرابط',
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _currentUrl));
              _showSnack('تم نسخ الرابط');
            },
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            color: AppColors.textSecondary,
            onPressed: _retry,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Container(
      color: AppColors.surface,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _sources.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final selected = i == _sourceIndex;
          return ChoiceChip(
            label: Text(_sources[i].name),
            selected: selected,
            onSelected: (_) => _switchSource(i),
            showCheckmark: false,
            avatar: Icon(
              Icons.dns_rounded,
              size: 14,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.cardFill,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.cardBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildControlDeck(
    BuildContext context,
    bool isAdBlock,
    bool isPopupBlock,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _DeckToggle(
            label: 'الإعلانات',
            icon: Icons.block,
            isActive: isAdBlock,
            onPressed: () =>
                context.read<SettingsCubit>().toggleAdBlock(!isAdBlock),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DeckToggle(
            label: 'النوافذ',
            icon: Icons.open_in_new_off,
            isActive: isPopupBlock,
            onPressed: () =>
                context.read<SettingsCubit>().togglePopupBlock(!isPopupBlock),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'السابق',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () async {
              if (await _webViewController?.canGoBack() ?? false) {
                _webViewController?.goBack();
              }
            },
          ),
          IconButton(
            tooltip: 'التالي',
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onPressed: () async {
              if (await _webViewController?.canGoForward() ?? false) {
                _webViewController?.goForward();
              }
            },
          ),
          IconButton(
            tooltip: 'ملء الشاشة',
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: () => _setFullscreen(true),
          ),
        ],
      ),
    );
  }

  void _updateWebViewSettings(bool isAdBlock, bool isPopupBlock) {
    _webViewController?.setSettings(
      settings: InAppWebViewSettings(
        javaScriptCanOpenWindowsAutomatically: !isPopupBlock,
        supportMultipleWindows: true,
        useShouldOverrideUrlLoading: true,
        contentBlockers: isAdBlock ? getAdBlockerRules() : [],
      ),
    );
    // Content rules only apply to new loads, so reload when they change.
    if (_lastAdBlockState != null && _lastAdBlockState != isAdBlock) {
      _webViewController?.reload();
    }
    _lastAdBlockState = isAdBlock;
  }

  void _notifyBlocked() {
    if (!mounted) return;
    setState(() => _blockedCount++);
    // Throttle so a burst of popups doesn't spam snackbars.
    final now = DateTime.now();
    if (now.difference(_lastBlockedNotice) < const Duration(seconds: 4)) return;
    _lastBlockedNotice = now;
    _showSnack('تم حظر نافذة منبثقة مزعجة', icon: Icons.shield);
  }

  void _showSnack(String message, {IconData? icon}) {
    if (!mounted || _isFullscreen) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _DeckToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  const _DeckToggle({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    final showText = MediaQuery.sizeOf(context).width > 360;
    return Tooltip(
      message: '$label: ${isActive ? 'محظورة' : 'مسموحة'}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.4) : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              if (showText) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
