import 'dart:io';

import 'package:bloc_firebase_storage/auth/auth_error.dart';
import 'package:bloc_firebase_storage/bloc/app_event.dart';
import 'package:bloc_firebase_storage/bloc/app_state.dart';
import 'package:bloc_firebase_storage/utils/upload_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc()
      : super(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        ) {
    on<AppEventInitialize>(
      (event, emit) async {
        // get the current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          emit(
            const AppStateLoggedOut(
              isLoading: false,
            ),
          );
        } else {
          // go grab the user's uploaded images
          final images = await _getImages(user.uid);
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: user,
              images: images,
            ),
          );
        }
      },
    );

    on<AppEventGoToRegistration>((event, emit) {
      emit(
        const AppStateIsInRegistrationView(
          isLoading: false,
        ),
      );
    });
    on<AppEventLogIn>(
      (event, emit) async {
        emit(
          const AppStateLoggedOut(
            isLoading: true,
          ),
        );
        // log the user in
        try {
          final email = event.email;
          final password = event.password;
          final userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          // get images for user
          final user = userCredential.user!;
          final images = await _getImages(user.uid);
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: user,
              images: images,
            ),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateLoggedOut(
              isLoading: false,
              authError: AuthError.from(e),
            ),
          );
        }
      },
    );
    on<AppEventGoToLogin>(
      (event, emit) {
        emit(
          const AppStateLoggedOut(
            isLoading: false,
          ),
        );
      },
    );

    on<AppEventRegister>(
      (event, emit) async {
        // start loading
        emit(
          const AppStateIsInRegistrationView(
            isLoading: true,
          ),
        );
        final email = event.email;
        final password = event.password;
        try {
          // create the user
          final credentials =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          emit(
            AppStateLoggedIn(
              isLoading: false,
              user: credentials.user!,
              images: const [],
            ),
          );
        } on FirebaseAuthException catch (e) {
          emit(
            AppStateIsInRegistrationView(
              isLoading: false,
              authError: AuthError.from(e),
            ),
          );
        }
      },
    );

// handel account delete

    on<AppEventDeleteAccount>((event, emit) async {
      final user = FirebaseAuth.instance.currentUser;
      // log user out if we don't have current user
      if (user == null) {
        emit(const AppStateLoggedOut(isLoading: false));
        return;
      }
// start loading
      emit(
        AppStateLoggedIn(
          isLoading: true,
          user: user,
          images: state.images ?? [],
        ),
      );
      // delete the user folder
      try {
// delete user folder

        final folder = await FirebaseStorage.instance.ref(user.uid).listAll();
        for (final items in folder.items) {
          await items.delete().catchError((_) {}); // may be handel the error
        }
        // delete folder itself
        await FirebaseStorage.instance
            .ref(user.uid)
            .delete()
            .catchError((_) {});

        await user.delete();

        // signed out user
        await FirebaseAuth.instance.signOut();
        // log the user out in ui as well
        emit(const AppStateLoggedOut(
          isLoading: false,
        ));
      } on FirebaseAuthException catch (e) {
        emit(
          AppStateLoggedIn(
            isLoading: false,
            user: user,
            images: state.images ?? [],
            authError: AuthError.from(e),
          ),
        );
      } on FirebaseException {
        // we might not be able to delete the folder
        // log the user out

        emit(
          const AppStateLoggedOut(isLoading: false),
        );
      }
    });

// log out event
    on<AppEventLogOut>((event, emit) async {
      emit(const AppStateLoggedOut(
        isLoading: true,
      ));

      // signed out user
      await FirebaseAuth.instance.signOut();
      // log the user out in ui as well
      emit(const AppStateLoggedOut(
        isLoading: false,
      ));
    });

    // handel uploading image
    on<AppEventUploadImage>(
      (event, emit) async {
        // log user out if we don't have actual user in app state.
        final user = state.user;
        if (user == null) {
          emit(const AppStateLoggedOut(isLoading: false));
          return;
        }
// start loading process
        emit(
          AppStateLoggedIn(
            isLoading: true,
            user: user,
            images: state.images ?? [],
          ),
        );

        // upload file
        final file = File(event.filePathToUpload);
        await uploadImage(
          file: file,
          userId: user.uid,
        );
        // after upload is complete , grab the latest file reference
        final images = await _getImages(user.uid);
        // emit new images and turn off loading
        emit(
          AppStateLoggedIn(isLoading: false, user: user, images: images),
        );
      },
    );
  }

  Future<Iterable<Reference>> _getImages(String userId) =>
      FirebaseStorage.instance
          .ref(userId)
          .list()
          .then((listResult) => listResult.items);
}
