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

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  const LoginEvent(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String name;
  final String password;
  const RegisterEvent({required this.email, required this.name, required this.password});
  @override
  List<Object?> get props => [email, name, password];
}

class LogoutEvent extends AuthEvent {}

// --- STATES ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
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
    on<LoginEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final user = await apiService.login(event.email, event.password);
        emit(AuthenticatedState(user));
      } catch (e) {
        emit(AuthErrorState(e.toString().replaceAll("Exception: ", "")));
      }
    });

    on<RegisterEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        await apiService.register(event.email, event.name, event.password);
        final user = await apiService.login(event.email, event.password);
        emit(AuthenticatedState(user));
      } catch (e) {
        emit(AuthErrorState(e.toString().replaceAll("Exception: ", "")));
      }
    });

    on<LogoutEvent>((event, emit) {
      apiService.logout();
      emit(AuthInitialState());
    });
  }
}

