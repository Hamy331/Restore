import assert from 'node:assert/strict';
import test from 'node:test';
import type { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { parse } from '../../common/validation/schemas.js';
import { emailBody, loginBody, otpBody, refreshTokenBody, registerBody, resetPasswordBody } from './auth.validator.js';

function outcome(run: () => unknown) {
  try {
    return { ok: run() };
  } catch (error) {
    assert.ok(error instanceof AppError, `expected AppError, got ${String(error)}`);
    return { error: { statusCode: error.statusCode, code: error.code, message: error.message, field: error.field } };
  }
}

/**
 * Kết quả mong đợi, ghi lại từ auth.validation.ts cũ (controller gọi parseX(req.body?.x) theo thứ tự)
 * trước khi chuyển sang zod ở C22: đúng mã lỗi 422, đúng trường, đúng thứ tự kiểm tra.
 */
const EXPECTED: Record<string, [unknown, unknown][]> = {

  login: [
    [undefined, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    ["x", { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{  }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": " A@B.co ", "password": "" }, { "error": { "statusCode": 422, "code": "PASSWORD_REQUIRED", "message": "Vui lòng nhập mật khẩu.", "field": "password" } }],
    [{ "email": "bad", "password": "x" }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": "a@b.co", "password": "x" }, { "ok": { "email": "a@b.co", "password": "x" } }],
    [{ "email": "a@b.co" }, { "error": { "statusCode": 422, "code": "PASSWORD_REQUIRED", "message": "Vui lòng nhập mật khẩu.", "field": "password" } }],
  ],
  register: [
    [{  }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": "a@b.co", "password": "weak" }, { "error": { "statusCode": 422, "code": "WEAK_PASSWORD", "message": "Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.", "field": "password" } }],
    [{ "email": "a@b.co", "password": "Strong123" }, { "error": { "statusCode": 422, "code": "INVALID_USERNAME", "message": "Tên người dùng phải có 3-30 ký tự và chỉ gồm chữ thường, số, dấu chấm hoặc gạch dưới.", "field": "username" } }],
    [{ "email": "a@b.co", "password": "Strong123", "username": "Ab_c.1" }, { "error": { "statusCode": 422, "code": "INVALID_FULL_NAME", "message": "Họ tên phải có từ 2 đến 80 ký tự.", "field": "fullName" } }],
    [{ "email": "a@b.co", "password": "Strong123", "username": "abc", "fullName": " A " }, { "error": { "statusCode": 422, "code": "INVALID_FULL_NAME", "message": "Họ tên phải có từ 2 đến 80 ký tự.", "field": "fullName" } }],
    [{ "email": "A@B.CO", "password": "Strong123", "username": "User.Name", "fullName": "  Nguyễn   Văn  A " }, { "ok": { "email": "a@b.co", "password": "Strong123", "username": "user.name", "fullName": "Nguyễn Văn A" } }],
    [{ "email": "x@y.z", "password": "Aa1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "username": "abc", "fullName": "An" }, { "error": { "statusCode": 422, "code": "WEAK_PASSWORD", "message": "Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.", "field": "password" } }],
  ],
  otp: [
    [{  }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": "a@b.co" }, { "error": { "statusCode": 422, "code": "INVALID_OTP_FORMAT", "message": "Mã OTP phải gồm đúng 6 chữ số.", "field": "otp" } }],
    [{ "email": "a@b.co", "otp": "12345" }, { "error": { "statusCode": 422, "code": "INVALID_OTP_FORMAT", "message": "Mã OTP phải gồm đúng 6 chữ số.", "field": "otp" } }],
    [{ "email": "a@b.co", "otp": " 123456 " }, { "ok": { "email": "a@b.co", "otp": "123456" } }],
    [{ "email": "a@b.co", "otp": 123456 }, { "error": { "statusCode": 422, "code": "INVALID_OTP_FORMAT", "message": "Mã OTP phải gồm đúng 6 chữ số.", "field": "otp" } }],
  ],
  reset: [
    [{  }, { "error": { "statusCode": 422, "code": "TOKEN_REQUIRED", "message": "Phiên xác thực không hợp lệ.", "field": "resetToken" } }],
    [{ "resetToken": " t " }, { "error": { "statusCode": 422, "code": "WEAK_PASSWORD", "message": "Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.", "field": "newPassword" } }],
    [{ "resetToken": "t", "newPassword": "weakpass" }, { "error": { "statusCode": 422, "code": "WEAK_PASSWORD", "message": "Mật khẩu phải có 8-72 ký tự, gồm chữ hoa, chữ thường và chữ số.", "field": "newPassword" } }],
    [{ "resetToken": "t", "newPassword": "Strong123" }, { "ok": { "resetToken": "t", "newPassword": "Strong123" } }],
  ],
  refresh: [
    [undefined, { "error": { "statusCode": 422, "code": "TOKEN_REQUIRED", "message": "Phiên xác thực không hợp lệ.", "field": "refreshToken" } }],
    [{  }, { "error": { "statusCode": 422, "code": "TOKEN_REQUIRED", "message": "Phiên xác thực không hợp lệ.", "field": "refreshToken" } }],
    [{ "refreshToken": "" }, { "error": { "statusCode": 422, "code": "TOKEN_REQUIRED", "message": "Phiên xác thực không hợp lệ.", "field": "refreshToken" } }],
    [{ "refreshToken": " r " }, { "ok": { "refreshToken": "r" } }],
    [{ "refreshToken": 5 }, { "error": { "statusCode": 422, "code": "TOKEN_REQUIRED", "message": "Phiên xác thực không hợp lệ.", "field": "refreshToken" } }],
  ],
  email: [
    [{  }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": "a@b" }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": " aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@b.co" }, { "error": { "statusCode": 422, "code": "INVALID_EMAIL", "message": "Email chưa đúng định dạng.", "field": "email" } }],
    [{ "email": "Me@Mail.VN" }, { "ok": { "email": "me@mail.vn" } }],
  ],
};

function check(cases: [unknown, unknown][], schema: z.ZodType) {
  for (const [input, expected] of cases) {
    assert.deepEqual(outcome(() => parse(schema, input)), expected, `input: ${JSON.stringify(input)}`);
  }
}

test('login body', () => check(EXPECTED.login, loginBody));
test('register body checks email, password, username, fullName in order', () => check(EXPECTED.register, registerBody));
test('otp body', () => check(EXPECTED.otp, otpBody));
test('reset password body', () => check(EXPECTED.reset, resetPasswordBody));
test('refresh / logout body', () => check(EXPECTED.refresh, refreshTokenBody));
test('email body', () => check(EXPECTED.email, emailBody));
