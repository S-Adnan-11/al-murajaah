import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 144});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/main-blue.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/wordmark-white.png',
    color: Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary
        : const Color(0xff34afe4),
    colorBlendMode: BlendMode.srcIn,
    width: 150,
    height: 42,
    fit: BoxFit.contain,
    semanticLabel: 'Al-Murāja\'ah',
  );
}

class BrandedStartup extends StatelessWidget {
  const BrandedStartup({
    super.key,
    this.failed = false,
    this.loading = false,
    this.retry,
  });
  final bool failed;
  final bool loading;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff050c1d)
        : Colors.white,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!loading) const BrandMark(size: 184),
              const SizedBox(height: 16),
              Text(
                loading ? 'Opening your listening library…' : 'Al-Murāja’ah',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (failed) ...[
                const SizedBox(height: 24),
                const Text(
                  'Your library could not be opened.',
                  textAlign: TextAlign.center,
                ),
                if (retry != null)
                  TextButton(onPressed: retry, child: const Text('Try again'))
                else
                  const Text(
                    'Close and reopen the app to retry.',
                    textAlign: TextAlign.center,
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
