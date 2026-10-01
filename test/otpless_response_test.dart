import 'package:flutter_test/flutter_test.dart';
import 'package:otpless_flutter_headless_demo/otpless/otpless_errors.dart';
import 'package:otpless_flutter_headless_demo/otpless/otpless_response.dart';
import 'package:otpless_flutter_headless_demo/otpless/otpless_service.dart';

void main() {
  group('OtplessResponse', () {
    test('parses INITIATE', () {
      final r = OtplessResponse.fromRaw({
        'responseType': 'INITIATE',
        'statusCode': 200,
        'response': {
          'requestId': 'req_1',
          'authType': 'OTP',
          'deliveryChannel': 'WHATSAPP',
        },
      });
      expect(r.type, OtplessResponseType.initiate);
      expect(r.isSuccess, isTrue);
      expect(r.authType, OtplessAuthType.otp);
      expect(r.deliveryChannel, 'WHATSAPP');
    });

    test('reads ONETAP token from response or response.data', () {
      final direct = OtplessResponse.fromRaw({
        'responseType': 'ONETAP',
        'statusCode': 200,
        'response': {'token': 'abc'},
      });
      final nested = OtplessResponse.fromRaw({
        'responseType': 'ONETAP',
        'statusCode': '200',
        'response': {
          'data': {'token': 'def', 'idToken': 'jwt'},
        },
      });
      expect(direct.token, 'abc');
      expect(nested.token, 'def');
      expect(nested.idToken, 'jwt');
      expect(nested.isSuccess, isTrue);
    });

    test('unknown responseType does not throw', () {
      final r = OtplessResponse.fromRaw({'responseType': 'SOMETHING_NEW'});
      expect(r.type, OtplessResponseType.unknown);
      expect(r.statusCode, -1);
      expect(r.response, isEmpty);
    });
  });

  group('OtplessErrors', () {
    test('maps known codes', () {
      final r = OtplessResponse.fromRaw({
        'responseType': 'VERIFY',
        'statusCode': 400,
        'response': {'errorCode': '7118', 'errorMessage': 'Incorrect OTP'},
      });
      expect(OtplessErrors.messageFor(r), contains('Incorrect OTP'));
    });

    test('falls back to SDK message', () {
      final r = OtplessResponse.fromRaw({
        'responseType': 'INITIATE',
        'statusCode': 400,
        'response': {'errorCode': '1234', 'errorMessage': 'From SDK'},
      });
      expect(OtplessErrors.messageFor(r), 'From SDK');
    });
  });

  test('redact hides OTPs and tokens at any depth', () {
    final out = OtplessService.redact({
      'phone': '9999999999',
      'otp': '123456',
      'response': {
        'data': {'token': 't', 'idToken': 'j'},
      },
    }) as Map;
    expect(out['phone'], '9999999999');
    expect(out['otp'], '•••');
    expect(out['response']['data']['token'], '•••');
    expect(out['response']['data']['idToken'], '•••');
  });
}
