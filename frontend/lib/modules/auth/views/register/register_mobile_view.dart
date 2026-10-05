import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers/t_snackbar_helper.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../auth_validators.dart';
import '../../bloc/register/register_bloc.dart';
import '../../bloc/register/register_event.dart';
import '../../bloc/register/register_state.dart';
import '../../widgets/auth_primitives.dart';
import '../../widgets/auth_text_field.dart';

class RegisterMobileView extends StatefulWidget {
  const RegisterMobileView({super.key});

  @override
  State<RegisterMobileView> createState() => _RegisterMobileViewState();
}

class _RegisterMobileViewState extends State<RegisterMobileView> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          context.go('/verify-email?email=${Uri.encodeComponent(_email.text)}');
        }
      },
      builder: (context, state) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFFFCF7),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 24.0
                  : 20.0;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SizedBox(
                      width: double.infinity,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Quay lại',
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                    onPressed: () => context.go('/welcome'),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Đăng ký',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tạo tài khoản ReStore',
                              style: TextStyle(
                                fontSize: 27,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Một tài khoản cho cả mua và bán.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 26),
                            AuthTextField(
                              label: 'Họ và tên',
                              hintText: 'Tên của bạn',
                              borderRadius: 14,
                              controller: _fullName,
                              validator: AuthValidators.fullName,
                              autofillHints: const [AutofillHints.name],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              label: 'Tên người dùng',
                              hintText: 'vd: minh_restore',
                              borderRadius: 14,
                              controller: _username,
                              validator: AuthValidators.username,
                              autofillHints: const [AutofillHints.newUsername],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              label: 'Email',
                              hintText: 'email@example.com',
                              borderRadius: 14,
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              validator: AuthValidators.email,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              label: 'Mật khẩu',
                              hintText: 'Tối thiểu 8 ký tự',
                              borderRadius: 14,
                              controller: _password,
                              obscureText: true,
                              validator: AuthValidators.password,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              label: 'Xác nhận mật khẩu',
                              hintText: 'Nhập lại mật khẩu',
                              borderRadius: 14,
                              controller: _confirmation,
                              obscureText: true,
                              validator: (value) => AuthValidators.confirmation(
                                value,
                                _password.text,
                              ),
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 14),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 42),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _acceptedTerms,
                                      activeColor: AppColors.primary,
                                      checkColor: AppColors.textPrimary,
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _acceptedTerms = value ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Tôi đồng ý '),
                                          TextSpan(
                                            text: 'Điều khoản',
                                            style: TextStyle(
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                          const TextSpan(text: ' và '),
                                          TextSpan(
                                            text: 'Chính sách riêng tư',
                                            style: TextStyle(
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (state is RegisterFailure) ...[
                              const SizedBox(height: 10),
                              AuthFeedback(message: state.error),
                            ],
                            const SizedBox(height: 12),
                            AppButton(
                              label: state is RegisterLoading
                                  ? 'Đang xử lý…'
                                  : 'Đăng ký',
                              isLoading: state is RegisterLoading,
                              height: 52,
                              borderRadius: 28,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 15),
                            const AuthDivider(),
                            const SizedBox(height: 15),
                            AuthGoogleButton(
                              borderRadius: 28,
                              height: 52,
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đăng ký bằng Google chưa được hỗ trợ.',
                                      ),
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Đã có tài khoản?',
                                  style: TextStyle(fontSize: 12),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.only(left: 8),
                                    minimumSize: const Size(0, 24),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      TSnackBarHelper.showWarning(
        context,
        message: 'Bạn cần đồng ý với điều khoản để tiếp tục.',
      );
      return;
    }
    context.read<RegisterBloc>().add(
      SubmitRegisterEvent(
        fullName: _fullName.text,
        username: _username.text,
        email: _email.text,
        password: _password.text,
      ),
    );
  }
}
