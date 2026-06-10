import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

// --- EVENTS ---
abstract class VenueEvent extends Equatable {
  const VenueEvent();
  @override
  List<Object?> get props => [];
}

class LoadVenuesEvent extends VenueEvent {}

// --- STATES ---
abstract class VenueState extends Equatable {
  const VenueState();
  @override
  List<Object?> get props => [];
}

class VenueInitialState extends VenueState {}

class VenueLoadingState extends VenueState {}

class VenueLoadedState extends VenueState {
  final List<Venue> venues;
  const VenueLoadedState(this.venues);
  @override
  List<Object?> get props => [venues];
}

class VenueErrorState extends VenueState {
  final String message;
  const VenueErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class VenueBloc extends Bloc<VenueEvent, VenueState> {
  final ApiService apiService;

  VenueBloc({required this.apiService}) : super(VenueInitialState()) {
    on<LoadVenuesEvent>((event, emit) async {
      emit(VenueLoadingState());
      try {
        final venues = await apiService.getVenues();
        emit(VenueLoadedState(venues));
      } catch (e) {
        emit(VenueErrorState(e.toString()));
      }
    });
  }
}
