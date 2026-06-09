class UserModel {
  const UserModel({required this.id, required this.mobile, required this.username});

  final String id;
  final String mobile;
  final String username;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        mobile: (j['mobile'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'mobile': mobile, 'username': username};

  UserModel copyWith({String? username}) =>
      UserModel(id: id, mobile: mobile, username: username ?? this.username);
}
