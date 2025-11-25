import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

void runAppWithDebuggingMode({
  required Widget appView,
  bool usingDebugging = kDebugMode,
}) {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        logsCubit.addLog(
          LogsHelper(
            status: LogsStatus.error,
            label: '- FLUTTER ERROR - ${details.exception}',
            currentTime: DateTime.now(),
          ),
        );
        FlutterError.dumpErrorToConsole(details);
      };

      runApp(
        Column(
          children: [
            Expanded(child: appView),
            debuggerView(usingDebugging),
          ],
        ),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        logsCubit.addLog(
          LogsHelper(
            status: LogsStatus.normal,
            label: line,
            currentTime: DateTime.now(),
          ),
        );
      },
    ),
    (error, stack) => logsCubit.addLog(
      LogsHelper(
        status: LogsStatus.error,
        label: '- ERROR - $error',
        currentTime: DateTime.now(),
      ),
    ),
  );
}

Widget debuggerView(bool usingDebugging) {
  return CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: SafeArea(
      top: false,
      child: Container(
        color: Colors.grey.shade300,
        padding: EdgeInsets.all(8),
        width: double.infinity,
        child: BlocProvider.value(
          value: logsCubit,
          child: BlocBuilder<LogsCubit, LogsState>(
            builder: (context, state) {
              bool hideByKeyboard =
                  MediaQuery.of(context).viewInsets.bottom > 0;
              bool hideByDeveloper = !state.showTerminal;
              if (hideByKeyboard) return SizedBox();
              if (usingDebugging) {
                if (hideByDeveloper) {
                  return ElevatedButton(
                    onPressed: () =>
                        logsCubit.switchTerminal(!state.showTerminal),
                    child: Text("Show Terminal"),
                  );
                }
                return Stack(
                  alignment: AlignmentDirectional.topCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          height: 175 + state.terminalSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF071013), Color(0xFF0A0F14)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.black87,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: 15),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    actionButton(
                                      color: Colors.yellow,
                                      icon: Icons.keyboard_arrow_down_sharp,
                                      onTap: () => logsCubit.switchTerminal(
                                        !state.showTerminal,
                                      ),
                                    ),
                                    actionButton(
                                      color: Colors.redAccent,
                                      icon: Icons.delete,
                                      onTap: () => logsCubit.clearLogs(),
                                    ),
                                  ],
                                ),
                                Divider(thickness: 1, color: Colors.white),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: state.logs.length,
                                    itemBuilder: (context, index) {
                                      final log = state.logs[index];
                                      return GestureDetector(
                                        onTap: () => Clipboard.setData(
                                          ClipboardData(text: log.label),
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            text:
                                                '[${DateFormat('HH:mm:ss').format(log.currentTime)}]',
                                            style: TextStyle(
                                              color:
                                                  log.status == LogsStatus.error
                                                  ? Colors.white
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              fontFamily: 'Courier',
                                            ),
                                            children: [
                                              TextSpan(
                                                text: ' ${log.label}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Courier',
                                                  color:
                                                      log.status ==
                                                          LogsStatus.error
                                                      ? Colors.redAccent
                                                      : Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressMoveUpdate: (details) {
                        double newOffsetPos =
                            (details.offsetFromOrigin.dy) * -1;
                        double newOffset = (details.offsetFromOrigin.dy);
                        if (newOffset < 75 && newOffset > -175) {
                          logsCubit.setTerminalSize(newOffsetPos);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return SizedBox();
            },
          ),
        ),
      ),
    ),
  );
}

Widget actionButton({
  required VoidCallback onTap,
  required Color color,
  required IconData icon,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color),
    ),
  );
}

final logsCubit = LogsCubit();

class LogsCubit extends Cubit<LogsState> {
  LogsCubit() : super(const LogsState(logs: [], terminalSize: 0));

  void addLog(LogsHelper log) {
    emit(state.copyWith(logs: [...state.logs, log]));
  }

  void clearLogs() {
    emit(state.copyWith(logs: []));
  }

  void setTerminalSize(double screenSize) {
    emit(state.copyWith(terminalSize: screenSize));
  }

  void switchTerminal(bool value) {
    emit(state.copyWith(showTerminal: value));
  }
}

class LogsState extends Equatable {
  final List<LogsHelper> logs;
  final double terminalSize;
  final bool showTerminal;

  const LogsState({
    required this.logs,
    required this.terminalSize,
    this.showTerminal = false,
  });

  LogsState copyWith({
    List<LogsHelper>? logs,
    double? terminalSize,
    bool? showTerminal,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      terminalSize: terminalSize ?? this.terminalSize,
      showTerminal: showTerminal ?? this.showTerminal,
    );
  }

  @override
  List<Object?> get props => [logs, terminalSize, showTerminal];
}

enum LogsStatus { error, warning, normal }

class LogsHelper {
  final LogsStatus status;
  final String label;
  final DateTime currentTime;

  LogsHelper({
    required this.status,
    required this.label,
    required this.currentTime,
  });
}
