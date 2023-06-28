import 'package:flutter/foundation.dart' show immutable;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;


const Map<String, AuthError> authErrorMapping = {
  'user-not-found': AuthErrorUserNotFound(),
  'weak-password': AuthErrorWeakPassword(),
  'invalid-email': AuthErrorInvalidEmail(),
  'operation-not-allowed': AuthErrorOperationNotAllow(),
  'email-already-in-use': AuthErrorEmailAlreadyUsed(),
  'requires-recent-login': AuthErrorRequiresRecentLogin(),
  'no-current-user': AuthErrorNoCurrentUser(),
};

@immutable
abstract class AuthError {
  final String dialogTitle;
  final String dialogText;

  const AuthError({required this.dialogTitle, required this.dialogText});

  factory AuthError.from(FirebaseAuthException exceptions) =>
      authErrorMapping[exceptions.code.toLowerCase().trim()] ??
      const AuthErrorUnknown();
}

@immutable
class AuthErrorUnknown extends AuthError {
  const AuthErrorUnknown()
      : super(
            dialogTitle: 'Authentication error',
            dialogText: "Unknown Authentication Error");
}

@immutable
class AuthErrorNoCurrentUser extends AuthError {
  const AuthErrorNoCurrentUser()
      : super(
            dialogTitle: 'no current user!',
            dialogText: "No current user with this information found");
}

@immutable
class AuthErrorRequiresRecentLogin extends AuthError {
  const AuthErrorRequiresRecentLogin()
      : super(
            dialogTitle: 'Required recent login',
            dialogText:
                "You need to log out and Log in back to perform this operation");
}

// email and password sign in is not enable , remember to enable it before running the code .
@immutable
class AuthErrorOperationNotAllow extends AuthError {
  const AuthErrorOperationNotAllow()
      : super(
            dialogTitle: 'Operation not allow',
            dialogText:
                "You can not registered using this method at the movement");
}

@immutable
class AuthErrorUserNotFound extends AuthError {
  const AuthErrorUserNotFound()
      : super(
            dialogTitle: 'User Not Found',
            dialogText: "the given user is not found on server!");
}

@immutable
class AuthErrorWeakPassword extends AuthError {
  const AuthErrorWeakPassword()
      : super(
            dialogTitle: 'Weak password',
            dialogText: "Please choose the stronger password");
}

@immutable
class AuthErrorInvalidEmail extends AuthError {
  const AuthErrorInvalidEmail()
      : super(
            dialogTitle: 'Invalid email',
            dialogText: "Please check the email again!");
}

@immutable
class AuthErrorEmailAlreadyUsed extends AuthError {
  const AuthErrorEmailAlreadyUsed()
      : super(
            dialogTitle: 'Invalid email',
            dialogText: "Please Choose another email!");
}
