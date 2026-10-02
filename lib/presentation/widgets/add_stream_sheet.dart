import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../../data/models/stream_link_model.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/stream/stream_cubit.dart';

/// Opens the add/edit form. Pass [initial] to edit an existing local link.
Future<void> showAddStreamSheet(BuildContext context, {StreamLink? initial}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<StreamCubit>(),
      child: AddStreamSheet(initial: initial),
    ),
  );
}

class AddStreamSheet extends StatefulWidget {
  final StreamLink? initial;

  const AddStreamSheet({super.key, this.initial});

  @override
  State<AddStreamSheet> createState() => _AddStreamSheetState();
}

class _AddStreamSheetState extends State<AddStreamSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _url;
  late final TextEditingController _mirrors;
  late StreamType _type;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _title = TextEditingController(text: s?.title ?? '');
    _url = TextEditingController(text: s?.url ?? '');
    _mirrors = TextEditingController(
      text: s?.mirrors.map((m) => m.url).join('\n') ?? '',
    );
    _type = s?.type ?? StreamType.koraMatch;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _mirrors.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'أدخل رابط البث';
    if (!StreamLinkModel.isValidStreamUrl(v)) {
      return 'الرابط غير صالح، يجب أن يبدأ بـ http:// أو https://';
    }
    return null;
  }

  String? _validateMirrors(String? value) {
    for (final line in _mirrorLines(value ?? '')) {
      if (!StreamLinkModel.isValidStreamUrl(line)) {
        return 'رابط غير صالح: $line';
      }
    }
    return null;
  }

  List<String> _mirrorLines(String text) => text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _url.text = text;
    _formKey.currentState?.validate();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<StreamCubit>();
    final mirrors = [
      for (final (i, url) in _mirrorLines(_mirrors.text).indexed)
        StreamMirror(name: 'سيرفر ${i + 2}', url: url),
    ];
    final initial = widget.initial;
    if (initial == null) {
      cubit.addNewStream(
        _title.text.trim(),
        _url.text.trim(),
        _type,
        mirrors: mirrors,
      );
    } else {
      cubit.editStream(initial.copyWith(
        title: _title.text.trim(),
        url: _url.text.trim(),
        type: _type,
        mirrors: mirrors,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'تعديل الرابط' : 'إضافة مباراة أو قناة',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _TypeSelector(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  hintText: _type == StreamType.koraMatch
                      ? 'مثال: الهلال vs النصر'
                      : 'مثال: beIN Sports 1',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'أدخل العنوان' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'رابط البث',
                  hintText: 'https://',
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: IconButton(
                    tooltip: 'لصق',
                    icon: const Icon(Icons.content_paste),
                    onPressed: _pasteUrl,
                  ),
                ),
                validator: _validateUrl,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _mirrors,
                keyboardType: TextInputType.multiline,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'روابط احتياطية (اختياري)',
                  helperText: 'رابط واحد في كل سطر — يمكنك التبديل بينها أثناء المشاهدة',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: _validateMirrors,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(_isEdit ? Icons.check : Icons.add),
                label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final StreamType value;
  final ValueChanged<StreamType> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StreamType>(
      segments: const [
        ButtonSegment(
          value: StreamType.koraMatch,
          icon: Icon(Icons.sports_soccer),
          label: Text('مباراة'),
        ),
        ButtonSegment(
          value: StreamType.tvChannel,
          icon: Icon(Icons.live_tv),
          label: Text('قناة'),
        ),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.cardFill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textSecondary,
        ),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.cardBorder),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
