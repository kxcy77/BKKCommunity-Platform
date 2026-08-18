import nodemailer from 'nodemailer'
import { config } from '../config'

interface SendResetEmailOptions {
  to: string
  code: string
}

let transporter: nodemailer.Transporter | null = null

async function getTransporter(): Promise<nodemailer.Transporter> {
  if (transporter) return transporter

  const host = config.SMTP_HOST
  const port = config.SMTP_PORT
  const user = config.SMTP_USER
  const pass = config.SMTP_PASS
  const from = config.FROM_EMAIL

  if (!host || !user || !pass || !from) {
    throw new Error('Password-reset email is not configured. Set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS and FROM_EMAIL.')
  }

  transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  })
  // Fail before issuing a usable code if the configured SMTP server cannot be reached.
  await transporter.verify()
  console.log('[EMAIL SERVICE] SMTP transport verified.')

  return transporter
}

export async function sendPasswordResetEmail({ to, code }: SendResetEmailOptions): Promise<void> {
    const transport = await getTransporter()
    const fromAddress = config.FROM_EMAIL!

    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>BKK Community Password Reset</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f6f8; margin: 0; padding: 20px; color: #1e293b; }
        .card { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }
        .header { text-align: center; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9; }
        .logo { font-size: 24px; font-weight: bold; color: #1e3a8a; }
        .sublogo { font-size: 13px; color: #64748b; margin-top: 4px; }
        .content { padding: 24px 0; }
        .title { font-size: 18px; font-weight: 600; color: #0f172a; margin-bottom: 12px; }
        .text { font-size: 15px; color: #334155; line-height: 1.6; margin-bottom: 24px; }
        .code-box { background-color: #f0fdf4; border: 2px dashed #16a34a; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }
        .code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #15803d; font-family: monospace; }
        .notice { font-size: 13px; color: #64748b; text-align: center; margin-top: 8px; }
        .footer { text-align: center; margin-top: 32px; padding-top: 20px; border-top: 1px solid #f1f5f9; font-size: 12px; color: #94a3b8; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <div class="logo">BKK Community</div>
          <div class="sublogo">Senior Community Platform</div>
        </div>
        <div class="content">
          <div class="title">Password Reset Request</div>
          <div class="text">
            We received a request to reset the password for your BKK Community account. Please use the 6-digit reset code below:
          </div>
          <div class="code-box">
            <div class="code">${code}</div>
            <div class="notice">This code expires in 15 minutes.</div>
          </div>
          <div class="text">
            Enter this 6-digit code on the reset password screen along with your new password to complete your password update.
          </div>
          <div class="text" style="font-size: 13px; color: #64748b;">
            If you did not request a password reset, you can safely ignore this email.
          </div>
        </div>
        <div class="footer">
          &copy; ${new Date().getFullYear()} BKK Community • Helpline: 072 888 5030
        </div>
      </div>
    </body>
    </html>
    `

    const info = await transport.sendMail({
      from: fromAddress,
      to,
      subject: 'Your BKK Community password reset request',
      text: `Your BKK Community password reset code is: ${code}. It expires in 15 minutes.`,
      html: htmlContent,
    })

    if (info.rejected.length > 0) {
      throw new Error('The mail server rejected the password-reset email.')
    }

    // Do not log email addresses, reset codes, or provider message identifiers.
    console.log('[EMAIL SERVICE] Password-reset email accepted by SMTP transport.')
}
