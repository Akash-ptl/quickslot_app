import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

// --- EVENTS ---
abstract class SlotEvent extends Equatable {
  const SlotEvent();
  @override
  List<Object?> get props => [];
}

class LoadSlotsEvent extends SlotEvent {
  final int venueId;
  final String date;
  const LoadSlotsEvent({required this.venueId, required this.date});

  @override
  List<Object?> get props => [venueId, date];
}

class PollSlotsEvent extends SlotEvent {
  final int venueId;
  final String date;
  const PollSlotsEvent({required this.venueId, required this.date});

  @override
  List<Object?> get props => [venueId, date];
}

class BookSlotEvent extends SlotEvent {
  final int venueId;
  final String date;
  final String slotTime;
  final int userId;

  const BookSlotEvent({
    required this.venueId,
    required this.date,
    required this.slotTime,
    required this.userId,
  });

  @override
  List<Object?> get props => [venueId, date, slotTime, userId];
}

class ResetBookingStatusEvent extends SlotEvent {}

// --- STATES ---
abstract class SlotState extends Equatable {
  const SlotState();
  @override
  List<Object?> get props => [];
}

class SlotInitialState extends SlotState {}

class SlotLoadingState extends SlotState {}

class SlotLoadedState extends SlotState {
  final List<Slot> slots;
  final int venueId;
  final String date;
  
  // Status of the current booking action: 'idle', 'progress', 'success', 'conflict', 'error'
  final String bookingStatus; 
  final String? bookingMessage;
  final String? conflictedSlotTime;

  const SlotLoadedState({
    required this.slots,
    required this.venueId,
    required this.date,
    this.bookingStatus = 'idle',
    this.bookingMessage,
    this.conflictedSlotTime,
  });

  SlotLoadedState copyWith({
    List<Slot>? slots,
    int? venueId,
    String? date,
    String? bookingStatus,
    String? bookingMessage,
    String? conflictedSlotTime,
  }) {
    return SlotLoadedState(
      slots: slots ?? this.slots,
      venueId: venueId ?? this.venueId,
      date: date ?? this.date,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      bookingMessage: bookingMessage ?? this.bookingMessage,
      conflictedSlotTime: conflictedSlotTime ?? this.conflictedSlotTime,
    );
  }

  @override
  List<Object?> get props => [slots, venueId, date, bookingStatus, bookingMessage, conflictedSlotTime];
}

class SlotErrorState extends SlotState {
  final String message;
  const SlotErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLOC ---
class SlotBloc extends Bloc<SlotEvent, SlotState> {
  final ApiService apiService;

  SlotBloc({required this.apiService}) : super(SlotInitialState()) {
    on<LoadSlotsEvent>((event, emit) async {
      emit(SlotLoadingState());
      try {
        final slots = await apiService.getSlots(event.venueId, event.date);
        emit(SlotLoadedState(slots: slots, venueId: event.venueId, date: event.date));
      } catch (e) {
        emit(SlotErrorState(e.toString()));
      }
    });

    on<PollSlotsEvent>((event, emit) async {
      try {
        final slots = await apiService.getSlots(event.venueId, event.date);
        final currentState = state;
        if (currentState is SlotLoadedState) {
          emit(currentState.copyWith(slots: slots));
        } else {
          emit(SlotLoadedState(slots: slots, venueId: event.venueId, date: event.date));
        }
      } catch (e) {
        print('[SlotBloc] Quiet polling error: $e');
      }
    });

    on<BookSlotEvent>((event, emit) async {
      final currentState = state;
      if (currentState is! SlotLoadedState) return;

      // Emit progress
      emit(currentState.copyWith(bookingStatus: 'progress'));

      try {
        // Book the slot
        await apiService.createBooking(event.venueId, event.date, event.slotTime, event.userId);
        
        // Reload slots to get updated grid status
        final updatedSlots = await apiService.getSlots(event.venueId, event.date);
        emit(SlotLoadedState(
          slots: updatedSlots,
          venueId: event.venueId,
          date: event.date,
          bookingStatus: 'success',
          bookingMessage: 'Slot booked successfully!',
        ));
      } on SlotAlreadyBookedException catch (_) {
        // Concurrency conflict - reload slots anyway to show updated grid status
        final updatedSlots = await apiService.getSlots(event.venueId, event.date);
        emit(SlotLoadedState(
          slots: updatedSlots,
          venueId: event.venueId,
          date: event.date,
          bookingStatus: 'conflict',
          conflictedSlotTime: event.slotTime,
        ));
      } catch (e) {
        emit(currentState.copyWith(bookingStatus: 'error', bookingMessage: e.toString()));
      }
    });

    on<ResetBookingStatusEvent>((event, emit) {
      final currentState = state;
      if (currentState is SlotLoadedState) {
        emit(currentState.copyWith(
          bookingStatus: 'idle',
          bookingMessage: null,
          conflictedSlotTime: null,
        ));
      }
    });
  }
}
