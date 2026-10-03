import 'package:flutter_bloc/flutter_bloc.dart';

enum BoostStep {
  packages,
  summary,
  payment,
  success,
  active,
  expired,
  unavailable,
  failed,
  cancelled,
  pending,
}

class BoostListingState {
  const BoostListingState({
    this.step = BoostStep.packages,
    this.package = 'threeDays',
  });

  final BoostStep step;
  final String package;

  BoostListingState copyWith({BoostStep? step, String? package}) =>
      BoostListingState(
        step: step ?? this.step,
        package: package ?? this.package,
      );
}

class BoostListingCubit extends Cubit<BoostListingState> {
  BoostListingCubit() : super(const BoostListingState());

  void packageChanged(String value) => emit(state.copyWith(package: value));

  void continued() {
    final next = switch (state.step) {
      BoostStep.packages => BoostStep.summary,
      BoostStep.summary => BoostStep.payment,
      BoostStep.payment => BoostStep.success,
      BoostStep.expired ||
      BoostStep.failed ||
      BoostStep.cancelled => BoostStep.packages,
      _ => state.step,
    };
    emit(state.copyWith(step: next));
  }

  void stepSelected(BoostStep value) => emit(state.copyWith(step: value));
}
