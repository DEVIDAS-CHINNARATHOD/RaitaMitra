import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../data/models.dart';
import '../state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'onboarding.dart';
import 'email_auth.dart';

const portals = [
  {
    'title': 'Karnataka Agriculture Department',
    'body': 'Official state agriculture information, programmes and contacts.',
    'url': 'https://raitamitra.karnataka.gov.in/',
  },
  {
    'title': 'PM-KISAN',
    'body':
        'Official beneficiary and application information. Check eligibility on the portal.',
    'url': 'https://pmkisan.gov.in/',
  },
  {
    'title': 'Crop insurance · PMFBY',
    'body':
        'Official crop insurance information. Deadlines depend on the notified crop, area and season.',
    'url': 'https://pmfby.gov.in/',
  },
];

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(state.t('Support', 'ಸಹಾಯ'))),
    body: PageBody(
      children: [
        Text(
          state.t('Help for your farm', 'ಉಪಯುಕ್ತ\nಮಾಹಿತಿ.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        const Text(
          'Find official services and understand the reports in your app.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: const StadiumBorder(),
          ),
          onPressed: () => openPage(context, HelpScreen(state: state)),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(state.t('Ask Mitra', 'ಮಿತ್ರನನ್ನು ಕೇಳಿ')),
        ),
        const SectionLabel('Official services'),
        ...portals.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(
                  Icons.account_balance_outlined,
                  color: accentBlue,
                ),
                title: Text(
                  p['title']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(p['body']!),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(context, PortalScreen(portal: p)),
              ),
            ),
          ),
        ),
        const SectionLabel('Your tools'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications_none,
                  color: accentBlue,
                ),
                title: const Text('Price watchlist'),
                subtitle: const Text('Save a target price for a crop'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(context, AlertsScreen(state: state)),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: accentBlue,
                ),
                title: const Text('Ask Mitra'),
                subtitle: const Text('Explore the reports saved in your app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openPage(context, HelpScreen(state: state)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Notice(
          'Insurance deadlines are not loaded yet. Check the official portal for your district, crop and season before applying.',
        ),
      ],
    ),
  );
}

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(state.t('Profile', 'ಪ್ರೊಫೈಲ್')),
        actions: [
          IconButton(
            tooltip: state.t('Edit profile', 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ'),
            onPressed: () =>
                openPage(context, ProfileScreen(state: state, editing: true)),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const SizedBox(height: 8),
          Center(child: ProfileAvatar(photo: state.avatarUrl, radius: 42)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              state.name.isEmpty
                  ? state.t('Farmer profile', 'ರೈತರ ಪ್ರೊಫೈಲ್')
                  : state.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              state.signedIn ? 'Account connected' : 'Saved on this device',
              style: const TextStyle(color: muted),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                if (state.repo.client?.auth.currentUser?.email
                    case final email?)
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: accentBlue,
                    ),
                    title: Text(state.t('Account email', 'ಖಾತೆಯ ಇಮೇಲ್')),
                    subtitle: Text(email),
                  ),
                if (state.repo.client?.auth.currentUser?.email != null)
                  const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: accentBlue,
                  ),
                  title: Text(state.t('Preferred mandi', 'ಆದ್ಯತೆಯ ಮಾರುಕಟ್ಟೆ')),
                  subtitle: Text(
                    state.selectedMarket?.name ??
                        state.t('Not selected', 'ಆಯ್ಕೆ ಮಾಡಿಲ್ಲ'),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16, height: 1),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: accentBlue),
                  title: Text(state.t('District', 'ಜಿಲ್ಲೆ')),
                  subtitle: Text(
                    state.districtId.isEmpty
                        ? '—'
                        : state.districtName(state.districtId),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                openPage(context, ProfileScreen(state: state, editing: true)),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              state.t('Edit profile details', 'ಪ್ರೊಫೈಲ್ ವಿವರಗಳನ್ನು ಬದಲಾಯಿಸಿ'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await state.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(state.t('Log out', 'ಲಾಗ್ ಔಟ್')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => openPage(context, SettingsScreen(state: state)),
            icon: const Icon(Icons.settings_outlined),
            label: Text(
              state.t('Settings and account', 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು ಮತ್ತು ಖಾತೆ'),
            ),
          ),
        ],
      ),
    ),
  );
}

