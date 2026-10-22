import '../data/crop_names.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/models.dart';
import 'theme.dart';

ImageProvider<Object>? profilePhotoProvider(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('data:')) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return MemoryImage(base64Decode(value.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(value);
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.photo, this.radius = 38});
  final String? photo;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: paleBlue,
    backgroundImage: profilePhotoProvider(photo),
    child: photo == null || photo!.isEmpty
        ? Icon(Icons.person_outline, size: radius, color: accentBlue)
        : null,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: paleBlue,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.45, color: ink),
          ),
        ),
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: paleBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentBlue, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class PriceTile extends StatelessWidget {
  const PriceTile(
    this.price, {
    super.key,
    required this.onTap,
    this.showMarket = false,
  });
  final Price price;
  final VoidCallback onTap;
  final bool showMarket;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          CommodityThumbnail(name: price.name, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showMarket ? price.marketName : cropLabel(price.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  showMarket
                      ? [
                          price.variety,
                          price.grade,
                        ].where((s) => s.isNotEmpty).join(' · ')
                      : '${price.variety.isEmpty ? 'Local' : price.variety} · ${price.marketName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        dayLabel(price.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Low ${price.min == null ? '—' : money(price.min!)}  ·  High ${price.max == null ? '—' : money(price.max!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(price.modal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: blueInk,
                ),
              ),
              const Text(
                'per quintal',
                style: TextStyle(fontSize: 10, color: muted),
              ),
              const SizedBox(height: 7),
              if (price.change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: price.change! >= 0
                        ? const Color(0xFFE7F7EF)
                        : const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${price.change! >= 0 ? '▲' : '▼'} ${price.change!.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: price.change! >= 0
                          ? const Color(0xFF169B65)
                          : const Color(0xFFE34A4A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A ready sized slot for the matching local crop photo.
class CommodityThumbnail extends StatelessWidget {
  const CommodityThumbnail({super.key, required this.name, this.size = 54});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileSlug = slug == 'cucumbar_kheera' ? 'cucumber_kheera' : slug;
    final imagePath = 'assets/images/crops/$fileSlug.png';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: name,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.eco_outlined,
          color: const Color(0xFF79A978),
          size: size * .48,
          semanticLabel: '$name image placeholder',
        ),
      ),
    );
  }
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      MaterialPageRoute(
        settings: RouteSettings(name: page.runtimeType.toString()),
        builder: (_) => page,
      ),
    );

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 160),
    children: children,
  );
}
