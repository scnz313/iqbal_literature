import 'package:flutter/material.dart';
import '../widgets/search_result.dart';
import 'package:get/get.dart';

class SearchResultTile extends StatelessWidget {
  final SearchResult result;

  const SearchResultTile({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrdu = result.title.contains(RegExp(r'[\u0600-\u06FF]'));
    final isUrduSubtitle = result.subtitle.contains(RegExp(r'[\u0600-\u06FF]'));

    return LayoutBuilder(builder: (context, constraints) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: InkWell(
          onTap: _navigateToDetails,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with title and icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    _buildTypeIcon(theme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isUrdu
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          // Title with highlight
                          _buildTitle(theme, isUrdu),

                          // Subtitle
                          if (result.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _buildSubtitle(theme, isUrduSubtitle),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTypeIcon(ThemeData theme) {
    IconData iconData;
    Color iconColor;

    switch (result.type) {
      case SearchResultType.book:
        iconData = Icons.book_outlined;
        iconColor = theme.colorScheme.primary;
        break;
      case SearchResultType.poem:
        iconData = Icons.article_outlined;
        iconColor = theme.colorScheme.secondary;
        break;
      case SearchResultType.line:
        iconData = Icons.format_quote_outlined;
        iconColor = theme.colorScheme.tertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, bool isUrdu) {
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: isUrdu ? 'JameelNooriNastaleeq' : null,
      fontSize: isUrdu ? 20 : 16,
    );

    return Text(
      result.title,
      style: titleStyle,
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme, bool isUrdu) {
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.textTheme.bodySmall?.color,
      fontFamily: isUrdu ? 'JameelNooriNastaleeq' : null,
      fontSize: isUrdu ? 16 : 14,
    );

    return Text(
      result.subtitle,
      style: subtitleStyle,
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _navigateToDetails() {
    switch (result.type) {
      case SearchResultType.book:
        Get.toNamed('/book-poems', arguments: {
          'book_id': result.id,
          'book_name': result.title,
          'view_type': 'book_specific'
        });
        break;
      case SearchResultType.poem:
      case SearchResultType.line:
        Get.toNamed('/poem-detail', arguments: {
          'poem_id': result.id,
          'title': result.title,
          'content': result.subtitle,
          'type': result.type.toString(),
        });
        break;
    }
  }
}
