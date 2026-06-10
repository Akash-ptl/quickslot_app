import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

// --- EVENTS ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends AuthEvent {}

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

class AuthInitialState extends AuthState {}

class AuthUsersLoadingState extends AuthState {}

class AuthUsersLoadedState extends AuthState {
  final List<User> users;
  const AuthUsersLoadedState(this.users);
  @override
  List<Object?> get props => [users];
}

class AuthUsersErrorState extends AuthState {
  final String message;
  const AuthUsersErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthenticatedState extends AuthState {
  final User user;
  const AuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitialState()) {
    on<LoadUsersEvent>((event, emit) async {
      emit(AuthUsersLoadingState());
      try {
        final users = await apiService.getUsers();
        emit(AuthUsersLoadedState(users));
      } catch (e) {
        emit(AuthUsersErrorState(e.toString()));
      }
    });

    on<LoginEvent>((event, emit) {
      emit(AuthenticatedState(event.user));
    });

    on<LogoutEvent>((event, emit) {
      emit(AuthInitialState()); // Revert back to loadable state
    });
  }
}
