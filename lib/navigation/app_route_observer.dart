import 'package:flutter/material.dart';

/// Observes nested pushes (e.g. Search) over [MainShell] so profile can reload.
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();
