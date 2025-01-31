// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:digital_clock/arc_clipper.dart';
import 'package:digital_clock/clock_hand.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_clock_helper/model.dart';

import 'assets_weather_mapper.dart';

enum _Element {
  background,
  text,
  shadow,
}

enum _HourFormat { hours24, hours12 }

const OFFSET = 3;
const WIDTH = 90.0;
const WEATHER_DISPLAY_WIDTH = 300.0;
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
  WeatherCondition _condition;
  var _location = '';
  var isPortrait = true;
  var offset = OFFSET;

  static final ScrollController _hoursController =
      ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _minutesController =
      ScrollController(initialScrollOffset: 0.0);
  static final ScrollController _secondController =
      ScrollController(initialScrollOffset: 0.0);
  ClockHand hourHand;
  ClockHand minuteHand = MinuteClockHand(_minutesController);
  ClockHand secondHand = SecondClockHand(_secondController);
  var _currentHourFormat = _HourFormat.hours12;

  var _weatherDisplayWidth = WEATHER_DISPLAY_WIDTH;

  @override
  void initState() {
    super.initState();
    hourHand = widget.model.is24HourFormat
        ? Hour24ClockHand(_hoursController)
        : Hour12ClockHand(_hoursController);
    _currentHourFormat =
        widget.model.is24HourFormat ? _HourFormat.hours24 : _HourFormat.hours12;
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
      _condition = widget.model.weatherCondition;
      _location = widget.model.location;
      if (widget.model.is24HourFormat &&
          _currentHourFormat == _HourFormat.hours12) {
        _currentHourFormat = _HourFormat.hours24;
        hourHand = Hour24ClockHand(_hoursController);
      } else if (!widget.model.is24HourFormat &&
          _currentHourFormat == _HourFormat.hours24) {
        _currentHourFormat = _HourFormat.hours12;
        hourHand = Hour12ClockHand(_hoursController);
      }
    });
  }

  void _updateTime() {
    var indexOfMinutes = minuteHand.calculateIndex(_dateTime);
    var indexOfSeconds = secondHand.calculateIndex(_dateTime);
    var indexOfHours = hourHand.calculateIndex(_dateTime);
    if (secondHand.controller.hasClients) {
      secondHand.controller.animateTo(
        (indexOfSeconds - offset) * WIDTH,
        curve: Curves.linear,
        duration: const Duration(milliseconds: 200),
      );
    }
    if (hourHand.controller.hasClients) {
      hourHand.controller.animateTo(
        (indexOfHours - offset) * WIDTH,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 900),
      );
    }
    if (minuteHand.controller.hasClients) {
      minuteHand.controller.animateTo(
        (indexOfMinutes - offset) * (WIDTH),
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 900),
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
        _weatherDisplayWidth = 200;
      } else {
        offset = 4;
        _weatherDisplayWidth = WEATHER_DISPLAY_WIDTH;
      }
    });
    return Container(
      decoration: new BoxDecoration(
        gradient: new LinearGradient(
            colors: [Color(0xff49637D), Color(0xff0C1725)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft),
      ),
      child: Stack(
        children: <Widget>[
          _buildTimeDisplayHolder(),
          _buildWeatherStatusHolder(),
        ],
      ),
    );
  }

  Stack _buildTimeDisplayHolder() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: buildHand(hourHand)),
              Expanded(child: buildHand(minuteHand)),
              Expanded(child: buildHand(secondHand, fontSize: 40.0)),
            ],
          ),
        ),
        _buildMarker()
      ],
    );
  }

  Widget _buildWeatherStatusHolder() {
    return ClipPath(
      clipBehavior: Clip.antiAlias,
      clipper: ArcClipper(),
      child: SizedBox(
        width: _weatherDisplayWidth,
        child: Card(
          shape: ContinuousRectangleBorder(),
          borderOnForeground: true,
          color: Colors.grey,
          elevation: 40.0,
          margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 5.0),
          child: Stack(
            children: <Widget>[
              buildWallpaper(),
              buildOverlay(),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _temperature,
                      style: TextStyle(fontSize: 50.0, fontFamily: 'Varela'),
                    ),
                    Text(
                      _temperatureRange,
                      style: TextStyle(fontSize: 15.0, fontFamily: 'Varela'),
                    ),
                    buildWidgetForWeatherStatus(),
                    Text(
                      _location,
                      style: TextStyle(fontSize: 20.0, fontFamily: 'Varela'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container buildWallpaper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        image: new DecorationImage(
          image: new AssetImage(
              isDarkTheme() ? 'assets/stacked_rocks.jpg' : 'assets/boats.jpg'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Container buildWidgetForWeatherStatus() {
    final fileName = AssetWeatherMapper.getAssetForWeather(_condition);
    if (fileName == null ||
        (!fileName.endsWith('png') && !fileName.endsWith('flr'))) {
      return Container(
          child: Text(_condition.toString().split(".")[1].toUpperCase()));
    }
    return Container(
      width: 60.0,
      height: 60.0,
      child: fileName.endsWith('flr')
          ? FlareActor('assets/$fileName', animation: 'animate')
          : Image.asset('assets/$fileName'),
    );
  }

  Container buildOverlay() {
    return Container(
      color: isDarkTheme() ? Colors.black54 : Colors.transparent,
    );
  }

  Widget _buildMarker() {
    return Positioned(
      top: -30.0,
      bottom: 20.0,
      width: 90,
      left: (WIDTH) * offset,
      child: Container(
        width: 96.0,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white,
            width: 3.0,
          ),
        ),
      ),
    );
  }

  bool isDarkTheme() {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
