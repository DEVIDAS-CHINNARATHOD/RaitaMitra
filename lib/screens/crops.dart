import '../data/crop_names.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../state.dart';
import '../data/models.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'markets.dart';

List<Price> cropPrices(AppState s, FarmCrop crop) => s.prices
    .where(
      (p) =>
          p.name.toLowerCase() == crop.name.toLowerCase() &&
          p.marketId == (crop.marketId ?? s.marketId) &&
          (crop.variety.isEmpty ||
              p.variety.toLowerCase() == crop.variety.toLowerCase()),
    )
    .toList();

class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(state.t('My Crops', 'ನನ್ನ ಬೆಳೆಗಳು')),
      actions: [
        IconButton(
          tooltip: 'Add crop',
          onPressed: () => openPage(context, CropFormScreen(state: state)),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: PageBody(
      children: [
        Text(
          state.t('Your crops', 'ನಿಮ್ಮ ಎಲ್ಲಾ ಬೆಳೆಗಳು\nಒಂದೇ ಸ್ಥಳದಲ್ಲಿ.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          state.t(
            'Keep track of planting, harvest and market prices.',
            'ಬಿತ್ತನೆ, ಕೊಯ್ಲು ಮತ್ತು ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳನ್ನು ಗಮನಿಸಿ.',
          ),
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 22),
        if (!state.signedIn) ...[
          const Notice(
            'These crops are saved on this device. Account sync becomes available when you sign in.',
          ),
          const SizedBox(height: 18),
        ],
        if (state.crops.isEmpty)
          EmptyPanel(
            icon: Icons.grass_outlined,
            title: state.t(
              'What are you growing?',
              'ನೀವು ಯಾವ ಬೆಳೆ ಬೆಳೆಯುತ್ತಿದ್ದೀರಿ?',
            ),
            body: state.t(
              'Add your first crop with its planting date. Quantity and harvest date can be added later.',
              'ನಿಮ್ಮ ಬೆಳೆ ಮತ್ತು ಬಿತ್ತನೆ ದಿನಾಂಕ ಸೇರಿಸಿ.',
            ),
            action: state.t('Add a crop', 'ಬೆಳೆ ಸೇರಿಸಿ'),
            onAction: () => openPage(context, CropFormScreen(state: state)),
          )
        else
          ...state.crops.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CropCard(state: state, crop: c),
            ),
          ),
        if (state.crops.isNotEmpty) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => openPage(context, CropFormScreen(state: state)),
            icon: const Icon(Icons.add, size: 20),
            label: Text(state.t('Add another crop', 'ಮತ್ತೊಂದು ಬೆಳೆ ಸೇರಿಸಿ')),
          ),
        ],
      ],
    ),
  );
}

