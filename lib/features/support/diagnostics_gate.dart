import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final diagnosticsRouteObserver = RouteObserver<ModalRoute<void>>();

/// Visit-scoped casual access gate. Every diagnostics route builds this boundary.
class DiagnosticsGate extends StatefulWidget {
  const DiagnosticsGate({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<DiagnosticsGate> createState() => _DiagnosticsGateState();
}

class _DiagnosticsGateState extends State<DiagnosticsGate>
    with WidgetsBindingObserver, RouteAware {
  final _pin = TextEditingController();
  bool _unlocked = false;
  String? _error;
  ModalRoute<void>? _route;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (_route != route) {
      diagnosticsRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) diagnosticsRouteObserver.subscribe(this, route);
    }
  }

  void _relock() {
    _pin.clear();
    if (mounted) {
      setState(() {
        _unlocked = false;
        _error = null;
      });
    }
  }

  @override
  void didPushNext() => _relock();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _relock();
    }
  }

  void _unlock() {
    if (_pin.text == '4444') {
      FocusManager.instance.primaryFocus?.unfocus();
      _pin.clear();
      setState(() {
        _unlocked = true;
        _error = null;
      });
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  void dispose() {
    diagnosticsRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _unlocked
      ? widget.builder(context)
      : Scaffold(
          appBar: AppBar(title: const Text('Audio diagnostics')),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const ValueKey('diagnostics-pin'),
                          controller: _pin,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'PIN',
                            errorText: _error,
                            counterText: '',
                          ),
                          onSubmitted: (_) => _unlock(),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: _unlock,
                              child: const Text('Open'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
}
