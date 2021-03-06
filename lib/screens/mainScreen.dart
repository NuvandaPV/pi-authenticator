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

import 'package:flutter/material.dart';
import 'package:privacyidea_authenticator/model/tokens.dart';
import 'package:privacyidea_authenticator/screens/addManuallyScreen.dart';
import 'package:privacyidea_authenticator/widgets/hotpwidget.dart';
import 'package:privacyidea_authenticator/widgets/totpwidget.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Token> _tokenList = List<Token>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.title,
        ),
        actions: _buildActionMenu(),
        leading: Padding(
          padding: EdgeInsets.all(4.0),
          child: Image.asset('res/logo/app_logo.png'),
        ),
      ),
      body: _buildTokenList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddButtonPressed(context),
        child: Icon(Icons.add),
      ),
    );
  }

  _onAddButtonPressed(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.assignment),
                    // TODO search for good icons
                    title: new Text(
                      'Add token manually',
                      style: Theme.of(context).textTheme.button,
                    ),
                    onTap: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTokenManuallyScreen(),
                              )).then((newToken) => _addNewToken(newToken))
                        }),
                new ListTile(
                  leading: new Icon(Icons.scanner),
                  // TODO search for good qrcode icon and add license -> http://fluttericon.com/
                  title: new Text(
                    'Scan QR-Code',
                    style: Theme.of(context).textTheme.button,
                  ),
                  onTap: () => {
                    // TODO scan a qr code and create the corresponding token?
                  },
                ),
              ],
            ),
          );
        });
  }

  ListView _buildTokenList() {
    return ListView.separated(
        itemBuilder: (context, index) {
          Token currentToken = _tokenList[index];
          if (currentToken is HOTPToken) {
            return HOTPWidget(
              token: currentToken,
            );
          } else if (currentToken is TOTPToken) {
            return TOTPWidget(
              token: currentToken,
            );
          }

          return null;
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
        itemCount: _tokenList.length);
  }

  List<Widget> _buildActionMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        onSelected: (String value) => {
          if (value == "about")
            {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LicensePage(
                            applicationName: "privacyIDEA Authenticator",
                            applicationVersion: "0.0.1",
                            applicationIcon:
                                Image.asset('res/logo/app_logo.png'),
                            applicationLegalese: "Apache License 2.0",
                            // TODO see http://astashov.s3.amazonaws.com/dartdoc_flutter/current/material/showLicensePage.html for information.
                            // TODO Register new licenses.
                          )))
            }
          else
            {
              // TODO if we have settingsat some point, open them
            }
        },
        elevation: 5.0,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: "about",
            child: Text("About"),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: null, // TODO add value as key for navigation
            child: Text("Settings"),
          ),
        ],
      ),
    ];
  }

  _addNewToken(Token newToken) {
    print("Token recieved: $newToken");
    if (newToken != null) {
      setState(() {
        _tokenList.add(newToken);
      });
    }
  }
}
