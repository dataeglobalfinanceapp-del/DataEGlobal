import 'dart:async';

import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/features/auth/models/auth_sign_in_challenge.dart';
import 'package:savetep/features/auth/screens/login_screen/login/controllers/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginController', () {
    test('validate rejects an empty identifier and short password', () {
      final LoginController controller = LoginController(
        signIn: (_, _) async => true,
      );
      addTearDown(controller.dispose);

      controller.identifierController.text = '  ';
      controller.passwordController.text = 'short';

      expect(controller.validate(), isFalse);
      expect(controller.state.identifierInvalid, isTrue);
      expect(controller.state.passwordInvalid, isTrue);
      expect(
        controller.state.errors,
        contains('Username or email is required'),
      );
      expect(
        controller.state.errors,
        contains('Password must be at least 8 characters'),
      );
    });

    test(
      'submit trims email alias and exposes loading while pending',
      () async {
        final Completer<bool> signInCompleter = Completer<bool>();
        String? submittedIdentifier;
        String? submittedPassword;
        final LoginController controller = LoginController(
          signIn: (String email, String password) {
            submittedIdentifier = email;
            submittedPassword = password;
            return signInCompleter.future;
          },
        );
        addTearDown(controller.dispose);

        controller.identifierController.text = ' sunny@example.com ';
        controller.passwordController.text = 'Password1!';

        final Future<bool> result = controller.submit();

        expect(controller.state.isLoading, isTrue);
        expect(submittedIdentifier, 'sunny@example.com');
        expect(submittedPassword, 'Password1!');

        signInCompleter.complete(true);

        expect(await result, isTrue);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.errors, isEmpty);
      },
    );

    test('submit accepts and trims a Cognito username', () async {
      String? submittedIdentifier;
      final LoginController controller = LoginController(
        signIn: (String identifier, String password) async {
          submittedIdentifier = identifier;
          return true;
        },
      );
      addTearDown(controller.dispose);

      controller.identifierController.text = ' demo-owner ';
      controller.passwordController.text = 'Password1!';

      expect(await controller.submit(), isTrue);
      expect(submittedIdentifier, 'demo-owner');
      expect(controller.state.identifierInvalid, isFalse);
    });

    test('continues an MFA verification challenge', () async {
      String? submittedChallenge;
      var signInCalls = 0;
      final LoginController controller = LoginController(
        signIn: (_, _) async {
          signInCalls += 1;
          throw const AuthSignInChallengeRequired(
            type: AuthSignInChallengeType.verificationCode,
            stepName: 'confirmSignInWithSmsMfaCode',
            prompt: 'Enter the verification code.',
            inputLabel: 'VERIFICATION CODE',
            obscureInput: false,
            canRespond: true,
          );
        },
        confirmSignIn: (String response) async {
          submittedChallenge = response;
          return true;
        },
      );
      addTearDown(controller.dispose);
      controller.identifierController.text = 'demo-owner';
      controller.passwordController.text = 'Password1!';

      expect(await controller.submit(), isFalse);
      expect(
        controller.state.challenge?.type,
        AuthSignInChallengeType.verificationCode,
      );

      controller.challengeController.text = ' 123456 ';
      expect(await controller.submit(), isTrue);
      expect(submittedChallenge, '123456');
      expect(signInCalls, 1);
      expect(controller.state.challenge, isNull);
    });

    test('surfaces non-interactive sign-in steps without retrying', () async {
      final LoginController controller = LoginController(
        signIn: (_, _) async {
          throw AuthSignInChallengeRequired.fromStep('resetPassword');
        },
      );
      addTearDown(controller.dispose);
      controller.identifierController.text = 'demo-owner';
      controller.passwordController.text = 'Password1!';

      expect(await controller.submit(), isFalse);
      expect(controller.state.challenge, isNull);
      expect(controller.state.errors.single, contains('Reset'));
    });

    test('requires sign-in again after API session expiry', () async {
      var signInCalls = 0;
      final LoginController controller = LoginController(
        signIn: (_, _) async {
          signInCalls += 1;
          return true;
        },
        loadBusinessSetupCompleted: () async {
          throw const ApiHttpException(
            kind: ApiFailureKind.unauthenticated,
            statusCode: 401,
          );
        },
      );
      addTearDown(controller.dispose);
      controller.identifierController.text = 'demo-owner';
      controller.passwordController.text = 'Password1!';

      expect(await controller.submitForDestination(), isNull);
      expect(controller.state.authenticationComplete, isFalse);
      expect(
        controller.state.profileError,
        'Your session expired. Sign in again.',
      );

      await controller.submitForDestination();
      expect(signInCalls, 2);
    });
  });
}
