import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/stream_link_model.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/stream/stream_cubit.dart';
import '../blocs/stream/stream_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stream_actions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverController = TextEditingController();
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsCubit>().state;
    if (state is SettingsLoaded) _serverController.text = state.settings.serverUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    final url = _serverController.text.trim();
    if (url.isNotEmpty && !StreamLinkModel.isValidStreamUrl(url)) {
      setState(() => _serverError = 'رابط غير صالح، يجب أن يبدأ بـ http:// أو https://');
      return;
    }
    setState(() => _serverError = null);
    FocusScope.of(context).unfocus();
    await context.read<SettingsCubit>().setServerUrl(url);
    if (!mounted) return;
    if (url.isEmpty) {
      showSnack(context, 'تم إيقاف المزامنة مع السيرفر');
      return;
    }
    final result = await context.read<StreamCubit>().syncWithServer(url);
    if (!mounted || result == null) return;
    showSnack(context, 'تمت المزامنة: ${result.total} رابط من السيرفر');
  }

  Future<void> _confirmClearHistory() async {
    final cubit = context.read<StreamCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح سجل المشاهدة؟'),
        content: const Text('سيتم تصفير عدد المشاهدات وقائمة "تابع المشاهدة".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await cubit.clearHistory();
    if (mounted) showSnack(context, 'تم مسح سجل المشاهدة');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) => prev is! SettingsLoaded && curr is SettingsLoaded,
      listener: (context, state) {
        if (state is SettingsLoaded) _serverController.text = state.settings.serverUrl;
      },
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = state.settings;
        final settings = context.read<SettingsCubit>();

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const _PageTitle('الإعدادات'),
            const _GroupLabel('سيرفر الروابط', Icons.cloud_sync_outlined),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أدخل رابط ملف JSON على السيرفر ليتم جلب المباريات والقنوات تلقائياً.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _serverController,
                      keyboardType: TextInputType.url,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      onSubmitted: (_) => _saveServer(),
                      decoration: InputDecoration(
                        labelText: 'رابط السيرفر',
                        hintText: 'https://example.com/streams.json',
                        prefixIcon: const Icon(Icons.dns_outlined),
                        errorText: _serverError,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<StreamCubit, StreamState>(
                      builder: (context, streamState) {
                        final syncing =
                            streamState is StreamLoaded && streamState.isSyncing;
                        final lastSync =
                            streamState is StreamLoaded ? streamState.lastSync : null;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: syncing ? null : _saveServer,
                              icon: syncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(syncing ? 'جاري المزامنة...' : 'حفظ ومزامنة الآن'),
                            ),
                            if (lastSync != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'آخر مزامنة ${formatRelative(lastSync.syncedAt)} • '
                                '${lastSync.total} رابط',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            _SwitchTile(
              icon: Icons.autorenew,
              title: 'مزامنة تلقائية',
              subtitle: 'جلب أحدث الروابط عند فتح التطبيق',
              value: s.autoSync,
              onChanged: settings.setAutoSync,
            ),
            const _GroupLabel('الحماية', Icons.shield_outlined),
            _SwitchTile(
              icon: Icons.block,
              title: 'حاجب الإعلانات',
              subtitle: 'حظر الإعلانات وأدوات التتبع داخل صفحات البث',
              value: s.adBlockEnabled,
              onChanged: settings.toggleAdBlock,
            ),
            _SwitchTile(
              icon: Icons.open_in_new_off,
              title: 'منع النوافذ المنبثقة',
              subtitle: 'منع التحويل إلى مواقع إعلانية أخرى',
              value: s.popupBlockEnabled,
              onChanged: settings.togglePopupBlock,
            ),
            const _GroupLabel('التشغيل', Icons.play_circle_outline),
            _SwitchTile(
              icon: Icons.light_mode_outlined,
              title: 'إبقاء الشاشة مضاءة',
              subtitle: 'منع إطفاء الشاشة أثناء المشاهدة',
              value: s.keepScreenOn,
              onChanged: settings.setKeepScreenOn,
            ),
            const _GroupLabel('البيانات', Icons.storage_outlined),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('مسح سجل المشاهدة'),
              onTap: _confirmClearHistory,
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                '${AppConfig.appName} • الإصدار ${AppConfig.appVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String text;
  const _PageTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _GroupLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: text, icon: icon);
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }
}
