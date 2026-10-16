import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/product_components.dart';
import 'feedback_client.dart';
import 'support_store.dart';
import 'confirmation_overlay.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.client, this.store});
  final FeedbackClient? client;
  final SupportStore? store;
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final _client = widget.client ?? FeedbackClient();
  late final Future<SupportStore> _store = widget.store == null
      ? SupportStore.open()
      : Future.value(widget.store);
  final _message = TextEditingController();
  String _category = 'other';
  Map<String, dynamic> _details = {}, _attemptDetails = {};
  String? _id, _result;
  bool _includeDetails = false,
      _busy = false,
      _loading = true,
      _uncertain = false;
  Timer? _saveTimer;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final data = (await (await _store).read())['feedbackDraft'];
      if (data is Map && mounted) {
        _message.text = data['message'] as String? ?? '';
        _category = data['category'] as String? ?? 'other';
        _id = data['submissionId'] as String?;
        _uncertain = data['uncertain'] == true;
        _includeDetails = data['includeDetails'] == true;
        _attemptDetails = Map<String, dynamic>.from(
          data['details'] as Map? ?? {},
        );
      }
      final details = await const MethodChannel('dev.almurajaah/support')
          .invokeMapMethod<String, String>('feedbackDetails');
      _details = details ?? {};
    } catch (_) {
      _result = 'Some local support information could not be opened.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> get _draft => {
    'message': _message.text,
    'category': _category,
    'submissionId': _id,
    'uncertain': _uncertain,
    'includeDetails': _includeDetails,
    'details': _uncertain
        ? _attemptDetails
        : _includeDetails
        ? _details
        : <String, dynamic>{},
  };
  Future<void> _save() async => (await _store).update('feedbackDraft', _draft);
  void _changed() {
    _id = null;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        await _save();
      } catch (_) {
        if (mounted) {
          setState(() => _result = 'Draft could not be saved on this device.');
        }
      }
    });
    setState(() => _result = null);
  }

  Future<void> _send() async {
    if (_busy || _confirming) return;
    final message = _message.text.trim();
    if (message.length < 3 || utf8.encode(message).length > 6000) {
      setState(
        () => _result = message.length < 3
            ? 'Write a message of at least 3 characters.'
            : 'Please shorten your message.',
      );
      return;
    }
    _saveTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _result = null;
    });
    _id ??= submissionId();
    if (!_uncertain) _attemptDetails = _includeDetails ? Map.of(_details) : {};
    final wasUncertain = _uncertain;
    _uncertain = true;
    final attempt = _draft;
    try {
      // Save the exact retry ID and reviewed details before the network request.
      final store = await _store;
      await store.update('feedbackDraft', attempt);
      final result = await _client.send({
        'submissionId': _id,
        'message': message,
        'category': _category,
        'details': _attemptDetails,
      });
      _uncertain =
          (wasUncertain && result.status != FeedbackStatus.confirmed) ||
          result.status == FeedbackStatus.pending ||
          result.status == FeedbackStatus.conflict;
      if (result.status == FeedbackStatus.confirmed) {
        if (mounted) _message.clear();
        _id = null;
        _includeDetails = false;
        _attemptDetails = {};
      }
      _result = switch (result.status) {
        FeedbackStatus.confirmed =>
          'Feedback sent. Reference #${result.reference}.',
        FeedbackStatus.pending =>
          'Delivery is not confirmed yet. Check again with this same message.',
        FeedbackStatus.unavailable =>
          'Feedback is currently unavailable. Your draft is saved.',
        FeedbackStatus.rateLimited =>
          'Please wait before trying again. Your draft is saved.',
        FeedbackStatus.invalid =>
          'The message was not accepted. Review it and try again.',
        FeedbackStatus.conflict => 'This submission could not be confirmed. Your original draft is retained.',
      };
      await store.update('feedbackDraft', {
        ...attempt,
        'uncertain': _uncertain,
        if (result.status == FeedbackStatus.confirmed) ...{
          'message': '',
          'submissionId': null,
          'includeDetails': false,
          'details': <String, dynamic>{},
        },
      });
      if (result.status == FeedbackStatus.confirmed &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.hidden) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          _busy = false;
          _confirming = true;
        });
        await showConfirmation(
          context,
          message: 'Thank you for your feedback.',
        );
      }
    } catch (_) {
      _result = 'Your draft could not be saved. Please try again.';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (!_loading) {
      final draft = _draft;
      unawaited(
        _store
            .then((store) => store.update('feedbackDraft', draft))
            .catchError((Object _) {}),
      );
    }
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Send feedback')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: AppSpace.page,
            children: [
              TextField(
                controller: _message,
                readOnly: _busy || _uncertain,
                minLines: 6,
                maxLines: 12,
                maxLength: 6000,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _changed(),
              ),
              const SizedBox(height: 16),
              AppChoiceField<String>(
                label: 'Category (optional)',
                value: _category,
                options: const {
                  'problem': 'Problem',
                  'suggestion': 'Suggestion',
                  'other': 'Other',
                },
                onChanged: _busy || _uncertain
                    ? null
                    : (value) {
                        if (value != null) {
                          _category = value;
                          _changed();
                        }
                      },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include app & device details'),
                value: _includeDetails,
                onChanged: _busy || _uncertain
                    ? null
                    : (value) {
                        _includeDetails = value;
                        _changed();
                      },
              ),
              if (_includeDetails)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      (_uncertain ? _attemptDetails : _details).entries
                          .map(
                            (e) =>
                                '${switch (e.key) {
                                  'appVersion' => 'App',
                                  'androidVersion' => 'Android',
                                  'manufacturer' => 'Manufacturer',
                                  'model' => 'Model',
                                  _ => e.key,
                                }}: ${e.value}',
                          )
                          .join('\n'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(feedbackNotice),
              const SizedBox(height: 12),
              if (!_client.configured)
                const Text(
                  'Feedback service is not available yet. You can keep a draft here.',
                ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_result!)),
                ),
              FilledButton.icon(
                onPressed: _busy || _confirming || !_client.configured
                    ? null
                    : _send,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _busy
                      ? 'Sending…'
                      : _uncertain
                      ? 'Check submission'
                      : 'Send',
                ),
              ),
            ],
          ),
  );
}
