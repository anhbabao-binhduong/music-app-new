import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_constants.dart';

// ─── Events ──────────────────────────────────────────────────

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override List<Object?> get props => [];
}

class LoadThemeEvent  extends ThemeEvent { const LoadThemeEvent(); }
class ToggleThemeEvent extends ThemeEvent { const ToggleThemeEvent(); }

class SetThemeModeEvent extends ThemeEvent {
  final AppThemeMode mode;
  const SetThemeModeEvent(this.mode);
  @override List<Object?> get props => [mode];
}

// ─── State ───────────────────────────────────────────────────

enum AppThemeMode { light, dark, system }

class ThemeState extends Equatable {
  final AppThemeMode mode;
  const ThemeState(this.mode);

  ThemeMode get flutterThemeMode => switch (mode) {
    AppThemeMode.light  => ThemeMode.light,
    AppThemeMode.dark   => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  bool get isDark => mode == AppThemeMode.dark;

  @override List<Object?> get props => [mode];
}

// ─── Bloc ────────────────────────────────────────────────────

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  Box<dynamic> get _settings => Hive.box(HiveBoxes.settings);

  ThemeBloc() : super(const ThemeState(AppThemeMode.dark)) {
    on<LoadThemeEvent>  (_onLoad);
    on<ToggleThemeEvent>(_onToggle);
    on<SetThemeModeEvent>(_onSet);
  }

  Future<void> _onLoad(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    final saved = _settings.get(
      HiveSettingsKeys.themeMode,
      defaultValue: 'dark',
    ) as String;

    final mode = switch (saved) {
      'light'  => AppThemeMode.light,
      'system' => AppThemeMode.system,
      _        => AppThemeMode.dark,
    };
    emit(ThemeState(mode));
  }

  Future<void> _onToggle(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final next = state.mode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await _persist(next);
    emit(ThemeState(next));
  }

  Future<void> _onSet(SetThemeModeEvent event, Emitter<ThemeState> emit) async {
    await _persist(event.mode);
    emit(ThemeState(event.mode));
  }

  Future<void> _persist(AppThemeMode mode) async {
    await _settings.put(
      HiveSettingsKeys.themeMode,
      mode.name,   // 'light' | 'dark' | 'system'
    );
  }
}