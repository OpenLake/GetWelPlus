import 'package:firebase_auth/firebase_auth.dart';



class AuthService {

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  User? get currentuser => firebaseAuth.currentUser;

  Stream<User?> get authstatechanges => firebaseAuth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,

  }) async{
    return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signup({
      required String email,
      required String password,
  }) async{
    return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async{
    await firebaseAuth.signOut();
  }


}