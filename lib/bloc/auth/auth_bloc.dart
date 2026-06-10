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
  final String password;
  const LoginEvent(this.user, this.password);
  @override
  List<Object?> get props => [user, password];
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

class AuthLoginErrorState extends AuthState {
  final String message;
  const AuthLoginErrorState(this.message);
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
  List<User> _cachedUsers = [];

  AuthBloc({required this.apiService}) : super(AuthInitialState()) {
    on<LoadUsersEvent>((event, emit) async {
      emit(AuthUsersLoadingState());
      try {
        final users = await apiService.getUsers();
        _cachedUsers = users;
        emit(AuthUsersLoadedState(users));
      } catch (e) {
        emit(AuthUsersErrorState(e.toString()));
      }
    });

    on<LoginEvent>((event, emit) async {
      emit(AuthUsersLoadingState());
      try {
        await apiService.login(event.user.id, event.password);
        emit(AuthenticatedState(event.user));
      } catch (e) {
        emit(AuthLoginErrorState(e.toString()));
        emit(AuthUsersLoadedState(_cachedUsers));
      }
    });

    on<LogoutEvent>((event, emit) {
      apiService.logout();
      emit(AuthUsersLoadedState(_cachedUsers));
    });
  }
}

