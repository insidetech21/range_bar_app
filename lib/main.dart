// lib/main.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'service.dart';
import 'notifier.dart';
import 'widgets/range_bar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final RangesNotifier notifier = RangesNotifier(RangesService());

  MyApp({Key? key}) : super(key: key) {
    notifier.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Range Bar',
      home: ChangeNotifierProvider(
        notifier: notifier,
        child: Scaffold(
          appBar: AppBar(title: Text('Range Bar Assignment')),
          body: Center(child: HomeScreen()),
        ),
      ),
    );
  }
}

// Minimal ChangeNotifier provider (manual because no external packages allowed)
class ChangeNotifierProvider extends InheritedWidget {
  final RangesNotifier notifier;

  const ChangeNotifierProvider({Key? key, required Widget child, required this.notifier}) : super(key: key, child: child);

  static RangesNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ChangeNotifierProvider>();
    if (provider == null) throw FlutterError('ChangeNotifierProvider not found in widget tree');
    return provider.notifier;
  }

  @override
  bool updateShouldNotify(ChangeNotifierProvider oldWidget) => notifier != oldWidget.notifier;
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RangesNotifier notifier;
  final TextEditingController _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    notifier = ChangeNotifierProvider.of(context);
    _controller.text = notifier.inputValue.isNaN ? '' : notifier.inputValue.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: notifier,
      builder: (context, _) {
        if (notifier.isLoading) return CircularProgressIndicator();
        if (notifier.error != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notifier.error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 12),
              ElevatedButton(onPressed: notifier.retry, child: Text('Retry')),
            ],
          );
        }

        final tests = notifier.tests;
        final selected = notifier.selectedTest!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (tests.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, idx) {
                      final t = tests[idx];
                      return ChoiceChip(
                        label: Text(t.title.isEmpty ? 'Test ${idx + 1}' : t.title),
                        selected: idx == notifier.selectedIndex,
                        onSelected: (_) => notifier.selectTest(idx),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(width: 8),
                    itemCount: tests.length,
                  ),
                ),
              SizedBox(height: 18),
              RangeBar(testCase: selected, value: notifier.inputValue.isNaN ? selected.min : notifier.inputValue),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        hintText: 'Enter value',
                      ),
                      onChanged: (s) {
                        final v = double.tryParse(s);
                        notifier.updateInput(v);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final v = double.tryParse(_controller.text);
                      notifier.updateInput(v);
                    },
                    style: ElevatedButton.styleFrom(shape: CircleBorder(), padding: EdgeInsets.all(16)),
                    child: Icon(Icons.arrow_forward),
                  )
                ],
              ),
              SizedBox(height: 12),
              Text('Range: ${selected.min} - ${selected.max}'),
            ],
          ),
        );
      },
    );
  }
}
