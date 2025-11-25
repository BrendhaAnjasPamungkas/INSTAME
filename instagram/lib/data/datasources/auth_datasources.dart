import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/core/errors/exception.dart';
import 'package:instagram/data/models/notification_model.dart';
import 'package:instagram/data/models/user_models.dart';
import 'package:instagram/domain/entities/notification.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signUp(
    String username,
    String fullName,
    String email,
    String password,
  );
  Future<UserCredential> signIn(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<UserModel> getUser(String uid);
  Future<void> logOut();
  Future<List<UserModel>> searchUsers(String query);
  Future<void> updateUserData(String uid, String newUsername, String newBio, String? newProfileImageUrl);
  Future<void> toggleFollowUser(
    String targetUserId,
    String currentUserId,
  ) async {}
 
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> signUp(
    String username,
    String fullName,
    String email,
    String password,
  ) async {
    try {
      // 1. BUAT PENGGUNA DI FIREBASE AUTH
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User newUser = userCredential.user!;

      // 2. BUAT MODEL PENGGUNA BARU
      final userModel = UserModel(
        uid: newUser.uid,
        username: username.trim(),
        email: email.trim(),
        fullName: fullName.trim(),
        // Data profil lain default-nya null/kosong
      );

      // 3. SIMPAN MODEL KE FIRESTORE (KOLEKSI 'users')
      await firestore
          .collection('users') // Nama koleksi
          .doc(newUser.uid) // ID dokumen = ID user auth
          .set(userModel.toJson()); // Simpan data JSON

      return userModel; // Kembalikan model yang sudah dibuat
    } on FirebaseAuthException {
      rethrow; // Biarkan repository yang tangani error
    }
  }
  @override
  Future<void> updateUserData(String uid, String newUsername, String newBio,String? newProfileImageUrl) async {
    try {
      // Siapkan data yang mau di-update
      final Map<String, dynamic> dataToUpdate = {
        'username': newUsername,
        'bio': newBio,
      };

      // Hanya update foto jika ada perubahan (tidak null)
      if (newProfileImageUrl != null) {
        dataToUpdate['profileImageUrl'] = newProfileImageUrl;
      }

      await firestore.collection('users').doc(uid).update(dataToUpdate);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? "Gagal mengirim email reset.");
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw ServerException("Gagal kirim verifikasi: ${e.toString()}");
    }
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) {
      return []; // Kembalikan daftar kosong jika query kosong
    }

    try {
      // Kueri Firestore untuk "starts with" (dimulai dengan)
      // Kita mencari 'username' yang lebih besar dari query
      // DAN lebih kecil dari query + karakter 'batas'
      final snapshot = await firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + '\uf8ff')
          .limit(15) // Batasi hasil (opsional tapi bagus)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> getUser(String uid) async {
    try {
      // Ambil dokumen user dari koleksi 'users'
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromSnapshot(doc);
      } else {
        throw ServerException("Data user tidak ditemukan");
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserCredential> signIn(String email, String password) async {
    // Implementasi login
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> toggleFollowUser(
    String targetUserId,
    String currentUserId,
  ) async {
    // Kita pakai Batched Write untuk memastikan kedua update berhasil
    // atau keduanya gagal.
    final WriteBatch batch = firestore.batch();

    // 1. Dapatkan referensi ke DOKUMEN KITA (Current User)
    final DocumentReference currentUserRef = firestore
        .collection('users')
        .doc(currentUserId);

    // 2. Dapatkan referensi ke DOKUMEN TARGET (Orang yg di-follow)
    final DocumentReference targetUserRef = firestore
        .collection('users')
        .doc(targetUserId);

    try {
      // Ambil data dokumen target untuk cek
      final targetDoc = await targetUserRef.get();
      if (!targetDoc.exists) {
        throw ServerException("User yang ingin di-follow tidak ditemukan.");
      }
      final data = targetDoc.data()! as Map<String, dynamic>;

      // 2. Sekarang aman untuk mengakses 'followers' dari Map
      final List<String> targetFollowers = List<String>.from(
        data['followers'] ?? [],
      );
      // Logika Toggle:
      if (targetFollowers.contains(currentUserId)) {
        // --- JIKA SUDAH FOLLOW -> LAKUKAN UNFOLLOW ---

        // Hapus ID kita dari 'followers' list dia
        batch.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([currentUserId]),
        });

        // Hapus ID dia dari 'following' list kita
        batch.update(currentUserRef, {
          'following': FieldValue.arrayRemove([targetUserId]),
        });
      } else {
        // --- JIKA BELUM FOLLOW -> LAKUKAN FOLLOW ---

        // Tambahkan ID kita ke 'followers' list dia
        batch.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([currentUserId]),
        });
        _sendNotification(
          toUserId: targetUserId,
          currentUserId: currentUserId,
          type: NotificationType.follow,
        );

        // Tambahkan ID dia ke 'following' list kita
        batch.update(currentUserRef, {
          'following': FieldValue.arrayUnion([targetUserId]),
        });
      }

      // 3. Jalankan kedua update sekaligus
      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  Future<void> _sendNotification({
    required String toUserId, // Siapa yang dapat notif
    required String currentUserId, // Siapa yang kirim
    required NotificationType type,
    String? postId,
    String? text,
    String? postImageUrl, // Opsional: Gambar postingan
  }) async {
    if (toUserId == currentUserId) return; // Jangan notif ke diri sendiri

    try {
      // Ambil data pengirim (kita) agar notifikasi lengkap
      final userDoc = await firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final userData = userDoc.data()!;

      final notif = NotificationModel(
        id: '',
        userId: toUserId,
        fromUserId: currentUserId,
        fromUsername: userData['username'],
        fromUserProfileUrl: userData['profileImageUrl'],
        type: type,
        postId: postId,
        postImageUrl: postImageUrl, // Simpan URL gambar post
        text: text,
        timestamp: DateTime.now(),
      );

      await firestore.collection('notifications').add(notif.toJson());
    } catch (e) {
      print("Gagal kirim notifikasi: $e"); // Non-blocking error
    }
  }
}