class CropCard extends StatelessWidget {
  const CropCard({super.key, required this.state, required this.crop});
  final AppState state;
  final FarmCrop crop;
  @override
  Widget build(BuildContext context) {
    final matches = cropPrices(state, crop);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPage(context, CropScreen(state: state, id: crop.id)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: paleBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.grass_outlined,
                      color: accentBlue,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cropLabel(crop.name),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          crop.quantity == null
                              ? 'Quantity not set'
                              : '${crop.quantity} quintals',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: muted, size: 20),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                crop.harvest == null
                    ? 'Harvest date not set'
                    : 'Expected harvest · ${dayLabel(crop.harvest!)}',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      matches.length == 1
                          ? 'Latest report: ${money(matches.first.modal)} / q'
                          : matches.isEmpty
                          ? 'No matching price report'
                          : '${matches.length} matching price reports',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Forecast not available yet',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CropFormScreen extends StatefulWidget {
  const CropFormScreen({super.key, required this.state, this.crop});
  final AppState state;
  final FarmCrop? crop;
  @override
  State<CropFormScreen> createState() => _CropFormScreenState();
}

class _CropFormScreenState extends State<CropFormScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, variety, quantity, notes;
  late DateTime planted;
  DateTime? harvest;
  String? market;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final c = widget.crop;
    name = TextEditingController(text: c?.name ?? '');
    variety = TextEditingController(text: c?.variety ?? '');
    quantity = TextEditingController(text: c?.quantity?.toString() ?? '');
    notes = TextEditingController(text: c?.notes ?? '');
    planted = c?.planted ?? DateTime.now();
    harvest = c?.harvest;
    market = c?.marketId ?? widget.state.marketId;
  }

  @override
  void dispose() {
    for (final c in [name, variety, quantity, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(bool isHarvest) async {
    final value = await showDatePicker(
      context: context,
      initialDate: isHarvest
          ? (harvest ?? planted.add(const Duration(days: 90)))
          : planted,
      firstDate: isHarvest ? planted : DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null && mounted) {
      setState(() {
        if (isHarvest) {
          harvest = value;
        } else {
          planted = value;
          if (harvest != null && harvest!.isBefore(planted)) harvest = null;
        }
      });
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.state.saveCrop({
        'id': widget.crop?.id ?? const Uuid().v4(),
        'commodity_name': canonicalCrop(name.text, {
          ...cropKannada.keys,
          ...widget.state.prices.map((p) => p.name),
        }),
        'variety': variety.text.trim(),
        'quantity': quantity.text.trim().isEmpty
            ? null
            : double.parse(quantity.text),
        'planting_date': dateOnly(planted),
        'harvest_date': harvest == null ? null : dateOnly(harvest!),
        'market_id': market,
        'notes': notes.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Your crop could not be saved. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final options = ({
      ...cropKannada.keys,
      ...s.prices.map((p) => p.name),
    }).toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.t(widget.crop == null ? 'Add a crop' : 'Edit crop', 'ಬೆಳೆ ಮಾಹಿತಿ'),
        ),
      ),
      body: Form(
        key: form,
        child: PageBody(
          children: [
            Text(
              s.t('Add your crop', 'ನಿಮ್ಮ ಬೆಳೆಯ\nಮಾಹಿತಿ ನೀಡಿ.'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: name.text),
              displayStringForOption: (option) => option,
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                return options.where(
                  (n) => cropLabel(n).toLowerCase().contains(q),
                );
              },
              onSelected: (value) => name.text = value,
              fieldViewBuilder: (context, controller, focus, submit) =>
                  TextFormField(
                    controller: controller,
                    focusNode: focus,
                    onChanged: (value) => name.text = value,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: s.t('Crop name', 'ಬೆಳೆಯ ಹೆಸರು'),
                      hintText: 'Tomato / ಟೊಮೇಟೊ',
                      helperText: s.t(
                        'Type in English or Kannada to find a crop',
                        'ಬೆಳೆ ಹುಡುಕಲು ಕನ್ನಡ ಅಥವಾ ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿ ಬರೆಯಿರಿ',
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a crop name'
                        : null,
                  ),
              optionsViewBuilder: (context, select, matches) => Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width - 40,
                    height: 240,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final option = matches.elementAt(i);
                        return ListTile(
                          title: Text(cropLabel(option)),
                          onTap: () => select(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: variety,
              decoration: InputDecoration(
                labelText: s.t('Variety (optional)', 'ತಳಿ (ಐಚ್ಛಿಕ)'),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: s.t(
                  'Expected quantity (optional)',
                  'ನಿರೀಕ್ಷಿತ ಪ್ರಮಾಣ',
                ),
                suffixText: 'quintals',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                return n == null || !n.isFinite || n <= 0
                    ? 'Enter a quantity greater than zero'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Planting / sowing date'),
                    subtitle: Text(dayLabel(planted)),
                    trailing: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                    ),
                    onTap: () => pickDate(false),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text('Expected harvest date'),
                    subtitle: Text(
                      harvest == null
                          ? 'Optional · set your own estimate'
                          : dayLabel(harvest!),
                    ),
                    trailing: harvest == null
                        ? const Icon(Icons.calendar_today_outlined, size: 20)
                        : IconButton(
                            tooltip: 'Clear harvest date',
                            onPressed: () => setState(() => harvest = null),
                            icon: const Icon(Icons.close, size: 20),
                          ),
                    onTap: () => pickDate(true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: market,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Market to track'),
              items: s.markets
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.name} · ${s.districtName(m.districtId)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => market = v),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            const Notice(
              'Harvest timing is your estimate. Automatic crop-duration estimates and price forecasts will be added when verified data is ready.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : s.t('Save crop', 'ಬೆಳೆ ಉಳಿಸಿ')),
            ),
          ],
        ),
      ),
    );
  }
}

class CropScreen extends StatelessWidget {
  const CropScreen({super.key, required this.state, required this.id});
  final AppState state;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final c = state.crops.where((c) => c.id == id).firstOrNull;
      if (c == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Crop')),
          body: const Center(child: Text('This crop has been removed.')),
        );
      }
      final prices = cropPrices(state, c);
      return Scaffold(
        appBar: AppBar(
          title: Text(cropLabel(c.name)),
          actions: [
            IconButton(
              tooltip: 'Edit crop',
              onPressed: () =>
                  openPage(context, CropFormScreen(state: state, crop: c)),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: PageBody(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.grass_outlined,
                      size: 35,
                      color: accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cropLabel(c.name),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (c.variety.isNotEmpty)
                      Text(c.variety, style: const TextStyle(color: muted)),
                    const SizedBox(height: 20),
                    Text('Planted ${dayLabel(c.planted)}'),
                    const SizedBox(height: 8),
                    Text(
                      c.harvest == null
                          ? 'Harvest estimate not set'
                          : 'Expected harvest ${dayLabel(c.harvest!)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.quantity == null
                          ? 'Quantity not set'
                          : 'Expected quantity ${c.quantity} quintals',
                    ),
                  ],
                ),
              ),
            ),
            const SectionLabel('Your market price'),
            if (prices.isEmpty)
              EmptyPanel(
                icon: Icons.storefront_outlined,
                title: 'No matching report available',
                body:
                    'Refresh the tracked mandi or check the crop and variety spelling.',
                action: 'Refresh market',
                onAction: state.busy ? null : () => state.refresh(c.marketId),
              )
            else
              Card(
                child: Column(
                  children: prices
                      .map(
                        (p) => PriceTile(
                          p,
                          onTap: () => openPage(
                            context,
                            PriceScreen(state: state, price: p),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (prices.length == 1 && c.quantity != null) ...[
              const SizedBox(height: 16),
              Notice(
                'At the reported price: ${money(prices.first.modal * c.quantity!)} for ${c.quantity} quintals. This is gross sales value before costs, based on the report dated ${dayLabel(prices.first.date)}.',
              ),
            ],
            const SectionLabel('Harvest outlook'),
            const EmptyPanel(
              icon: Icons.event_note_outlined,
              title: 'Forecast not available yet',
              body:
                  'Price estimates and selling options will appear when forecasts are available for this crop and market.',
            ),
            if (c.notes.isNotEmpty) ...[
              const SectionLabel('Your notes'),
              Text(c.notes),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove this crop?'),
                    content: Text('Remove ${c.name} from My Crops?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await state.deleteCrop(id);
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      toast(context, 'Could not remove the crop. Try again.');
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove crop'),
            ),
          ],
        ),
      );
    },
  );
}
