import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key, required this.state});

  final AppState state;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool registering = false;
  bool busy = false;
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (registering) {
        final response = await widget.state.registerWithEmail(
          email: email.text,
          password: password.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          toast(
            context,
            'Account created. Check your email to confirm, then sign in.',
          );
          setState(() => registering = false);
        } else {
          toast(context, 'Account created.');
        }
      } else {
        await widget.state.signInWithEmail(
          email: email.text,
          password: password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) toast(context, error.message);
    } catch (error) {
      if (mounted) toast(context, 'Could not sign in: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sendResetLink() async {
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      toast(context, 'Enter a valid email address first.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.state.sendPasswordReset(address);
      if (mounted) {
        toast(context, 'Password reset link sent. Check your email.');
      }
    } on AuthException catch (error) {
      if (mounted) toast(context, error.message);
    } catch (error) {
      if (mounted) toast(context, 'Could not send reset link: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const ScenicAppBarBackground(),
      title: Text(registering ? 'Create account' : 'Email sign in'),
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Center(
              child: Image.asset(
                'assets/images/raitha_mitra_logo.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              registering ? 'Create your account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              registering
                  ? 'Register with your email address and a password.'
                  : 'Sign in with the email address linked to your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final candidate = value?.trim() ?? '';
                if (candidate.isEmpty) return 'Enter your email address.';
                if (!RegExp(
                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                ).hasMatch(candidate)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: password,
              obscureText: !showPassword,
              textInputAction: registering
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: registering
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              onFieldSubmitted: (_) {
                if (!registering) submit();
              },
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Use at least 6 characters.';
                }
                return null;
              },
            ),
            if (!registering)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : sendResetLink,
                  child: const Text('Forgot password?'),
                ),
              ),
            if (registering) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPassword,
                obscureText: !showPassword,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    value != password.text ? 'Passwords do not match.' : null,
                onFieldSubmitted: (_) => submit(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(registering ? 'Create account' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      registering = !registering;
                      formKey.currentState?.reset();
                    }),
              child: Text(
                registering
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  bool showPassword = false;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> updatePassword() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.state.updatePassword(password.text);
      if (mounted) toast(context, 'Password updated. You are signed in.');
    } on AuthException catch (error) {
      if (mounted) toast(context, error.message);
    } catch (error) {
      if (mounted) toast(context, 'Could not update password: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const ScenicAppBarBackground(),
      title: const Text('Set a new password'),
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Choose a new password',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter and confirm your new password to finish resetting it.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: password,
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => showPassword = !showPassword),
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').length < 6
                  ? 'Use at least 6 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmation,
              obscureText: !showPassword,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  value != password.text ? 'Passwords do not match.' : null,
              onFieldSubmitted: (_) => updatePassword(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: busy ? null : updatePassword,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
