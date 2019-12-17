/*
  privacyIDEA Authenticator

  Authors: Timo Sturm <timo.sturm@netknights.it>

  Copyright (c) 2017-2019 NetKnights GmbH

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:privacyidea_authenticator/model/tokens.dart';
import 'package:privacyidea_authenticator/utils/storageUtils.dart';
import 'package:privacyidea_authenticator/utils/util.dart';

class TokenWidget extends StatefulWidget {
  final Token _token;
  final Function _delete;

  TokenWidget(this._token, this._delete);

  @override
  State<StatefulWidget> createState() {
    if (_token is HOTPToken) {
      return _HotpWidgetState(_token, _delete);
    } else if (_token is TOTPToken) {
      return _TotpWidgetState(_token, _delete);
    } else {
      throw ArgumentError.value(_token, "token",
          "The token [$_token] is of unknown type and not supported");
    }
  }
}

abstract class _TokenWidgetState extends State<TokenWidget> {
  final Token _token;
  static final SlidableController _slidableController = SlidableController();
  String _otpValue;
  String _label;

  final Function _delete;

  _TokenWidgetState(this._token, this._delete) {
    _otpValue = calculateOtpValue(_token);
    _saveThisToken();
    _label = _token.label;
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(_token.serial),
      // This is used to only let one Slidable be open at a time.
      controller: _slidableController,
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
        color: Colors.white,
        child: _buildTile(),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => _deleteTokenDialog(),
        ),
        IconSlideAction(
          caption: 'Rename',
          color: Colors.blue,
          icon: Icons.edit,
          onTap: () => _renameTokenDialog(),
        ),
      ],
    );
  }

  // TODO Test this behaviour with integration testing.
  void _renameTokenDialog() {
    final _nameInputKey = GlobalKey<FormFieldState>();
    String _selectedName;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Rename token"),
            titleTextStyle: Theme.of(context).textTheme.subhead,
            content: TextFormField(
              autofocus: true,
              initialValue: _label,
              key: _nameInputKey,
              onChanged: (value) => this.setState(() => _selectedName = value),
              decoration: InputDecoration(labelText: "Name"),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter a name for this token.';
                }
                return null;
              },
            ),
            actions: <Widget>[
              FlatButton(
                child: Text("Rename"),
                onPressed: () {
                  if (_nameInputKey.currentState.validate()) {
                    _renameToken(_selectedName);
                    Navigator.of(context).pop();
                  }
                },
              ),
              FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        });
  }

  void _renameToken(String newLabel) {
    _saveThisToken();
    log(
      "Renamed token:",
      name: "token_widgets.dart",
      error: "\"${_token.label}\" changed to \"$newLabel\"",
    );
    _token.label = newLabel;

    setState(() {
      _label = _token.label;
    });
  }

  void _deleteTokenDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm deletion"),
            titleTextStyle: Theme.of(context).textTheme.subhead,
            content: RichText(
              text: TextSpan(
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: "Are you sure you want to delete ",
                    ),
                    TextSpan(
                        text: "\'$_label\'?",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ))
                  ]),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () => {
                  _deleteToken(),
                  Navigator.of(context).pop(),
                },
                child: Text("Yes!"),
              ),
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("No, take me back!"),
              ),
            ],
          );
        });
  }

  // FIXME It seems that doing this without the list is not possible, it may work if the list is returned by token_widget instead
  void _deleteToken() {
    // TODO find out what to do here ...
//    setState(() {
//      StorageUtil.deleteToken(_token);
//      _tokenList.remove(_token);
//    });
    // TODO remove this unnecessary method
    _delete(_token);
  }

  void _saveThisToken() {
    StorageUtil.saveOrReplaceToken(this._token);
  }

  void _updateOtpValue();

  Widget _buildTile();
}

class _HotpWidgetState extends _TokenWidgetState {
  _HotpWidgetState(Token token, Function delete) : super(token, delete);

  @override
  void _updateOtpValue() {
    setState(() {
      (_token as HOTPToken).incrementCounter();
      _otpValue = calculateOtpValue(_token);
    });
  }

  @override
  Widget _buildTile() {
    return Stack(
      children: <Widget>[
        ListTile(
          title: Center(
            child: Text(
              insertCharAt(_otpValue, " ", _otpValue.length ~/ 2),
              textScaleFactor: 2.5,
            ),
          ),
          subtitle: Center(
            child: Text(
              _label,
              textScaleFactor: 2.0,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: RaisedButton(
            onPressed: () => _updateOtpValue(),
            child: Text(
              "Next",
              textScaleFactor: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _TotpWidgetState extends _TokenWidgetState
    with SingleTickerProviderStateMixin {
  AnimationController
      controller; // Controller for animating the LinearProgressAnimator

  _TotpWidgetState(Token token, Function delete) : super(token, delete);

  @override
  void _updateOtpValue() {
    setState(() {
      _otpValue = calculateOtpValue(_token);
    });
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: Duration(seconds: (_token as TOTPToken).period),
      // Animate the progress for the duration of the tokens period.
      vsync:
          this, // By extending SingleTickerProviderStateMixin we can use this object as vsync, this prevents offscreen animations.
    )
      ..addListener(() {
        // Adding a listener to update the view for the animation steps.
        setState(() => {
              // The state that has changed here is the animation object’s value.
            });
      })
      ..addStatusListener((status) {
        // Add listener to restart the animation after the period, also updates the otp value.
        if (status == AnimationStatus.completed) {
          controller.forward(from: 0.0);
          _updateOtpValue();
        }
      })
      ..forward(); // Start the animation.

    // Update the otp value when the android app resumes, this prevents outdated otp values
    // ignore: missing_return
    SystemChannels.lifecycle.setMessageHandler((msg) {
      log(
        "SystemChannels:",
        name: "totpwidget.dart",
        error: msg,
      );
      if (msg == AppLifecycleState.resumed.toString()) {
        _updateOtpValue();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the controller to prevent memory leak.
    super.dispose();
  }

  @override
  Widget _buildTile() {
    return Column(
      children: <Widget>[
        ListTile(
          title: Center(
            child: Text(
              insertCharAt(_otpValue, " ", _otpValue.length ~/ 2),
              textScaleFactor: 2.5,
            ),
          ),
          subtitle: Center(
            child: Text(
              _label,
              textScaleFactor: 2.0,
            ),
          ),
        ),
        LinearProgressIndicator(
          value: controller.value,
        ),
      ],
    );
  }
}