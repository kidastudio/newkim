import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive/rive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kim Orb Rive Preview',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const RivePreviewPage(),
    );
  }
}

class RivePreviewPage extends StatefulWidget {
  const RivePreviewPage({super.key});

  @override
  State<RivePreviewPage> createState() => _RivePreviewPageState();
}

class _RivePreviewPageState extends State<RivePreviewPage>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  // Data Binding (New Rive API)
  ViewModelInstanceTrigger? _talkingTrigger;
  ViewModelInstanceTrigger? _listeningTrigger;
  ViewModelInstanceTrigger? _resetTrigger;
  ViewModelInstanceTrigger? _thinkingTrigger;
  ViewModelInstanceNumber? _voiceLevelInput;
  ViewModelInstanceString? _smallOrbsClickInput;

  // Track active artboard
  String _activeArtboard = 'AllOrbs';

  // Track the current value for the voice level slider
  double _currentVoiceLevel = 0.0;
  String _smallOrbsClickValue = '';

  // Store FileLoader to avoid recreation on every build
  late final FileLoader _fileLoader;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/kim_orb2.riv',
      riveFactory: Factory.rive,
    );
    _ticker = createTicker((elapsed) {
      if (_smallOrbsClickInput != null &&
          _smallOrbsClickValue != _smallOrbsClickInput!.value) {
        setState(() {
          _smallOrbsClickValue = _smallOrbsClickInput!.value;
        });
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  void _onRiveLoaded(RiveLoaded state) {
    final vmi = state.viewModelInstance;

    if (vmi != null) {
      // Use the new Data Binding API
      _talkingTrigger = vmi.trigger('talking');
      _listeningTrigger = vmi.trigger('listening');
      _resetTrigger = vmi.trigger('reset');
      _thinkingTrigger = vmi.trigger('thinking');
      _voiceLevelInput = vmi.number('voiceLevel');
      _smallOrbsClickInput = vmi.string('smallOrbsClick');

      // Initialize values from the binding
      if (_voiceLevelInput != null) {
        _currentVoiceLevel = _voiceLevelInput!.value;
      }
      if (_smallOrbsClickInput != null) {
        _smallOrbsClickValue = _smallOrbsClickInput!.value;
      }
    }

    // Force rebuild to enable buttons
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kim Orb Preview')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'AllOrbs', label: Text('All Orbs')),
                ButtonSegment(value: 'MainOrb', label: Text('Main Orb')),
              ],
              selected: {_activeArtboard},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _activeArtboard = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: RiveWidgetBuilder(
              key: ValueKey(_activeArtboard),
              fileLoader: _fileLoader,
              artboardSelector: ArtboardNamed(_activeArtboard),
              stateMachineSelector: const StateMachineNamed('State Machine 1'),
              dataBind: const AutoBind(), // Enable Data Binding
              onLoaded: _onRiveLoaded,
              builder: (context, state) {
                return switch (state) {
                  RiveLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  RiveFailed(:final error) => Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  RiveLoaded(:final controller) => Center(
                    child: RiveWidget(controller: controller, fit: Fit.contain),
                  ),
                };
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Triggers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTriggerButton("Thinking", _thinkingTrigger),
                      _buildTriggerButton("Listening", _listeningTrigger),
                      _buildTriggerButton("Talking", _talkingTrigger),
                      _buildTriggerButton("Reset", _resetTrigger),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Small Orbs Click (Read-only)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      _smallOrbsClickValue.isEmpty
                          ? "No click data"
                          : _smallOrbsClickValue,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Voice Level",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text("0"),
                      Expanded(
                        child: Slider(
                          value: _currentVoiceLevel,
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              _currentVoiceLevel = value;
                              if (_voiceLevelInput != null) {
                                _voiceLevelInput!.value = value;
                              }
                            });
                          },
                        ),
                      ),
                      Text(_currentVoiceLevel.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerButton(String label, ViewModelInstanceTrigger? trigger) {
    return ElevatedButton(
      onPressed: trigger == null
          ? null
          : () {
              trigger.trigger();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Fired '$label'"),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            },
      child: Text(label),
    );
  }
}
