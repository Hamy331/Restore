import { Resend } from 'resend';
import { ensureVerifiedEmailSender, getRequiredEnv } from '../config/env.js';
import { AppError, isAppError } from '../errors/app-error.js';

type OtpPurpose = 'register' | 'forgot-password';

export const sendOtpEmail = async (to: string, otp: string, purpose: OtpPurpose = 'register') => {
  const apiKey = getRequiredEnv('RESEND_API_KEY');
  const fromEmail = ensureVerifiedEmailSender(to);
  const resend = new Resend(apiKey);

  const templates: Record<OtpPurpose, { subject: string; heading: string; body: string; note: string }> = {
    'register': {
      subject: 'Xác minh tài khoản - ReStore',
      heading: 'Xác minh tài khoản',
      body: 'Cảm ơn bạn đã đăng ký tài khoản ReStore. Vui lòng nhập mã OTP bên dưới để xác minh email của bạn:',
      note: 'Nếu bạn không đăng ký tài khoản ReStore, vui lòng bỏ qua email này.',
    },
    'forgot-password': {
      subject: 'Đặt lại mật khẩu - ReStore',
      heading: 'Đặt lại mật khẩu',
      body: 'Bạn đã yêu cầu đặt lại mật khẩu cho tài khoản ReStore. Dưới đây là mã OTP của bạn:',
      note: 'Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.',
    },
  };

  const t = templates[purpose];

  try {
    const { data, error } = await resend.emails.send({
      from: `ReStore <${fromEmail}>`,
      to: [to],
      subject: t.subject,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
          <h2 style="color: #1E3A8A; text-align: center;">${t.heading}</h2>
          <p style="font-size: 16px; color: #333;">Chào bạn,</p>
          <p style="font-size: 16px; color: #333;">${t.body}</p>
          <div style="text-align: center; margin: 30px 0;">
            <span style="display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1E3A8A; background-color: #F3F4F6; padding: 10px 20px; border-radius: 8px;">${otp}</span>
          </div>
          <p style="font-size: 16px; color: #333;">Mã OTP này sẽ hết hạn trong <strong>5 phút</strong>.</p>
          <p style="font-size: 14px; color: #666; margin-top: 30px;">${t.note}</p>
          <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 20px 0;">
          <p style="font-size: 12px; color: #999; text-align: center;">© 2026 ReStore. All rights reserved.</p>
        </div>
      `,
    });

    if (error) {
      console.error('[Resend] OTP delivery failed:', { name: error.name, message: error.message });
      throw new AppError(503, 'EMAIL_DELIVERY_FAILED', 'Không thể gửi email lúc này. Vui lòng thử lại sau.');
    }

    console.info('[Resend] OTP delivered:', { messageId: data?.id });
  } catch (error: unknown) {
    if (isAppError(error)) throw error;
    console.error('[Resend] Unexpected OTP delivery error:', error);
    throw new AppError(503, 'EMAIL_DELIVERY_FAILED', 'Không thể gửi email lúc này. Vui lòng thử lại sau.');
  }
};