class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key, required this.portal});
  final Map<String, String> portal;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Official service')),
    body: PageBody(
      children: [
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            Icons.account_balance_outlined,
            size: 44,
            color: accentBlue,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          portal['title']!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text(
          portal['body']!,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 24),
        const Notice(
          'Read the official eligibility, documents and current dates before applying. This app does not submit applications.',
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: () async {
            try {
              final ok = await launchUrl(
                Uri.parse(portal['url']!),
                mode: LaunchMode.externalApplication,
              );
              if (!ok && context.mounted) {
                toast(context, 'Could not open the portal.');
              }
            } catch (_) {
              if (context.mounted) toast(context, 'Could not open the portal.');
            }
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open official website'),
        ),
        const SizedBox(height: 18),
        Text(
          portal['url']!,
          style: const TextStyle(fontSize: 12, color: muted),
        ),
      ],
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(state.t('Settings', 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು'))),
      body: PageBody(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: paleBlue,
                    child: Icon(Icons.person_outline, color: accentBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.name.isEmpty ? 'Raitha Mitra user' : state.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          state.signedIn
                              ? 'Account connected'
                              : 'Exploring on this device',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('District and preferred mandi'),
                  subtitle: Text(
                    state.selectedMarket?.name ?? 'Choose a market',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openPage(
                    context,
                    ProfileScreen(state: state, editing: true),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text('Language / ಭಾಷೆ'),
                  trailing: DropdownButton<String>(
                    value: state.language,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
                    ],
                    onChanged: (v) => state.setLanguage(v!),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reload saved market data'),
                  subtitle: const Text('Your crops are kept'),
                  onTap: () async {
                    try {
                      await state.repo.clearMarketCache();
                      await state.loadPrices(force: true);
                      if (context.mounted) {
                        toast(context, 'Market data reloaded.');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        toast(context, 'Could not reload market data.');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (!state.signedIn)
            FilledButton.icon(
              onPressed: () async {
                try {
                  await state.signIn();
                } catch (error) {
                  if (context.mounted) {
                    toast(context, 'Could not start Google sign-in: $error');
                  }
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          if (!state.signedIn)
            OutlinedButton.icon(
              onPressed: () => openPage(context, EmailAuthScreen(state: state)),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Sign in or register with email'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await state.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: Text(state.signedIn ? 'Sign out' : 'Return to welcome'),
          ),
          const SizedBox(height: 28),
          const Text(
            'Raitha Mitra · 1.0\nFarmer market information for Karnataka.\nAn independent student project.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.8),
          ),
        ],
      ),
    ),
  );
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.state});
  final AppState state;
  Future<void> add(BuildContext context) async {
    final name = TextEditingController(), amount = TextEditingController();
    final form = GlobalKey<FormState>();
    final result = await showDialog<Json>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Watch a price'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Commodity'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a crop' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target ₹ / quintal',
                ),
                validator: (v) {
                  final x = double.tryParse(v ?? '');
                  return x == null || !x.isFinite || x <= 0
                      ? 'Enter a positive price'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, {
                  'id': const Uuid().v4(),
                  'commodity_name': name.text.trim(),
                  'threshold': double.parse(amount.text),
                  'market_id': state.marketId,
                  'enabled': true,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Dialog controllers are disposed after the route's exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    amount.dispose();
    if (result != null) {
      try {
        await state.saveAlert(result);
      } catch (_) {
        if (context.mounted) {
          toast(context, 'Could not save this watch. Please retry.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Price watchlist'),
        actions: [
          IconButton(
            tooltip: 'Add price watch',
            onPressed: () => add(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const Notice(
            'Targets are checked against available recent reports when you open the app. Background push notifications are not enabled.',
          ),
          const SizedBox(height: 20),
          if (state.alerts.isEmpty)
            EmptyPanel(
              icon: Icons.notifications_none,
              title: 'Keep an eye on a price',
              body: 'Save a target for a commodity at your preferred mandi.',
              action: 'Add a price watch',
              onAction: () => add(context),
            ),
          ...state.alerts.map((a) {
            final matches = state.prices.where(
              (p) =>
                  p.name.toLowerCase() ==
                      a['commodity_name'].toString().toLowerCase() &&
                  p.marketId == a['market_id'] &&
                  !p.old,
            );
            final reached = matches.any(
              (p) => p.modal >= number(a['threshold'])!,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    reached
                        ? Icons.check_circle_outline
                        : Icons.notifications_none,
                    color: accentBlue,
                  ),
                  title: Text(
                    '${a['commodity_name']} · ${money(number(a['threshold'])!)}',
                  ),
                  subtitle: Text(
                    reached
                        ? 'A recent report meets this target'
                        : matches.isEmpty
                        ? 'No matching recent report'
                        : 'Target not reached in saved reports',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove watch',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () async {
                      try {
                        await state.deleteAlert(a['id']);
                      } catch (_) {
                        if (context.mounted) {
                          toast(context, 'Could not remove this watch.');
                        }
                      }
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, required this.state});
  final AppState state;
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final input = TextEditingController();
  final messages = <Map<String, String>>[];
  @override
  void dispose() {
    scroll.dispose();
    input.dispose();
    super.dispose();
  }

  bool sending = false;
  final scroll = ScrollController();

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || sending) return;
    final client = widget.state.repo.client;
    if (client?.auth.currentUser == null) {
      toast(context, 'Sign in to use Ask Mitra.');
      return;
    }
    final history = messages
        .expand(
          (m) => [
            {'role': 'user', 'content': m['question']!},
            if (m['error'] != 'true')
              {'role': 'assistant', 'content': m['answer']!},
          ],
        )
        .toList();
    setState(() {
      sending = true;
      messages.add({'question': text, 'answer': ''});
      input.clear();
    });
    try {
      final result = await client!.functions
          .invoke(
            'ask-mitra',
            body: {
              'question': text,
              'language': widget.state.language,
              'market_id': widget.state.marketId,
              'history': history.length > 10
                  ? history.sublist(history.length - 10)
                  : history,
            },
          )
          .timeout(const Duration(seconds: 40));
      if (!mounted) return;
      final answer = result.data?['answer'];
      if (answer is! String || answer.isEmpty) throw StateError('No answer');
      setState(() => messages.last['answer'] = answer);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        messages.last['answer'] =
            'Mitra could not connect. Please try again shortly. Saved market prices are still available in Markets.';
        messages.last['error'] = 'true';
      });
    } finally {
      if (mounted) {
        setState(() => sending = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients) {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.state.t('Ask Mitra', 'ಮಿತ್ರನನ್ನು ಕೇಳಿ'))),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(20),
            children: [
              if (!widget.state.signedIn) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in to chat with Mitra'),
                  onPressed: () async {
                    try {
                      await widget.state.signIn();
                    } catch (error) {
                      if (context.mounted) {
                        toast(
                          context,
                          'Could not start Google sign-in: $error',
                        );
                      }
                    }
                  },
                ),
                TextButton.icon(
                  onPressed: () =>
                      openPage(context, EmailAuthScreen(state: widget.state)),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Sign in with email'),
                ),
                const SizedBox(height: 16),
              ],
              const Notice(
                'AI answers may be inaccurate. Questions and recent chat messages are sent to Groq, with relevant saved crop and market details. Do not include private information.',
              ),
              const SizedBox(height: 20),
              Text(
                'A little help for your farm.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          'Show market prices',
                          'How do I plan irrigation?',
                          'ಕನ್ನಡದಲ್ಲಿ ಸಹಾಯ ಮಾಡಿ',
                        ]
                        .map(
                          (q) => ActionChip(
                            label: Text(q),
                            onPressed: sending ? null : () => ask(q),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              ...messages.expand(
                (m) => [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(left: 35, bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        m['question']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        m['answer']!.isEmpty
                            ? 'Mitra is thinking…'
                            : m['answer']!,
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    maxLength: 2000,
                    onSubmitted: ask,
                    decoration: const InputDecoration(
                      hintText: 'Ask in English or Kannada…',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: sending ? null : () => ask(input.text),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
