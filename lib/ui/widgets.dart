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
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showMarket ? price.marketName : cropLabel(price.name),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        price.variety,
                        price.grade,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(price.modal),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  const Text(
                    'per quintal',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reported ${dayLabel(price.date)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: price.old ? const Color(0xFF956A24) : muted,
                  ),
                ),
              ),
              if (price.change != null)
                Text(
                  '${price.change! >= 0 ? '+' : ''}${price.change!.toStringAsFixed(1)}% vs previous',
                  style: const TextStyle(fontSize: 11, color: ink),
                ),
            ],
          ),
        ],
      ),
    ),
  );
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
