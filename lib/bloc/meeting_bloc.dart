import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'meeting_event.dart';
part 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  MeetingBloc() : super(MeetingInitial()) {
    on<MeetingEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
