import 'package:equatable/equatable.dart';

class MerchantProfile extends Equatable {
  final String id;
  final bool isMerchant;
  final String firstName;
  final String lastName;
  final String? email;
  final int dialingCode;
  final int mobileNumber;
  final List<String> roles;
  final List<String> stores;
  final List<String> outStores;
  final String? businessName;
  final String? image;

  const MerchantProfile({
    required this.id,
    required this.isMerchant,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.dialingCode,
    required this.mobileNumber,
    required this.roles,
    required this.stores,
    required this.outStores,
    this.businessName,
    this.image,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MerchantProfile.fromJson(Map<String, dynamic> json) {
    String? emailAddress;
    if (json['email'] is Map<String, dynamic>) {
      emailAddress = json['email']['id'] as String?;
    } else if (json['email'] is String) {
      emailAddress = json['email'] as String;
    }

    int dialingCode = 91;
    int mobileNumber = 0;
    if (json['mobile'] is Map<String, dynamic>) {
      dialingCode = (json['mobile']['dialing_code'] as num?)?.toInt() ?? 91;
      mobileNumber = (json['mobile']['number'] as num?)?.toInt() ?? 0;
    } else if (json['mobile'] is num) {
      mobileNumber = (json['mobile'] as num).toInt();
    }

    List<String> parseStringList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return const [];
    }

    String? businessDisplayName;
    if (json['wsbuyer'] is Map<String, dynamic>) {
      businessDisplayName = json['wsbuyer']['display_name'] as String?;
    }

    return MerchantProfile(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      isMerchant: json['is_merchant'] as bool? ?? false,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: emailAddress,
      dialingCode: dialingCode,
      mobileNumber: mobileNumber,
      roles: parseStringList(json['role']),
      stores: parseStringList(json['store']),
      outStores: parseStringList(json['out_stores']),
      businessName: businessDisplayName,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'is_merchant': isMerchant,
      'first_name': firstName,
      'last_name': lastName,
      'email': {'id': email},
      'mobile': {
        'dialing_code': dialingCode,
        'number': mobileNumber,
      },
      'role': roles,
      'store': stores,
      'out_stores': outStores,
      'wsbuyer': {'display_name': businessName},
      'image': image,
    };
  }

  @override
  List<Object?> get props => [
        id,
        isMerchant,
        firstName,
        lastName,
        email,
        dialingCode,
        mobileNumber,
        roles,
        stores,
        outStores,
        businessName,
        image,
      ];
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String accessSchema;
  final int? accessExp;
  final String? refreshToken;
  final String refreshSchema;

  const AuthTokens({
    required this.accessToken,
    this.accessSchema = 'Bearer',
    this.accessExp,
    this.refreshToken,
    this.refreshSchema = 'Bearer',
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    String accessToken = '';
    String accessSchema = 'Bearer';
    int? accessExp;
    String? refreshToken;
    String refreshSchema = 'Bearer';

    if (json['access'] is Map<String, dynamic>) {
      accessToken = json['access']['token'] as String? ?? '';
      accessSchema = json['access']['schema'] as String? ?? 'Bearer';
      accessExp = (json['access']['exp'] as num?)?.toInt();
    } else if (json['access'] is String) {
      accessToken = json['access'] as String;
    }

    if (json['refresh'] is Map<String, dynamic>) {
      refreshToken = json['refresh']['token'] as String?;
      refreshSchema = json['refresh']['schema'] as String? ?? 'Bearer';
    } else if (json['refresh'] is String) {
      refreshToken = json['refresh'] as String;
    }

    return AuthTokens(
      accessToken: accessToken,
      accessSchema: accessSchema,
      accessExp: accessExp,
      refreshToken: refreshToken,
      refreshSchema: refreshSchema,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': {
        'token': accessToken,
        'schema': accessSchema,
        'exp': accessExp,
      },
      'refresh': {
        'token': refreshToken,
        'schema': refreshSchema,
      },
    };
  }

  @override
  List<Object?> get props => [
        accessToken,
        accessSchema,
        accessExp,
        refreshToken,
        refreshSchema,
      ];
}

class LoginResponse extends Equatable {
  final bool success;
  final String message;
  final MerchantProfile? profile;
  final AuthTokens tokens;
  final Map<String, dynamic>? privileges;

  const LoginResponse({
    required this.success,
    required this.message,
    this.profile,
    required this.tokens,
    this.privileges,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? true;
    final message = json['message'] as String? ?? '';
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    MerchantProfile? profile;
    if (data['merchant_profile'] is Map<String, dynamic>) {
      profile = MerchantProfile.fromJson(
        data['merchant_profile'] as Map<String, dynamic>,
      );
    }

    AuthTokens tokens = const AuthTokens(accessToken: '');
    if (data['auth_token'] is Map<String, dynamic>) {
      tokens = AuthTokens.fromJson(data['auth_token'] as Map<String, dynamic>);
    } else if (data['token'] != null) {
      tokens = AuthTokens(accessToken: data['token'].toString());
    }

    final privileges = data['privileges'] is Map<String, dynamic>
        ? data['privileges'] as Map<String, dynamic>
        : null;

    return LoginResponse(
      success: success,
      message: message,
      profile: profile,
      tokens: tokens,
      privileges: privileges,
    );
  }

  @override
  List<Object?> get props => [success, message, profile, tokens, privileges];
}
