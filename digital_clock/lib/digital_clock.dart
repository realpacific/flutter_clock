// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:digital_clock/clock_hand.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';

enum _Element {
  background,
  text,
  shadow,
}

const OFFSET = 2;

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _Element.shadow: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFF174EA6),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  static final ScrollController _hoursController =
      ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _minutesController =
      ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _secondController =
      ScrollController(initialScrollOffset: 0.0);
  ClockHand hourHand = HourClockHand(_hoursController);
  ClockHand minuteHand = MinuteClockHand(_minutesController);
  ClockHand secondHand = SecondClockHand(_secondController);

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    hourHand.controller.dispose();
    minuteHand.controller.dispose();
    secondHand.controller.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    var indexOfMinutes = minuteHand.calculateIndex(_dateTime);
    var indexOfSeconds = secondHand.calculateIndex(_dateTime);
    var indexOfHours = hourHand.calculateIndex(_dateTime);
    if (secondHand.controller.hasClients) {
      secondHand.controller.animateTo(
        (indexOfSeconds - OFFSET) * (90.0),
        curve: Curves.linear,
        duration: const Duration(milliseconds: 200),
      );
    }
    if (hourHand.controller.hasClients) {
      hourHand.controller.animateTo(
        (indexOfHours - OFFSET) * 90.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 1000),
      );
    }
    if (minuteHand.controller.hasClients) {
      minuteHand.controller.animateTo(
        (indexOfMinutes - OFFSET) * (90.0),
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 1000),
      );
    }
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 3.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(DateFormat("HH:mm:ss").format(_dateTime).toString()),
              Expanded(child: buildHand(hourHand)),
              Expanded(child: buildHand(minuteHand)),
              Expanded(child: buildHand(secondHand)),
            ],
          ),
        ),
        Positioned(
          top: 2.0,
          bottom: 2.0,
          width: 90,
          left: (90.0 + 4) * OFFSET,
          child: Container(
            width: 96.0,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2.0,
              ),
            ),
          ),
        )
      ],
    );
  }
}
