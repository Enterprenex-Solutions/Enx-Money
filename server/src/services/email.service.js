const { getTransporter } = require('../config/mailer.config');
const config = require('../config/env.config');

class EmailService {
  /**
   * Send OTP Verification Email
   */
  static async sendOtpEmail({ email, otp, expiryMinutes = 5 }) {
    const transporter = getTransporter();

    const subject = `Your ENX Money Verification Code: ${otp}`;
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>ENX Money Verification</title>
        <style>
          body { margin: 0; padding: 0; background-color: #090B0E; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF; }
          .container { max-width: 520px; margin: 40px auto; background: #12161F; border: 1px solid #1E293B; border-radius: 16px; overflow: hidden; }
          .header { background: #0E121B; padding: 32px 24px; text-align: center; border-bottom: 1px solid #1E293B; }
          .brand-logo { display: inline-block; width: 44px; height: 44px; line-height: 44px; border-radius: 50%; background: linear-gradient(135deg, #00E599, #05D686); color: #090B0E; font-weight: 900; font-size: 16px; margin-bottom: 12px; }
          .brand-title { font-size: 18px; font-weight: 800; letter-spacing: 2px; color: #FFFFFF; margin: 0; }
          .content { padding: 36px 32px; text-align: center; }
          .title { font-size: 22px; font-weight: 700; margin: 0 0 12px 0; color: #FFFFFF; }
          .subtitle { font-size: 14px; color: #94A3B8; margin: 0 0 28px 0; line-height: 1.5; }
          .otp-card { background: #1A1F2C; border: 1px solid #00E599; border-radius: 12px; padding: 20px; margin: 0 auto 28px auto; max-width: 280px; box-shadow: 0 0 24px rgba(0, 229, 153, 0.15); }
          .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #00E599; margin: 0; }
          .expiry-note { font-size: 13px; color: #64748B; margin: 0 0 20px 0; }
          .security-banner { background: #0E121B; border-radius: 8px; padding: 14px; margin: 24px 0 0 0; text-align: left; border: 1px solid #1E293B; }
          .security-text { font-size: 12px; color: #94A3B8; margin: 0; line-height: 1.5; }
          .footer { background: #0E121B; padding: 20px 24px; text-align: center; font-size: 12px; color: #475569; border-top: 1px solid #1E293B; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="brand-logo">EN</div>
            <h1 class="brand-title">ENX MONEY</h1>
          </div>
          <div class="content">
            <h2 class="title">Security Verification Code</h2>
            <p class="subtitle">Use the verification code below to log in or register for your ENX Money account.</p>
            <div class="otp-card">
              <div class="otp-code">${otp}</div>
            </div>
            <p class="expiry-note">⏱️ This code will expire in <strong>${expiryMinutes} minutes</strong>.</p>
            <div class="security-banner">
              <p class="security-text">🔒 <strong>Security Warning:</strong> Never share this OTP with anyone, including ENX Money support representatives. Our team will never ask for your code.</p>
            </div>
          </div>
          <div class="footer">
            &copy; ${new Date().getFullYear()} Enterprenex Solutions Pvt. Ltd. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `Your ENX Money verification code is: ${otp}. It will expire in ${expiryMinutes} minutes. Do not share this code with anyone.`;

    const mailOptions = {
      from: config.SMTP.FROM,
      to: email,
      subject,
      text,
      html,
    };

    return transporter.sendMail(mailOptions);
  }

  /**
   * Send EMI Due & Overdue Notification Email
   */
  static async sendEmiReminderEmail({
    email,
    name = 'Valued Customer',
    loanType,
    lenderName,
    installmentNumber,
    emiAmount,
    dueDate,
    daysRemaining,
    isOverdue = false,
    lateFee = 0.0,
    totalPayable,
  }) {
    const transporter = getTransporter();
    const formattedEmi = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(emiAmount);
    const formattedTotal = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(totalPayable || emiAmount);
    const formattedLateFee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(lateFee || 0);

    const subject = isOverdue
      ? `🚨 OVERDUE ALERT: EMI for your ${loanType} Loan is past due`
      : `📅 Reminder: EMI of ${formattedEmi} due on ${dueDate}`;

    const statusBannerColor = isOverdue ? '#FF4D6D' : '#00E599';
    const statusTitle = isOverdue ? 'Overdue EMI Alert' : 'Upcoming EMI Due Reminder';
    const statusSubtitle = isOverdue
      ? `Your installment #${installmentNumber} for ${lenderName || loanType} is past due by ${Math.abs(daysRemaining)} days.`
      : `Your installment #${installmentNumber} for ${lenderName || loanType} is due in ${daysRemaining === 0 ? 'today' : `${daysRemaining} days`}.`;

    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>
          body { margin: 0; padding: 0; background-color: #090B0E; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #FFFFFF; }
          .container { max-width: 540px; margin: 30px auto; background: #12161F; border: 1px solid #1E293B; border-radius: 16px; overflow: hidden; }
          .header { background: #0E121B; padding: 24px; text-align: center; border-bottom: 1px solid #1E293B; }
          .brand-title { font-size: 16px; font-weight: 800; letter-spacing: 2px; color: #FFFFFF; margin: 0; }
          .content { padding: 32px 28px; }
          .status-badge { display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 12px; font-weight: 700; background: ${statusBannerColor}20; color: ${statusBannerColor}; border: 1px solid ${statusBannerColor}40; margin-bottom: 16px; }
          .title { font-size: 22px; font-weight: 700; margin: 0 0 8px 0; color: #FFFFFF; }
          .subtitle { font-size: 14px; color: #94A3B8; margin: 0 0 24px 0; line-height: 1.5; }
          .card { background: #1A1F2C; border: 1px solid #1E293B; border-radius: 12px; padding: 20px; margin-bottom: 24px; }
          .row { display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 14px; }
          .label { color: #94A3B8; }
          .value { font-weight: 700; color: #FFFFFF; }
          .divider { height: 1px; background: #1E293B; margin: 14px 0; }
          .total-value { font-size: 20px; font-weight: 800; color: ${statusBannerColor}; }
          .footer { background: #0E121B; padding: 18px 24px; text-align: center; font-size: 12px; color: #475569; border-top: 1px solid #1E293B; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="brand-title">ENX MONEY</h1>
          </div>
          <div class="content">
            <span class="status-badge">${isOverdue ? 'ACTION REQUIRED' : 'PAYMENT REMINDER'}</span>
            <h2 class="title">${statusTitle}</h2>
            <p class="subtitle">Dear ${name}, ${statusSubtitle}</p>
            
            <div class="card">
              <div class="row"><span class="label">Loan Type</span><span class="value">${loanType} Loan</span></div>
              <div class="row"><span class="label">Lender</span><span class="value">${lenderName || 'ENX Money'}</span></div>
              <div class="row"><span class="label">Installment #</span><span class="value">#${installmentNumber}</span></div>
              <div class="row"><span class="label">Due Date</span><span class="value">${dueDate}</span></div>
              <div class="row"><span class="label">Original EMI</span><span class="value">${formattedEmi}</span></div>
              ${isOverdue && lateFee > 0 ? `<div class="row"><span class="label" style="color:#FF4D6D;">Late Fee Penalty</span><span class="value" style="color:#FF4D6D;">+ ${formattedLateFee}</span></div>` : ''}
              <div class="divider"></div>
              <div class="row"><span class="label" style="font-weight:700;">Total Payable</span><span class="total-value">${formattedTotal}</span></div>
            </div>

            <p style="font-size:13px; color:#94A3B8; text-align:center;">Open your ENX Money app to make a quick one-tap payment and avoid credit score impact.</p>
          </div>
          <div class="footer">
            &copy; ${new Date().getFullYear()} Enterprenex Solutions Pvt. Ltd. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;

    const text = isOverdue
      ? `OVERDUE ALERT: Installment #${installmentNumber} of ${formattedTotal} for your ${loanType} loan was due on ${dueDate}. Please settle immediately.`
      : `REMINDER: Installment #${installmentNumber} of ${formattedEmi} for your ${loanType} loan is due on ${dueDate}.`;

    const mailOptions = {
      from: config.SMTP.FROM,
      to: email,
      subject,
      text,
      html,
    };

    return transporter.sendMail(mailOptions);
  }

  /**
   * Send Customer Khata / Invoice Payment Reminder Email
   */
  static async sendCustomerPaymentReminder({
    email,
    customerName,
    businessName = 'Krishna Textiles & Supplies',
    amountDue,
    phone,
    invoiceNumber = 'INV/2026-27/0001',
  }) {
    const transporter = getTransporter();
    const formattedAmount = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(amountDue);

    const subject = `Payment Reminder from ${businessName} — Outstanding Balance: ${formattedAmount}`;
    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <style>
          body { margin: 0; padding: 0; background-color: #080A0F; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #FFFFFF; }
          .container { max-width: 520px; margin: 30px auto; background: #121724; border: 1px solid #1E273A; border-radius: 16px; overflow: hidden; }
          .header { background: #10141F; padding: 24px; text-align: center; border-bottom: 1px solid #1E273A; }
          .brand-title { font-size: 18px; font-weight: 800; color: #00E676; margin: 0; }
          .content { padding: 32px 24px; text-align: center; }
          .amount-box { background: #161D2C; border: 1px solid rgba(255, 71, 87, 0.4); border-radius: 12px; padding: 20px; margin: 20px 0; }
          .amount-val { font-size: 32px; font-weight: 900; color: #FF4757; }
          .footer { background: #10141F; padding: 16px; text-align: center; font-size: 12px; color: #8E9DB5; border-top: 1px solid #1E273A; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="brand-title">${businessName}</h1>
          </div>
          <div class="content">
            <h2 style="font-size:20px; font-weight:700; margin:0 0 10px 0;">Payment Reminder</h2>
            <p style="color:#8E9DB5; font-size:14px; margin:0 0 20px 0;">Dear <strong>${customerName}</strong>, this is a gentle reminder regarding your outstanding payment.</p>
            <div class="amount-box">
              <div style="font-size:12px; color:#8E9DB5; font-weight:700; text-transform:uppercase; margin-bottom:6px;">TOTAL AMOUNT DUE</div>
              <div class="amount-val">${formattedAmount}</div>
            </div>
            <p style="font-size:13px; color:#8E9DB5; line-height:1.5;">Please arrange to settle this payment via UPI or Bank Transfer at your earliest convenience.<br>Thank you for your business!</p>
          </div>
          <div class="footer">
            Sent securely via <strong>ENX Money Business Suite</strong>
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `Dear ${customerName}, this is a gentle payment reminder from ${businessName} regarding your outstanding balance of ${formattedAmount}. Kindly arrange payment at your earliest convenience. Thank you.`;

    if (email) {
      return transporter.sendMail({
        from: config.SMTP.FROM,
        to: email,
        subject,
        text,
        html,
      }).catch(err => {
        console.error('[Mailer Warning] Failed to dispatch reminder email:', err.message);
      });
    }
    return { success: true };
  }

  /**
   * Send Device Login Approval Alert Email
   */
  static async sendDeviceApprovalAlertEmail({ email, deviceName, platform, ipAddress, verificationCode, time }) {
    const transporter = getTransporter();
    const subject = `⚠️ Security Alert: New Device Login Attempt for ENX Money`;
    const formattedTime = time || new Date().toUTCString();

    const html = `
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>New Device Login Alert</title>
        <style>
          body { margin: 0; padding: 0; background-color: #F8FAFC; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #0F172A; }
          .container { max-width: 520px; margin: 40px auto; background: #FFFFFF; border: 1px solid #E2E8F0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
          .header { background: #0A1931; padding: 28px 24px; text-align: center; }
          .brand-title { font-size: 20px; font-weight: 800; letter-spacing: 2px; color: #FFFFFF; margin: 0; }
          .content { padding: 32px 28px; }
          .alert-badge { display: inline-block; background: #FEF3C7; color: #D97706; padding: 6px 12px; border-radius: 20px; font-weight: 700; font-size: 12px; margin-bottom: 16px; }
          .title { font-size: 20px; font-weight: 800; color: #0A1931; margin: 0 0 10px 0; }
          .desc { font-size: 14px; color: #475569; line-height: 1.5; margin: 0 0 20px 0; }
          .device-card { background: #F1F5F9; border-radius: 12px; padding: 18px; margin-bottom: 24px; }
          .device-row { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 8px; }
          .device-label { color: #64748B; font-weight: 600; }
          .device-value { color: #0A1931; font-weight: 700; }
          .pin-box { background: #EFF6FF; border: 1.5px dashed #0066FF; border-radius: 12px; padding: 16px; text-align: center; margin-bottom: 24px; }
          .pin-label { font-size: 11px; font-weight: 800; letter-spacing: 1px; color: #0066FF; text-transform: uppercase; margin-bottom: 6px; }
          .pin-code { font-family: monospace; font-size: 28px; font-weight: 800; letter-spacing: 6px; color: #0066FF; }
          .footer { background: #F8FAFC; padding: 20px 24px; text-align: center; font-size: 12px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="brand-title">ENX MONEY</h1>
          </div>
          <div class="content">
            <div class="alert-badge">⚠️ NEW DEVICE DETECTED</div>
            <h2 class="title">Action Required: Login Approval</h2>
            <p class="desc">A new device is attempting to log into your ENX Money account. If this was you, approve the request directly in your primary mobile app.</p>
            
            <div class="device-card">
              <div class="device-row"><span class="device-label">Device Name:</span> <span class="device-value">${deviceName || 'Unknown Device'}</span></div>
              <div class="device-row"><span class="device-label">Platform:</span> <span class="device-value">${platform || 'Mobile'}</span></div>
              <div class="device-row"><span class="device-label">IP Address:</span> <span class="device-value">${ipAddress || 'Unknown'}</span></div>
              <div class="device-row" style="margin-bottom:0;"><span class="device-label">Time:</span> <span class="device-value">${formattedTime}</span></div>
            </div>

            <div class="pin-box">
              <div class="pin-label">Verification Code</div>
              <div class="pin-code">${verificationCode || '----'}</div>
            </div>

            <p style="font-size: 13px; color: #DC2626; line-height: 1.4; margin: 0;"><strong>Did not request this?</strong> Do not approve. Open ENX Money on your primary device, deny the request, and change your password immediately.</p>
          </div>
          <div class="footer">
            &copy; ${new Date().getFullYear()} Enterprenex Solutions Pvt. Ltd. • Multi-Device Security
          </div>
        </div>
      </body>
      </html>
    `;

    const text = `Security Alert: A new device (${deviceName} - ${platform}, IP: ${ipAddress}) is attempting to log in to your ENX Money account at ${formattedTime}. Verification Code: ${verificationCode}. If this wasn't you, deny access immediately.`;

    if (email) {
      return transporter.sendMail({
        from: config.SMTP.FROM,
        to: email,
        subject,
        text,
        html,
      }).catch(err => {
        console.error('[Mailer Warning] Failed to dispatch device alert email:', err.message);
      });
    }
    return { success: true };
  }
}

module.exports = EmailService;
