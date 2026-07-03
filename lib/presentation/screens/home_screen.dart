import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/stream/stream_cubit.dart';
import '../blocs/stream/stream_state.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  StreamType _selectedType = StreamType.koraMatch;
  int _bottomNavIndex =
      0; // 0: Home, 1: Schedule, 2: Channels, 3: Favorites, 4: Profile
  int _activeCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
    context.read<StreamCubit>().loadStreams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Auto-detect team logo
  String _getTeamLogo(String title) {
    final name = title.toLowerCase();
    if (name.contains('liverpool') || name.contains('ليفربول')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/1200px-Liverpool_FC.svg.png';
    }
    if (name.contains('manchester city') ||
        name.contains('man city') ||
        name.contains('سيتي') ||
        name.contains('مانشستر سيتي')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/e/eb/Manchester_City_FC_badge.svg/1200px-Manchester_City_FC_badge.svg.png';
    }
    if (name.contains('chelsea') || name.contains('تشيلسي')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/c/cc/Chelsea_FC.svg/1200px-Chelsea_FC.svg.png';
    }
    if (name.contains('editorial') ||
        name.contains('arsenal') ||
        name.contains('أرسنال') ||
        name.contains('ارسنال')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Arsenal_FC.svg/1200px-Arsenal_FC.svg.png';
    }
    if (name.contains('real madrid') ||
        name.contains('ريال مدريد') ||
        name.contains('مدريد')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/5/56/Real_Madrid_CF.svg/1200px-Real_Madrid_CF.svg.png';
    }
    if (name.contains('barcelona') || name.contains('برشلونة')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/1200px-FC_Barcelona_%28crest%29.svg.png';
    }
    if (name.contains('milan') || name.contains('ميلان')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/AC_Milan_logo.svg/1200px-AC_Milan_logo.svg.png';
    }
    if (name.contains('inter') ||
        name.contains('إنتر') ||
        name.contains('انتر')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/FC_Internazionale_Milano_2021_logo.svg/1200px-FC_Internazionale_Milano_2021_logo.svg.png';
    }
    if (name.contains('psg') ||
        name.contains('باريس') ||
        name.contains('germain')) {
      return 'https://upload.wikimedia.org/wikipedia/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/1200px-Paris_Saint-Germain_F.C..svg.png';
    }
    if (name.contains('bayern') || name.contains('بايرن')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg/1200px-FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg.png';
    }
    return ''; // empty fallback
  }

  // Auto-detect channel logo
  String _getChannelLogo(String title) {
    final name = title.toLowerCase();
    if (name.contains('bein') ||
        name.contains('بي ان') ||
        name.contains('بين')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/BeIN_Sports_logo.svg/1200px-BeIN_Sports_logo.svg.png';
    }
    if (name.contains('ssc') || name.contains('اس اس سي')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/SSC_Logo.svg/1200px-SSC_Logo.svg.png';
    }
    if (name.contains('abu dhabi') ||
        name.contains('أبوظبي') ||
        name.contains('ابوظبي')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Abu_Dhabi_Media_logo.svg/1200px-Abu_Dhabi_Media_logo.svg.png';
    }
    if (name.contains('ontime') || name.contains('اون تايم')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/MBC_Group_Logo.svg/1200px-MBC_Group_Logo.svg.png'; // MBC fallback for ontime logo
    }
    if (name.contains('mbc') || name.contains('ام بي سي')) {
      return 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/MBC_Group_Logo.svg/1200px-MBC_Group_Logo.svg.png';
    }
    return '';
  }

  // Quick Action: Change filters based on bottom navigation tabs
  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 0) {
      context.read<StreamCubit>().changeFilter(FilterOption.all);
    } else if (index == 1) {
      context.read<StreamCubit>().changeFilter(FilterOption.koraMatches);
    } else if (index == 2) {
      context.read<StreamCubit>().changeFilter(FilterOption.tvChannels);
    } else if (index == 3) {
      context.read<StreamCubit>().changeFilter(FilterOption.favorites);
    }
  }

  void _showAddStreamBottomSheet(BuildContext context) {
    _titleController.clear();
    _urlController.clear();
    _selectedType = StreamType.koraMatch;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (statefulContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(statefulContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundLightDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.cardBorder, width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'إضافة رابط بث / قناة تلفزيونية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'العنوان / الاسم',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.cardFill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'رابط البث (URL)',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.cardFill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedType = StreamType.koraMatch;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _selectedType == StreamType.koraMatch
                                    ? AppColors.liveGradient
                                    : null,
                                color: _selectedType == StreamType.koraMatch
                                    ? null
                                    : AppColors.cardFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == StreamType.koraMatch
                                      ? AppColors.neonGreen
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.sports_soccer,
                                    color: _selectedType == StreamType.koraMatch
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'مباراة مباشرة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _selectedType == StreamType.koraMatch
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                _selectedType = StreamType.tvChannel;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: _selectedType == StreamType.tvChannel
                                    ? AppColors.accentGradient
                                    : null,
                                color: _selectedType == StreamType.tvChannel
                                    ? null
                                    : AppColors.cardFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == StreamType.tvChannel
                                      ? AppColors.neonCyan
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tv,
                                    color: _selectedType == StreamType.tvChannel
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'قناة تلفزيونية',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _selectedType == StreamType.tvChannel
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      
                      onPressed: () {
                        final title = _titleController.text.trim();
                        final url = _urlController.text.trim();

                        if (title.isEmpty) return;
                        if (url.isEmpty || !Uri.parse(url).isAbsolute) return;

                        context.read<StreamCubit>().addNewStream(
                          title,
                          url,
                          _selectedType,
                        );
                        Navigator.pop(context);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          height: 54,
                          child: const Text(
                            'حفظ الرابط',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLightDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'البحث عن قناة أو مباراة',
            style: TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.right,
          ),
          content: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (val) {
              context.read<StreamCubit>().searchStreams(val);
            },
            decoration: InputDecoration(
              hintText: 'اكتب اسم المباراة أو القناة...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardFill,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _searchController.clear();
                context.read<StreamCubit>().searchStreams('');
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'بحث',
                style: TextStyle(color: AppColors.neonCyan),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<StreamCubit, StreamState>(
          builder: (context, streamState) {
            List<StreamLink> matches = [];
            List<StreamLink> channels = [];
            List<StreamLink> todayStreams = [];

            if (streamState is StreamLoaded) {
              matches = streamState.allStreams
                  .where((s) => s.type == StreamType.koraMatch)
                  .toList();
              channels = streamState.allStreams
                  .where((s) => s.type == StreamType.tvChannel)
                  .toList();
              todayStreams = streamState.filteredStreams;
            }

            return Column(
              children: [
                // 1. App Bar
                _buildAppBar(context),

                // 2. Main Content Scrollable View
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => context.read<StreamCubit>().loadStreams(),
                    color: AppColors.neonCyan,
                    backgroundColor: AppColors.backgroundLightDark,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3. Featured Hero Match Carousel
                          _buildHeroCarousel(matches),

                          // 4. Live Matches Horizontal Section
                          _buildLiveMatchesSection(matches),

                          // 5. TV Channels Horizontal Section
                          _buildTvChannelsSection(channels),

                          // 6. Today's Matches Vertical Section
                          _buildTodayMatchesSection(todayStreams, streamState),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // 7. Bottom Navigation Bar
                _buildBottomNavigation(),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStreamBottomSheet(context),
        backgroundColor: Colors.redAccent,
        mini: true,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 1. App Bar Widget
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger Menu
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () {
              // Show quick settings directly via hamburger menu
              _showSettingsBottomSheet(context);
            },
          ),

          // Center App Logo (Renders like the screenshot)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sport',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'Live',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
    );
  }

  // 2. Settings bottom sheet triggered from Menu
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLightDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final isAdBlock = settingsState is SettingsLoaded
                ? settingsState.settings.adBlockEnabled
                : true;
            final isPopupBlock = settingsState is SettingsLoaded
                ? settingsState.settings.popupBlockEnabled
                : true;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدوات الحماية والإعلانات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text(
                      'حاجب الإعلانات (AdBlock)',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: const Text(
                      'منع الإعلانات والنوافذ المنبثقة المزعجة',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: isAdBlock,
                    activeColor: AppColors.neonGreen,
                    onChanged: (val) =>
                        context.read<SettingsCubit>().toggleAdBlock(val),
                  ),
                  SwitchListTile(
                    title: const Text(
                      'منع الصفحات المنبثقة (Popup Blocker)',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: const Text(
                      'منع إعادة التوجيه إلى مواقع إعلانية أخرى',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: isPopupBlock,
                    activeColor: AppColors.neonCyan,
                    onChanged: (val) =>
                        context.read<SettingsCubit>().togglePopupBlock(val),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. Featured Hero Carousel Widget (Liverpool vs Man City style)
  Widget _buildHeroCarousel(List<StreamLink> userMatches) {
    // Dynamic carousel list. We prepopulate a mock highlight card (Liverpool vs Man City) to look like screenshot
    final List<Map<String, dynamic>> items = [
      {
        'isMock': true,
        'title': 'ليفربول VS مانشستر سيتي',
        'subTitle': 'دوري أبطال أوروبا',
        'time': '10:00 PM',
        'badge': 'مباشر الآن',
        'team1': 'ليفربول',
        'team1Logo':
            'https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/1200px-Liverpool_FC.svg.png',
        'team2': 'مانشستر سيتي',
        'team2Logo':
            'https://upload.wikimedia.org/wikipedia/en/thumb/e/eb/Manchester_City_FC_badge.svg/1200px-Manchester_City_FC_badge.svg.png',
        'bgUrl':
            'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop',
      },
    ];

    // Add user's custom matches to the carousel if any exist
    for (final m in userMatches) {
      items.add({
        'isMock': false,
        'stream': m,
        'title': m.title,
        'subTitle': 'مباراة مضافة',
        'time': m.lastViewedAt != null
            ? 'آخر تشغيل: ${_formatTime(m.lastViewedAt!)}'
            : 'جديد',
        'badge': 'بث مباشر',
        'team1': m.title.split('vs').first.trim(),
        'team1Logo': _getTeamLogo(m.title.split('vs').first),
        'team2': m.title.contains('vs') ? m.title.split('vs').last.trim() : '',
        'team2Logo': m.title.contains('vs')
            ? _getTeamLogo(m.title.split('vs').last)
            : '',
        'bgUrl':
            'https://images.unsplash.com/photo-1540747737956-37872574b821?w=800&auto=format&fit=crop',
      });
    }

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: items.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _activeCarouselIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final item = items[index];

                return InkWell(
                  onTap: () {
                    if (item['isMock'] == false) {
                      final stream = item['stream'] as StreamLink;
                      context.read<StreamCubit>().recordPlay(stream);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(stream: stream),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(item['bgUrl'] as String),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.65),
                          BlendMode.srcOver,
                        ),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Card Top Bar (Live dot badge and UCL logo)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.sports_soccer,
                              color: Colors.white70,
                              size: 20,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['badge'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Card Content: VS logos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Team 1 Logo
                            _buildTeamAvatar(
                              item['team1Logo'] as String,
                              item['team1'] as String,
                              size: 50,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            // Team 2 Logo
                            _buildTeamAvatar(
                              item['team2Logo'] as String,
                              item['team2'] as String,
                              size: 50,
                            ),
                          ],
                        ),

                        // Card Footer description
                        Column(
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['subTitle']} • ${item['time']}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Carousel Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final isActive = index == _activeCarouselIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 12 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive ? Colors.red : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 4. Live Matches Horizontal Section
  Widget _buildLiveMatchesSection(List<StreamLink> userMatches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (مباريات مباشرة)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عرض الكل >',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'مباريات مباشرة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.sensors, color: Colors.red, size: 18),
                ],
              ),
            ],
          ),
        ),

        // Horizontal matches list
        SizedBox(
          height: 124,
          child: userMatches.isEmpty
              ? _buildEmptyHorizontalList('أضف مبارياتك لتظهر هنا')
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userMatches.length,
                  itemBuilder: (context, index) {
                    final match = userMatches[index];
                    final t1 = match.title.split('vs').first.trim();
                    final t2 = match.title.contains('vs')
                        ? match.title.split('vs').last.trim()
                        : '';

                    return GestureDetector(
                      onTap: () {
                        context.read<StreamCubit>().recordPlay(match);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(stream: match),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Card live indicator tag
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 6,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'مباشر',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            // Opponent logos & scores
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTeamAvatar(
                                  _getTeamLogo(t1),
                                  t1,
                                  size: 24,
                                ),
                                Text(
                                  match.playCount > 0
                                      ? '${match.playCount} - 0'
                                      : '0 - 0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                _buildTeamAvatar(
                                  _getTeamLogo(t2),
                                  t2,
                                  size: 24,
                                ),
                              ],
                            ),

                            // Opponent text names
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    t2.isNotEmpty ? t2 : 'خصم',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // League label placeholder
                            Text(
                              'الدوري الإسباني',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 5. TV Channels Horizontal Section
  Widget _buildTvChannelsSection(List<StreamLink> userChannels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (القنوات التلفزيونية)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عرض الكل >',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'القنوات التلفزيونية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.tv, color: Colors.purpleAccent, size: 18),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Channels list
        SizedBox(
          height: 110,
          child: userChannels.isEmpty
              ? _buildEmptyHorizontalList('أضف قنواتك المفضلة لتظهر هنا')
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userChannels.length,
                  itemBuilder: (context, index) {
                    final ch = userChannels[index];
                    final logoUrl = _getChannelLogo(ch.title);

                    return GestureDetector(
                      onTap: () {
                        context.read<StreamCubit>().recordPlay(ch);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(stream: ch),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            // Glass Box logo container
                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: AppColors.cardFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Center(
                                child: logoUrl.isNotEmpty
                                    ? Image.network(
                                        logoUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.tv,
                                              color: Colors.purpleAccent,
                                              size: 28,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.tv,
                                        color: Colors.purpleAccent,
                                        size: 28,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Title below
                            Text(
                              ch.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 6. Today's Matches / Filtered List Section
  Widget _buildTodayMatchesSection(
    List<StreamLink> filteredStreams,
    StreamState streamState,
  ) {
    final currentFilter = streamState is StreamLoaded
        ? streamState.currentFilter
        : FilterOption.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (مباريات اليوم)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عرض الكل >',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'مباريات اليوم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.calendar_today,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Categories Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: FilterOption.values.map((option) {
              String label = '';
              IconData icon = Icons.all_out;
              Color activeColor = Colors.red;

              switch (option) {
                case FilterOption.all:
                  label = 'الكل';
                  icon = Icons.grid_view;
                  break;
                case FilterOption.koraMatches:
                  label = 'مباشرة الآن';
                  icon = Icons.sports_soccer;
                  break;
                case FilterOption.tvChannels:
                  label = 'قنوات الكأس';
                  icon = Icons.tv;
                  break;
                case FilterOption.favorites:
                  label = 'المفضلة';
                  icon = Icons.star;
                  break;
              }

              final isSelected = option == currentFilter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    context.read<StreamCubit>().changeFilter(option);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : AppColors.cardFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? activeColor : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Vertical List Views
        filteredStreams.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.white.withOpacity(0.2),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لا يوجد روابط متوفرة حالياً في هذا القسم',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredStreams.length,
                itemBuilder: (context, index) {
                  final stream = filteredStreams[index];
                  final isMatch = stream.type == StreamType.koraMatch;
                  final t1 = stream.title.split('vs').first.trim();
                  final t2 = stream.title.contains('vs')
                      ? stream.title.split('vs').last.trim()
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: InkWell(
                      onTap: () {
                        context.read<StreamCubit>().recordPlay(stream);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(stream: stream),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          // Bookmark Star (Favorite toggle)
                          GestureDetector(
                            onTap: () {
                              context.read<StreamCubit>().toggleFavorite(
                                stream,
                              );
                            },
                            child: Icon(
                              stream.isFavorite
                                  ? Icons.star
                                  : Icons.star_border,
                              color: stream.isFavorite
                                  ? Colors.amber
                                  : AppColors.textMuted,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Stream Info details
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Match layout (Logo - vs - Logo)
                                if (isMatch) ...[
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          t1,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 6),
                                        _buildTeamAvatar(
                                          _getTeamLogo(t1),
                                          t1,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          '10:00 PM',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                0.5,
                                              ),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: const Text(
                                            'مباشر',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _buildTeamAvatar(
                                          _getTeamLogo(t2),
                                          t2,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          t2.isNotEmpty ? t2 : 'خصم',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Channel layout
                                  Row(
                                    children: [
                                      _buildTeamAvatar(
                                        _getChannelLogo(stream.title),
                                        stream.title,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        stream.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'بث تلفزيوني',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // League Logo details or delete action
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor:
                                      AppColors.backgroundLightDark,
                                  title: const Text(
                                    'حذف الرابط؟',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  content: Text(
                                    'هل تريد حذف "${stream.title}"؟',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<StreamCubit>()
                                            .removeStream(stream.id);
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'حذف',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // 7. Bottom Navigation Bar (RTL labels matches screenshot)
  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLightDark,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.home, 'الرئيسية'),
          _buildBottomNavItem(1, Icons.calendar_month, 'المباريات'),
          _buildBottomNavItem(2, Icons.tv, 'القنوات'),
          _buildBottomNavItem(3, Icons.star, 'المفضلة'),
          _buildBottomNavItem(4, Icons.person, 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = _bottomNavIndex == index;
    final color = isSelected ? Colors.red : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onBottomNavTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Common widgets helpers
  Widget _buildTeamAvatar(
    String logoUrl,
    String fallbackName, {
    double size = 30,
  }) {
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(fallbackName, size),
      );
    }
    return _buildFallbackAvatar(fallbackName, size);
  }

  Widget _buildFallbackAvatar(String name, double size) {
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyHorizontalList(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
