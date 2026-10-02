import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/stream/stream_cubit.dart';
import '../screens/player_screen.dart';
import 'add_stream_sheet.dart';

/// Records the view and opens the player.
void openStream(BuildContext context, StreamLink stream) {
  context.read<StreamCubit>().recordPlay(stream);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PlayerScreen(stream: stream)),
  );
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<void> deleteStreamWithUndo(BuildContext context, StreamLink stream) async {
  final cubit = context.read<StreamCubit>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف الرابط؟'),
      content: Text('سيتم حذف "${stream.title}" من قائمتك.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await cubit.removeStream(stream.id);
  if (!context.mounted) return;
  showSnack(
    context,
    'تم حذف "${stream.title}"',
    action: SnackBarAction(
      label: 'تراجع',
      onPressed: () => cubit.restoreStream(stream),
    ),
  );
}

/// Bottom sheet with every action available for a stream.
void showStreamActions(BuildContext context, StreamLink stream) {
  final cubit = context.read<StreamCubit>();
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      void close() => Navigator.pop(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                stream.title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_fill, color: AppColors.primary),
              title: const Text('تشغيل'),
              onTap: () {
                close();
                openStream(context, stream);
              },
            ),
            ListTile(
              leading: Icon(
                stream.isFavorite ? Icons.star : Icons.star_border,
                color: AppColors.favorite,
              ),
              title: Text(
                stream.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              ),
              onTap: () {
                close();
                cubit.toggleFavorite(stream);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('نسخ الرابط'),
              onTap: () {
                close();
                Clipboard.setData(ClipboardData(text: stream.url));
                showSnack(context, 'تم نسخ الرابط');
              },
            ),
            if (!stream.isRemote) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('تعديل'),
                onTap: () {
                  close();
                  showAddStreamSheet(context, initial: stream);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  'حذف',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  close();
                  deleteStreamWithUndo(context, stream);
                },
              ),
            ] else
              const ListTile(
                leading: Icon(Icons.cloud_done_outlined),
                title: Text('رابط من السيرفر'),
                subtitle: Text('يتم تحديثه تلقائياً ولا يمكن تعديله'),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}
