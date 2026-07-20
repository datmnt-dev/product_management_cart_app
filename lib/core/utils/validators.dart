class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label.';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, 'email');
    if (required != null) {
      return required;
    }

    final email = value!.trim();
    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!isValid) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  static String? password(String? value) {
    final required = requiredText(value, 'mật khẩu');
    if (required != null) {
      return required;
    }

    if (value!.length < 6) {
      return 'Mật khẩu cần ít nhất 6 ký tự.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final validation = Validators.password(value);
    if (validation != null) {
      return validation;
    }

    if (value != password) {
      return 'Mật khẩu xác nhận chưa khớp.';
    }
    return null;
  }

  static String? positivePrice(String? value) {
    final required = requiredText(value, 'giá sản phẩm');
    if (required != null) {
      return required;
    }

    final normalized = value!.replaceAll(',', '.');
    final price = double.tryParse(normalized);
    if (price == null || price <= 0) {
      return 'Giá phải là số lớn hơn 0.';
    }
    return null;
  }
}
