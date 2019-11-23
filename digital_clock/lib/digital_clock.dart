// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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

class ClockHand {
  final List<int> values;
  final ScrollController controller;
  int currentIndex = 0;
  int maxRepitition = 10;
  final DateFormat dateFormat;

  ClockHand(this.values, this.controller, this.dateFormat);

  calculateIndex(DateTime dateTime) {
    final format = dateFormat.format(dateTime);
//    if (currentIndex < values.length * (maxRepitition - 2)) {
//      return (values.length + values.indexOf(int.parse(format))) *
//          (currentIndex / values.length).ceil();
//    }
    return values.length + values.indexOf(int.parse(format));
  }
}

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  static final hours = new List<int>.generate(12, (int index) => index + 1);
  static final minutes = new List<int>.generate(60, (int index) => index);
  static final seconds = new List<int>.generate(60, (int index) => index);
  static final ScrollController _hoursController =
      new ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _minutesController =
      new ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _secondController =
      new ScrollController(initialScrollOffset: 0.0);
  ClockHand hourHand = ClockHand(hours, _hoursController, DateFormat("hh"));
  ClockHand minuteHand =
      ClockHand(minutes, _minutesController, DateFormat("mm"));
  ClockHand secondHand =
      ClockHand(seconds, _secondController, DateFormat("ss"));

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
    print((indexOfHours - 12).toString() +
        ":" +
        (indexOfMinutes - 60).toString() +
        ":" +
        (indexOfSeconds - 60).toString());
    if (secondHand.controller.hasClients) {
      secondHand.controller.animateTo(
        (indexOfSeconds - OFFSET) * (90.0),
        curve: Curves.linear,
        duration: const Duration(milliseconds: 600),
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
              Expanded(
                  child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider();
                      },
                      controller: hourHand.controller,
                      itemCount:
                          hourHand.values.length * hourHand.maxRepitition,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        hourHand.currentIndex = index;
                        return Container(
                          width: 90,
                          child: Center(
                            child: Text(
                              '${(index + 1) % 12}',
                              style: TextStyle(fontSize: 60),
                            ),
                          ),
                        );
                      })),
              Expanded(
                  child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider();
                      },
                      controller: minuteHand.controller,
                      itemCount:
                          minuteHand.values.length * minuteHand.maxRepitition,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        minuteHand.currentIndex = index;
                        return Container(
                          height: 50,
                          width: 90,
                          child: Center(
                            child: Text(
                              '${index % 60}',
                              style: TextStyle(fontSize: 50),
                            ),
                          ),
                        );
                      })),
              Expanded(
                  child: ListView.separated(
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider();
                      },
                      controller: secondHand.controller,
                      itemCount:
                          secondHand.values.length * secondHand.maxRepitition,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        secondHand.currentIndex = index;
                        print(index.toString() + " index secs");
                        return Container(
                          height: 50,
                          width: 90,
                          child: Center(
                            child: Text(
                              '${index % 60}',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                        );
                      })),
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
