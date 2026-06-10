import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models.dart';

// Preconfigured Users matching our database seed data
final mockUsers = [
  User(id: 1, name: "Akash Patel"),
  User(id: 2, name: "Judge Alpha"),
  User(id: 3, name: "Judge Beta"),
  User(id: 4, name: "Test User 4"),
  User(id: 5, name: "Test User 5"),
];

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final User user;
  const LoginEvent(this.user);
  @override
  List<Object?> get props => [user];
}

class LogoutEvent extends AuthEvent {}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class UnauthenticatedState extends AuthState {}

class AuthenticatedState extends AuthState {
  final User user;
  const AuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(UnauthenticatedState()) {
    on<LoginEvent>((event, emit) {
      emit(AuthenticatedState(event.user));
    });

    on<LogoutEvent>((event, emit) {
      emit(UnauthenticatedState());
    });
  }
}
