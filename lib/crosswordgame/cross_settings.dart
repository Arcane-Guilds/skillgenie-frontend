// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'maincross.dart';


class CrosswordSettingsRoute extends StatefulWidget {
  final int pageid;
  final String title;
  final bool language;

  const CrosswordSettingsRoute({
    super.key,
    required this.pageid,
    required this.title,
    required this.language,
  });

  @override
  _CrosswordSettingsRouteState createState() => _CrosswordSettingsRouteState();
}

class _CrosswordSettingsRouteState extends State<CrosswordSettingsRoute> {
  int _size = 15;
  int _words = 15;
  int _recursive = 3;
  int _maxlen = 15;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossword Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic: ${widget.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSlider(
              'Grid Size',
              _size,
              5,
              25,
              (value) {
                setState(() {
                  _size = value.round();
                });
              },
            ),
            _buildSlider(
              'Number of Words',
              _words,
              5,
              30,
              (value) {
                setState(() {
                  _words = value.round();
                });
              },
            ),
            _buildSlider(
              'Recursive Depth',
              _recursive,
              1,
              5,
              (value) {
                setState(() {
                  _recursive = value.round();
                });
              },
            ),
            _buildSlider(
              'Max Word Length',
              _maxlen,
              5,
              20,
              (value) {
                setState(() {
                  _maxlen = value.round();
                });
              },
            ),
            const Spacer(),
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                        });
                        // Generate crossword and navigate to it
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CrosswordRoute(
                              pageid: widget.pageid,
                              size: _size,
                              diff: _getDifficultyLevel(), // Calculate difficulty based on settings
                              lang_rus: widget.language,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _loading = false;
                            });
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        'Generate Crossword',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    int value,
    int min,
    int max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: value.toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Helper method to determine difficulty level based on settings
  int _getDifficultyLevel() {
    // Calculate difficulty based on word count, recursive depth, and max length
    if (_words <= 10 && _recursive <= 2 && _maxlen <= 10) {
      return 1; // Easy
    } else if (_words >= 20 && _recursive >= 4 && _maxlen >= 18) {
      return 3; // Hard
    } else {
      return 2; // Medium
    }
  }
}

class GenSettings
{
  GenSettings(this.pageid, this.size, this.difficulty, this.lang_rus);
  int pageid, size, difficulty;
  bool lang_rus;
}

