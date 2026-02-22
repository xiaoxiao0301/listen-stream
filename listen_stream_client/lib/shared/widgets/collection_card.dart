import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'cover_image.dart';

class CollectionCard extends StatefulWidget {
  final String coverUrl;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onPlay;
  const CollectionCard({super.key, required this.coverUrl, required this.title, required this.subtitle, required this.meta, this.onPlay});

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(DesignTokens.rMed),
          boxShadow: _hover ? DesignTokens.hoverShadow : DesignTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.rMed),
                child: CoverImage(imageUrl: widget.coverUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: DesignTokens.h2(context)),
            const SizedBox(height: 6),
            Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: DesignTokens.body(context).copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8))),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(widget.meta, style: DesignTokens.caption(context)),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _hover ? 1 : 0,
                  child: Row(children: [
                    IconButton(onPressed: widget.onPlay, icon: Icon(Icons.play_arrow)),
                    IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
                  ]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
