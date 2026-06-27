import 'dart:convert';

// ─── User ──────────────────────────────────────────────────────────────────

class UserModel {
  final String username;
  final String avatar;
  final String surname;
  final String otherNames;
  final String email;
  final String phone;
  final String timezone;
  final String joinDate;

  UserModel({
    required this.username,
    required this.avatar,
    required this.surname,
    required this.otherNames,
    required this.email,
    required this.phone,
    required this.timezone,
    required this.joinDate,
  });

  String get fullName => '$surname $otherNames'.trim();
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>? ?? {};
    final contact = json['contact'] as Map<String, dynamic>? ?? {};
    final dated = json['dated'] as Map<String, dynamic>? ?? {};

    return UserModel(
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      surname: name['surname']?.toString() ?? '',
      otherNames: name['other_names']?.toString() ?? '',
      email: contact['email']?.toString() ?? '',
      phone: contact['phone']?.toString() ?? '',
      timezone: dated['timezone']?.toString() ?? '',
      joinDate: dated['join']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'avatar': avatar,
        'name': {'surname': surname, 'other_names': otherNames},
        'contact': {'email': email, 'phone': phone},
        'dated': {'timezone': timezone, 'join': joinDate},
      };

  String toStorageString() => jsonEncode(toJson());

  factory UserModel.fromStorageString(String s) =>
      UserModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

// ─── Auth Response ─────────────────────────────────────────────────────────

class AuthResponse {
  final String message;
  final String accessToken;
  final String tokenType;
  final UserModel user;

  AuthResponse({
    required this.message,
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>? ?? {};
    return AuthResponse(
      message: json['message']?.toString() ?? '',
      accessToken: tokens['access_token']?.toString() ?? '',
      tokenType: tokens['token_type']?.toString() ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ─── Document ──────────────────────────────────────────────────────────────

class DocumentVisibility {
  final String value;
  final String name;

  DocumentVisibility({required this.value, required this.name});

  factory DocumentVisibility.fromJson(Map<String, dynamic> json) =>
      DocumentVisibility(
        value: json['value']?.toString() ?? 'pri',
        name: json['name']?.toString() ?? 'Private',
      );

  bool get isPublic => value == 'pub';
}

class DocumentType {
  final String mime;
  final String extension;
  final String img;

  DocumentType({required this.mime, required this.extension, required this.img});

  factory DocumentType.fromJson(Map<String, dynamic> json) => DocumentType(
        mime: json['mime']?.toString() ?? '',
        extension: json['extension']?.toString() ?? '',
        img: json['img']?.toString() ?? '',
      );
}

class DocumentSize {
  final String string;
  final int bytes;

  DocumentSize({required this.string, required this.bytes});

  factory DocumentSize.fromJson(Map<String, dynamic> json) => DocumentSize(
        string: json['string']?.toString() ?? '0 B',
        bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      );
}

class DocumentLinks {
  final String detail;
  final String summary;
  final String move;

  DocumentLinks({required this.detail, required this.summary, required this.move});

  factory DocumentLinks.fromJson(Map<String, dynamic> json) => DocumentLinks(
        detail: json['detail']?.toString() ?? '',
        summary: json['summary']?.toString() ?? '',
        move: json['move']?.toString() ?? '',
      );
}

class DocumentDated {
  final String datetime;
  final String string;

  DocumentDated({required this.datetime, required this.string});

  factory DocumentDated.fromJson(Map<String, dynamic> json) => DocumentDated(
        datetime: json['datetime']?.toString() ?? '',
        string: json['string']?.toString() ?? '',
      );
}

class DocumentModel {
  final String id;
  final String name;
  final DocumentVisibility visibility;
  final DocumentType type;
  final DocumentSize size;
  final DocumentDated dated;
  final DocumentLinks links;

  DocumentModel({
    required this.id,
    required this.name,
    required this.visibility,
    required this.type,
    required this.size,
    required this.dated,
    required this.links,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Untitled',
        visibility: DocumentVisibility.fromJson(
            json['visibility'] as Map<String, dynamic>? ?? {}),
        type: DocumentType.fromJson(
            json['type'] as Map<String, dynamic>? ?? {}),
        size: DocumentSize.fromJson(
            json['size'] as Map<String, dynamic>? ?? {}),
        dated: DocumentDated.fromJson(
            json['dated'] as Map<String, dynamic>? ?? {}),
        links: DocumentLinks.fromJson(
            json['links'] as Map<String, dynamic>? ?? {}),
      );
}

// ─── Upload Result ─────────────────────────────────────────────────────────

class UploadResult {
  final String fileName;
  final bool success;
  final String? message;
  final DocumentModel? document;
  final DateTime uploadedAt;

  UploadResult({
    required this.fileName,
    required this.success,
    this.message,
    this.document,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();
}

// ─── API Error ─────────────────────────────────────────────────────────────

class ApiError {
  final String message;
  final Map<String, List<String>> errors;
  final int? statusCode;

  ApiError({required this.message, this.errors = const {}, this.statusCode});

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    final rawErrors = json['errors'] as Map<String, dynamic>? ?? {};
    final parsedErrors = rawErrors.map(
      (k, v) => MapEntry(
        k,
        (v as List<dynamic>).map((e) => e.toString()).toList(),
      ),
    );
    return ApiError(
      message: json['message']?.toString() ?? 'Unknown error',
      errors: parsedErrors,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
