import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/travel_theme.dart';
import '../../../core/ui/page_components.dart';
import '../../books/presentation/book_view_model.dart';

class PermitsScreen extends StatelessWidget {
  const PermitsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final model = context.watch<BookViewModel>();
    return TravelPage(
      children: [
        const PageHeading(
          number: '11',
          title: '办证与路线分流',
          description: '保留2026年原路书的办理顺序和参考图分支。当前政策、窗口受理范围和有效期需重新向办理方确认。',
        ),
        const Notice(
          '原路书计划办理日喀则＋阿里范围。任一步成功后，核对实际获准范围和有效期；路线选择以实际办理结果为准。',
          warning: true,
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...model.book.permitSteps.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: TravelTheme.forest.withValues(
                          alpha: .1,
                        ),
                        child: Text(
                          '${entry.$1 + 1}',
                          style: const TextStyle(color: TravelTheme.forest),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.$2.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: TravelTheme.muted,
                              ),
                            ),
                            Text(
                              entry.$2.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(entry.$2.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Notice(
          'A：拉萨办理成功，按南线主方案。B：原图中的日喀则方向统一暂停预案，按北线分支。C：优先去日喀则办理，结果待定时后续路线留空；成功后汇入 A，失败后汇入 B。',
        ),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('此前另提的备选', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...model.book.notes
                  .skip(3)
                  .map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Text(note),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
