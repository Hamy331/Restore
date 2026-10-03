import 'package:equatable/equatable.dart';

class OtpState extends Equatable {
  final int secondsRemaining;

  const OtpState({required this.secondsRemaining});

  String get formattedTime {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isExpired => secondsRemaining == 0;

  @override
  List<Object> get props => [secondsRemaining];
}
