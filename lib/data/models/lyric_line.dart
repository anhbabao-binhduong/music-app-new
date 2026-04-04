import 'package:equatable/equatable.dart';

class LyricLine extends Equatable {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});

  @override
  List<Object?> get props => [time, text];
}