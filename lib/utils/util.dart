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

import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart' as Base32Converter;
import 'package:dart_otp/dart_otp.dart' as OTPLibrary;
import 'package:hex/hex.dart' as HexConverter;
import 'package:privacyidea_authenticator/model/tokens.dart';

import 'identifiers.dart';

Uint8List decodeSecretToUint8(String secret, String encoding) {
  ArgumentError.checkNotNull(secret, "secret");
  ArgumentError.checkNotNull(encoding, "encoding");

  switch (encoding) {
    case NONE:
      return utf8.encode(secret);
      break;
    case HEX:
      return HexConverter.HEX.decode(secret);
      break;
    case BASE32:
      return Base32Converter.base32.decode(secret);
      break;
    default:
      throw ArgumentError.value(
          encoding, "encoding", "The encoding is unknown and not supported!");
  }
}

bool isValidEncoding(String secret, String encoding) {
  try {
    decodeSecretToUint8(secret, encoding);
  } on Exception catch (_) {
    return false;
  }

  return true;
}

String calculateHotpValue(HOTPToken token) {
  String base32Secret = Base32Converter.base32.encode(token.secret);
  return OTPLibrary.HOTP(
    counter: token.counter,
    digits: token.digits,
    secret: base32Secret,
    algorithm: _mapAlgorithms(token.algorithm),
  ).at(counter: token.counter);
}

// TODO test this method, may use mockito for 'faking' the system time
String calculateTotpValue(TOTPToken token) {
  String base32Secret = Base32Converter.base32.encode(token.secret);
  return OTPLibrary.TOTP(
          interval: token.period,
          digits: token.digits,
          secret: base32Secret,
          algorithm: _mapAlgorithms(token.algorithm))
      .now();
}

OTPLibrary.OTPAlgorithm _mapAlgorithms(String algorithmName) {
  ArgumentError.checkNotNull(algorithmName, "algorithmName");

  switch (algorithmName) {
    case SHA1:
      return OTPLibrary.OTPAlgorithm.SHA1;
    case SHA256:
      return OTPLibrary.OTPAlgorithm.SHA256;
    case SHA512:
      return OTPLibrary.OTPAlgorithm.SHA512;
    default:
      throw ArgumentError.value(algorithmName, "algorithmName",
          "This algortihm is unknown and not supported!");
  }
}

/// Inserts [char] at the position [pos] in the given String ([str]), and returns the resulting String.
///
/// Example: insertCharAt("ABCD", " ", 2) --> "AB CD"
String insertCharAt(String str, String char, int pos) {
  return str.substring(0, pos) + char + str.substring(pos, str.length);
}
