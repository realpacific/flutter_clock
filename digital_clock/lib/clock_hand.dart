import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract class ClockHand {
  final List<int> values;
  final ScrollController controller;
  int _counter = 1;
  int _duplicationCount = 5;
  final DateFormat dateFormat;

  ClockHand(this.values, this.controller, this.dateFormat);

  int get duplicationCount => _duplicationCount;

  calculateIndex(DateTime dateTime) {
    final format = dateFormat.format(dateTime);
    final handTime = int.parse(format);
    final indexInValuesList = values.indexOf(handTime);
    final newPosition = indexInValuesList + values.length * _counter;
    // If the current hand time value is equal to the max possible value of the hand i.e the last element of [values], then switch to new iteration;
    if (handTime == values.last) {
      _counter++;
      print("At last: Counter:" + _counter.toString());
    }
    // Reset the [_counter] as there is only one duplication of the hand values remaining, hence save one set of hand values to the right
    if (_counter == _duplicationCount) {
      print("Resetting: Counter:" + _counter.toString());
      // Reset to 1 so as to offset the list and save one unexplored set of hand values on the left
      _counter = 1;
      // Jump to the 2nd set of hand values
      return indexInValuesList + values.length * _counter;
    }
    return newPosition;
  }
}

class SecondClockHand extends ClockHand {
  SecondClockHand(ScrollController controller)
      : super(new List<int>.generate(60, (int index) => index), controller,
            DateFormat("ss")) {
    _duplicationCount = 4;
  }
}

class HourClockHand extends ClockHand {
  HourClockHand(ScrollController controller)
      : super(new List<int>.generate(12, (int index) => index + 1), controller,
            DateFormat("hh")) {
    _duplicationCount = 4;
  }
}

class MinuteClockHand extends ClockHand {
  MinuteClockHand(ScrollController controller)
      : super(new List<int>.generate(60, (int index) => index), controller,
            DateFormat("mm")) {
    _duplicationCount = 4;
  }
}

Widget buildHand(ClockHand hand) {
  return ListView.separated(
      separatorBuilder: (BuildContext context, int index) {
        return Divider();
      },
      controller: hand.controller,
      itemCount: hand.values.length * hand.duplicationCount,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        int currentTime = hand.values[index % hand.values.length];
        return Container(
          height: 50,
          width: 90,
          child: Center(
            child: Text(
              '${(currentTime <= 9) ? '0' + currentTime.toString() : currentTime}',
              style: TextStyle(fontSize: 30),
            ),
          ),
        );
      });
}
