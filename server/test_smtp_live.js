const nodemailer = require('./node_modules/nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: { user: 'b75126964@gmail.com', pass: 'bucymvqwsdazcofc' },
  tls: { rejectUnauthorized: false },
  connectionTimeout: 15000,
  greetingTimeout: 15000,
  socketTimeout: 15000,
});

const otp = Math.floor(100000 + Math.random() * 900000);

transporter.verify()
  .then(() => {
    console.log('SMTP_OK - credentials accepted by Gmail');
    return transporter.sendMail({
      from: 'ENX Money <b75126964@gmail.com>',
      to: 'b75126964@gmail.com',
      subject: '[ENX Money LIVE TEST] OTP: ' + otp,
      text: 'Your test OTP is: ' + otp + '\nSent at: ' + new Date().toISOString(),
    });
  })
  .then((r) => {
    console.log('EMAIL_SENT MessageID=' + r.messageId + ' Response=' + r.response);
    process.exit(0);
  })
  .catch((e) => {
    console.error('SMTP_FAILED ' + e.message);
    process.exit(1);
  });
