import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../search/widgets/search_result.dart';

class SearchResultTile extends StatelessWidget {
  final SearchResult result;

  const SearchResultTile({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(result.typeIcon),
      title: Text(
        result.title,
        style: const TextStyle(
          fontFamily: 'JameelNooriNastaleeq',
          fontSize: 18,
        ),
        textDirection: TextDirection.rtl,
      ),
      subtitle: result.subtitle.isNotEmpty
          ? Text(
              result.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JameelNooriNastaleeq',
                fontSize: 14,
              ),
              textDirection: TextDirection.rtl,
            )
          : null,
      onTap: () {
        switch (result.type) {
          case SearchResultType.book:
            Get.toNamed('/book-poems', arguments: {
              'book_id': int.tryParse(result.id) ?? 0,
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
      },
    );
  }
}
