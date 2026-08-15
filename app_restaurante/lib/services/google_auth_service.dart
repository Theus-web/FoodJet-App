import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class GoogleAuthService {


  final FirebaseAuth _auth =
      FirebaseAuth.instance;


  final GoogleSignIn _google =
      GoogleSignIn();



  Future<User?> loginGoogle() async {


    try {


      final GoogleSignInAccount?
          googleUser =
          await _google.signIn();



      if (googleUser == null) {

        return null;

      }




      final GoogleSignInAuthentication
          googleAuth =
          await googleUser.authentication;




      final credential =
          GoogleAuthProvider.credential(


        accessToken:
            googleAuth.accessToken,


        idToken:
            googleAuth.idToken,


      );




      final result =
          await _auth.signInWithCredential(
            credential,
          );



      return result.user;



    } catch(e) {


      throw Exception(
        "Erro no Google Login: $e",
      );


    }


  }






  Future<void> logoutGoogle() async {


    await _google.signOut();

    await _auth.signOut();


  }



}