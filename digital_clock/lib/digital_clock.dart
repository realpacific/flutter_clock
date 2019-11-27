// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:digital_clock/arc_clipper.dart';
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

const OFFSET = 3;
const WIDTH = 90.0;
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
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  var isPortrait = true;
  var offset = OFFSET;

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
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    var indexOfMinutes = minuteHand.calculateIndex(_dateTime);
    var indexOfSeconds = secondHand.calculateIndex(_dateTime);
    var indexOfHours = hourHand.calculateIndex(_dateTime);
    if (secondHand.controller.hasClients) {
      secondHand.controller.animateTo(
        (indexOfSeconds - offset) * (WIDTH),
        curve: Curves.linear,
        duration: const Duration(milliseconds: 200),
      );
    }
    if (hourHand.controller.hasClients) {
      hourHand.controller.animateTo(
        (indexOfHours - offset) * WIDTH,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 1000),
      );
    }
    if (minuteHand.controller.hasClients) {
      minuteHand.controller.animateTo(
        (indexOfMinutes - offset) * (WIDTH),
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
    setState(() {
      if (MediaQuery.of(context).orientation == Orientation.portrait) {
        offset = OFFSET;
      } else {
        offset = 4;
      }
    });

    return Container(
      decoration: new BoxDecoration(
        gradient: new LinearGradient(
            colors: [Colors.red, Colors.purpleAccent],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft),
      ),
      child: Stack(
        children: <Widget>[
          Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Align(
                        alignment: Alignment.topRight,
                        child: Text(DateFormat("HH:mm:ss")
                            .format(_dateTime)
                            .toString())),
                    Expanded(child: buildHand(hourHand)),
                    Expanded(child: buildHand(minuteHand)),
                    Expanded(child: buildHand(secondHand)),
                  ],
                ),
              ),
              Positioned(
                top: 5.0,
                bottom: 5.0,
                width: 90,
                left: (WIDTH) * offset,
                child: Container(
                  width: 96.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 3.0,
                    ),
                  ),
                ),
              )
            ],
          ),
          ClipPath(
            clipBehavior: Clip.antiAlias,
            clipper: ArcClipper(),
            child: SizedBox(
              width: 250.0,
              child: Card(
                margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 5.0),
                elevation: 90.0,
                child: Container(
                  decoration: BoxDecoration(
                    image: new DecorationImage(
                      image: new AssetImage(
                          'assets/joonas-sild-CwnDbpkSdYI-unsplash.webp'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _temperature,
                        style: TextStyle(
                            fontSize: 50.0, fontFamily: 'Segment7Standard'),
                      ),
                      Text(_temperatureRange),
                      Text(_condition),
                      Text(_location),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
