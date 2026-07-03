import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  final GlobalKey _webViewKey = GlobalKey();
  InAppWebViewController? _webViewController;
  double _progress = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: BlocConsumer<SettingsCubit, SettingsState>(
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
            child: Column(
              children: [
                // Top Custom Header Control Deck
                if (!_isFullscreen)
                  _buildHeader(context, isAdBlock, isPopupBlock),

                // Web Player Area
                Expanded(
                  child: Stack(
                    children: [
                      // WebView
                      if (_errorMessage == null)
                        InAppWebView(
                          key: _webViewKey,
                          initialUrlRequest: URLRequest(
                            url: WebUri(widget.stream.url),
                          ),
                          initialUserScripts: UnmodifiableListView<UserScript>([
                            UserScript(
                              source: """
                                // Prevent scripts from opening popup windows
                                window.open = function() { 
                                  console.log('window.open blocked'); 
                                  return null; 
                                };
                                window.alert = function() {}; // Suppress annoying alerts
                              """,
                              injectionTime:
                                  UserScriptInjectionTime.AT_DOCUMENT_START,
                            ),
                          ]),
                          initialSettings: InAppWebViewSettings(
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            iframeAllowFullscreen: true,
                            javaScriptCanOpenWindowsAutomatically:
                                !isPopupBlock,
                            supportMultipleWindows:
                                true, // Always true to intercept popup tabs in onCreateWindow
                            useShouldOverrideUrlLoading:
                                true, // Intercept all navigation actions
                            contentBlockers: isAdBlock
                                ? getAdBlockerRules()
                                : [],
                            userAgent:
                                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                          ),
                          onWebViewCreated: (controller) {
                            _webViewController = controller;
                          },
                          onProgressChanged: (controller, progress) {
                            setState(() {
                              _progress = progress / 100;
                              if (progress == 100) {
                                _isLoading = false;
                              }
                            });
                          },
                          onLoadStart: (controller, url) {
                            setState(() {
                              _isLoading = true;
                            });
                          },
                          onLoadStop: (controller, url) async {
                            setState(() {
                              _isLoading = false;
                            });
                            try {
                              await controller.evaluateJavascript(
                                source: """
                                (function() {
                                  var css = 'html, body { overflow: auto !important; position: static !important; height: auto !important; -webkit-overflow-scrolling: touch !important; }';
                                  var style = document.createElement('style');
                                  style.type = 'text/css';
                                  style.appendChild(document.createTextNode(css));
                                  document.head.appendChild(style);
                                })();
                              """,
                              );
                            } catch (_) {}
                          },
                          onReceivedError: (controller, request, error) {
                            // Don't show error page for minor resource load errors (e.g. cancelled/blocked ad resources)
                            if (request.isForMainFrame == true) {
                              setState(() {
                                _errorMessage = error.description;
                                _isLoading = false;
                              });
                            }
                          },

                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                                // Read LIVE state from cubit (closure values are stale due to GlobalKey)
                                final currentSettings = context
                                    .read<SettingsCubit>()
                                    .state;
                                final liveAdBlock =
                                    currentSettings is SettingsLoaded
                                    ? currentSettings.settings.adBlockEnabled
                                    : true;
                                final livePopupBlock =
                                    currentSettings is SettingsLoaded
                                    ? currentSettings.settings.popupBlockEnabled
                                    : true;

                                final requestUrl = navigationAction.request.url;
                                if (requestUrl != null) {
                                  final targetUrl = requestUrl.toString();
                                  final isMainFrame =
                                      navigationAction.isForMainFrame;

                                  if (isMainFrame) {
                                    if ((liveAdBlock || livePopupBlock) &&
                                        isAdOrPopupUrl(targetUrl)) {
                                      if (livePopupBlock) {
                                        _showPopupBlockedNotification();
                                      }
                                      return NavigationActionPolicy.CANCEL;
                                    }

                                    if (livePopupBlock) {
                                      final currentUri = await controller
                                          .getUrl();
                                      if (currentUri != null) {
                                        final currentUrl = currentUri
                                            .toString();
                                        if (isRedirectToDifferentDomain(
                                          currentUrl,
                                          targetUrl,
                                        )) {
                                          _showPopupBlockedNotification();
                                          return NavigationActionPolicy.CANCEL;
                                        }
                                      }
                                    }
                                  }
                                }
                                return NavigationActionPolicy.ALLOW;
                              },
                          onCreateWindow: (controller, createWindowAction) async {
                            final popupUrl =
                                createWindowAction.request.url?.toString() ??
                                '';

                            // Always silently block known ad/tracker URLs regardless of popup setting
                            if (popupUrl.isNotEmpty &&
                                isAdOrPopupUrl(popupUrl)) {
                              return true; // Silently consume & drop
                            }

                            // Read LIVE state from cubit (closure values are stale due to GlobalKey)
                            final currentSettings = context
                                .read<SettingsCubit>()
                                .state;
                            final livePopupBlock =
                                currentSettings is SettingsLoaded
                                ? currentSettings.settings.popupBlockEnabled
                                : true;

                            if (livePopupBlock) {
                              _showPopupBlockedNotification();
                              return true; // Consume & block popup
                            }

                            // Popup blocking is OFF and URL is not an ad — load in current WebView
                            // but only if it belongs to the same base domain as the stream
                            if (popupUrl.isNotEmpty) {
                              final streamHost =
                                  Uri.tryParse(widget.stream.url)?.host ?? '';
                              final popupHost =
                                  Uri.tryParse(popupUrl)?.host ?? '';
                              if (streamHost.isNotEmpty &&
                                  popupHost.isNotEmpty &&
                                  popupHost.contains(
                                    streamHost
                                        .split('.')
                                        .reversed
                                        .take(2)
                                        .toList()
                                        .reversed
                                        .join('.'),
                                  )) {
                                controller.loadUrl(
                                  urlRequest: URLRequest(url: WebUri(popupUrl)),
                                );
                              }
                            }
                            return true; // Always consume — never open separate windows
                          },
                        ),

                      // Error placeholder
                      if (_errorMessage != null)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.backgroundDark,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.danger,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to Load Player',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = null;
                                      _isLoading = true;
                                    });
                                    _webViewController?.reload();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonCyan,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Centered progress spinner overlay on initial warm-up only
                      if (_isLoading && _webViewController == null)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.backgroundDark,
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.neonCyan,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Floating fullscreen exit button
                      if (_isFullscreen)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isFullscreen = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cardBorder.withOpacity(0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.fullscreen_exit,
                                color: AppColors.neonCyan,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Inline Player Control Deck
                if (!_isFullscreen)
                  _buildControlDeck(context, isAdBlock, isPopupBlock),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdBlock, bool isPopupBlock) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLightDark,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stream.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),
                Row(
                  children: [
                    if (_isLoading && _progress < 1.0) ...[
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.neonCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Loading ${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isAdBlock
                              ? AppColors.neonGreen
                              : AppColors.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isAdBlock)
                              BoxShadow(
                                color: AppColors.neonGreen.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAdBlock ? 'Shield Connected' : 'Shield Disabled',
                        style: TextStyle(
                          fontSize: 10,
                          color: isAdBlock
                              ? AppColors.neonGreen
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
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
        color: AppColors.backgroundLightDark,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ad Block Fast Toggle Button
          _buildDeckButton(
            label: 'AdBlock',
            icon: Icons.block,
            isActive: isAdBlock,
            activeColor: AppColors.neonGreen,
            onPressed: () {
              context.read<SettingsCubit>().toggleAdBlock(!isAdBlock);
            },
          ),

          // Navigation controls
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textPrimary,
                ),
                onPressed: () async {
                  if (await _webViewController?.canGoBack() ?? false) {
                    _webViewController?.goBack();
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textPrimary,
                ),
                onPressed: () async {
                  if (await _webViewController?.canGoForward() ?? false) {
                    _webViewController?.goForward();
                  }
                },
              ),
            ],
          ),

          // Popup Block Fast Toggle Button
          _buildDeckButton(
            label: 'Popup',
            icon: Icons.open_in_new_off,
            isActive: isPopupBlock,
            activeColor: AppColors.neonCyan,
            onPressed: () {
              context.read<SettingsCubit>().togglePopupBlock(!isPopupBlock);
            },
          ),

          // Fullscreen Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.fullscreen,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isFullscreen = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeckButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    final showText = MediaQuery.of(context).size.width > 360;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showText ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppColors.textSecondary,
              size: 18,
            ),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool? _lastAdBlockState;

  void _updateWebViewSettings(bool isAdBlock, bool isPopupBlock) {
    _webViewController?.setSettings(
      settings: InAppWebViewSettings(
        javaScriptCanOpenWindowsAutomatically: !isPopupBlock,
        supportMultipleWindows: true,
        useShouldOverrideUrlLoading: true,
        contentBlockers: isAdBlock ? getAdBlockerRules() : [],
      ),
    );
    // Only reload the page when ad-block content rules change (not popup toggle)
    if (_lastAdBlockState != null && _lastAdBlockState != isAdBlock) {
      _webViewController?.reload();
    }
    _lastAdBlockState = isAdBlock;
  }

  void _showPopupBlockedNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.security, color: AppColors.neonCyan),
            SizedBox(width: 8),
            Text('Intrusive pop-up block active'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
