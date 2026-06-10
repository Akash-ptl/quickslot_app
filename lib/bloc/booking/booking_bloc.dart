import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

// --- EVENTS ---
abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserBookingsEvent extends BookingEvent {
  final int userId;
  const LoadUserBookingsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CancelBookingEvent extends BookingEvent {
  final int bookingId;
  final int userId;
  const CancelBookingEvent({required this.bookingId, required this.userId});
  @override
  List<Object?> get props => [bookingId, userId];
}

class ResetBookingActionStatusEvent extends BookingEvent {}

// --- STATES ---
abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitialState extends BookingState {}

class BookingLoadingState extends BookingState {}

class BookingLoadedState extends BookingState {
  final List<Booking> bookings;
  
  // Status of the current cancel action: 'idle', 'progress', 'success', 'error'
  final String actionStatus; 
  final String? actionMessage;

  const BookingLoadedState({
    required this.bookings,
    this.actionStatus = 'idle',
    this.actionMessage,
  });

  BookingLoadedState copyWith({
    List<Booking>? bookings,
    String? actionStatus,
    String? actionMessage,
  }) {
    return BookingLoadedState(
      bookings: bookings ?? this.bookings,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }

  @override
  List<Object?> get props => [bookings, actionStatus, actionMessage];
}

class BookingErrorState extends BookingState {
  final String message;
  const BookingErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final ApiService apiService;

  BookingBloc({required this.apiService}) : super(BookingInitialState()) {
    on<LoadUserBookingsEvent>((event, emit) async {
      emit(BookingLoadingState());
      try {
        final bookings = await apiService.getUserBookings(event.userId);
        emit(BookingLoadedState(bookings: bookings));
      } catch (e) {
        emit(BookingErrorState(e.toString()));
      }
    });

    on<CancelBookingEvent>((event, emit) async {
      final currentState = state;
      if (currentState is! BookingLoadedState) return;

      emit(currentState.copyWith(actionStatus: 'progress'));

      try {
        await apiService.cancelBooking(event.bookingId);
        
        // Reload bookings for the user
        final updatedBookings = await apiService.getUserBookings(event.userId);
        emit(BookingLoadedState(
          bookings: updatedBookings,
          actionStatus: 'success',
          actionMessage: 'Booking cancelled successfully.',
        ));
      } catch (e) {
        emit(currentState.copyWith(actionStatus: 'error', actionMessage: e.toString()));
      }
    });

    on<ResetBookingActionStatusEvent>((event, emit) {
      final currentState = state;
      if (currentState is BookingLoadedState) {
        emit(currentState.copyWith(
          actionStatus: 'idle',
          actionMessage: null,
        ));
      }
    });
  }
}
