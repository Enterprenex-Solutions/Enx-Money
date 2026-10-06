/**
 * ENX Money — Razorpay Standard Payment Controller
 * Implements:
 * 1. POST /api/create-order (amount >= 100 paise, currency, receipt)
 * 2. POST /api/verify-payment (HMAC-SHA256 signature verification)
 */
const crypto = require('crypto');
const razorpayService = require('../services/razorpay.service');

/**
 * STEP 1: BACKEND - Create Order
 * Endpoint: POST /api/create-order
 * Request: { amount (paise), currency, receipt }
 * Return: { order_id, amount, currency, key_id }
 * Minimum amount: 100 paise
 */
exports.createOrder = async (req, res) => {
  try {
    let { amount, currency = 'INR', receipt, notes = {} } = req.body;

    // Validate amount
    if (amount === undefined || amount === null || isNaN(Number(amount))) {
      return res.status(400).json({
        success: false,
        error: 'Amount is required and must be a valid number in paise',
      });
    }

    amount = parseInt(amount, 10);

    // Minimum amount: 100 paise (₹1.00)
    if (amount < 100) {
      return res.status(400).json({
        success: false,
        error: 'Amount must be at least 100 paise (₹1.00)',
        min_amount_paise: 100,
      });
    }

    const receiptId = receipt || `rcpt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const rzp = razorpayService.getRazorpayInstance();
    const keyId = razorpayService.getKeyId();

    const { SETTLEMENT_CONFIG } = require('../config/settlement.config');
    const vpa = SETTLEMENT_CONFIG.MERCHANT_UPI_VPA || '8767443493@jiopay';
    const payeeName = SETTLEMENT_CONFIG.BENEFICIARY_NAME || 'Rohit Samadhan Pawar';
    const amountRupees = (amount / 100).toFixed(2);
    const note = notes?.customer_name ? `ENX Money - ${notes.customer_name}` : 'ENX Money Subscription';

    if (!rzp) {
      // If running without live keys, use simulated order
      const simOrder = await razorpayService.createOrder(amount, currency, receiptId, notes);
      const upiIntentUrl = `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(payeeName)}&am=${amountRupees}&cu=INR&tn=${encodeURIComponent(note)}&tr=${simOrder.id}`;
      return res.status(200).json({
        success: true,
        order_id: simOrder.id,
        amount: simOrder.amount,
        currency: simOrder.currency,
        key_id: keyId || 'rzp_live_ThjlhbHvQ4iaQV',
        upi_intent_url: upiIntentUrl,
        upi_qr_data: upiIntentUrl,
        upi_vpa: vpa,
        merchant_upi_link: SETTLEMENT_CONFIG.MERCHANT_UPI_LINK,
        payment_link: SETTLEMENT_CONFIG.MERCHANT_UPI_LINK,
        _simulated: true,
      });
    }

    try {
      const order = await rzp.orders.create({
        amount,
        currency,
        receipt: receiptId,
        payment_capture: 1,
        notes: {
          app: 'ENX Money',
          ...notes,
        },
      });

      const upiIntentUrl = `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(payeeName)}&am=${amountRupees}&cu=INR&tn=${encodeURIComponent(note)}&tr=${order.id}`;

      return res.status(200).json({
        success: true,
        order_id: order.id,
        amount: order.amount,
        currency: order.currency,
        key_id: keyId,
        upi_intent_url: upiIntentUrl,
        upi_qr_data: upiIntentUrl,
        upi_vpa: vpa,
        merchant_upi_link: SETTLEMENT_CONFIG.MERCHANT_UPI_LINK,
        payment_link: SETTLEMENT_CONFIG.MERCHANT_UPI_LINK,
      });
    } catch (rzpErr) {
      console.error('[Razorpay createOrder] API error:', rzpErr);
      const statusCode = rzpErr.statusCode || (rzpErr.error && rzpErr.error.code === 'BAD_REQUEST_ERROR' ? 400 : 500);
      
      // Handle auth failure
      if (statusCode === 401 || (rzpErr.error && rzpErr.error.code === 'AUTHENTICATION_FAILED')) {
        return res.status(401).json({
          success: false,
          error: 'Razorpay authentication failed. Verify RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.',
          details: rzpErr.error ? rzpErr.error.description : rzpErr.message,
        });
      }

      return res.status(statusCode >= 400 && statusCode < 600 ? statusCode : 500).json({
        success: false,
        error: 'Failed to create Razorpay order',
        details: rzpErr.error ? rzpErr.error.description : rzpErr.message,
      });
    }
  } catch (err) {
    console.error('[Razorpay createOrder] unexpected error:', err);
    return res.status(500).json({
      success: false,
      error: 'Internal server error while creating order',
      message: err.message,
    });
  }
};

/**
 * STEP 3: BACKEND - Verify Signature
 * Endpoint: POST /api/verify-payment
 * Algorithm: HMAC-SHA256(order_id + "|" + payment_id, KEY_SECRET)
 * Compare generated signature with razorpay_signature
 * Return success only if signatures match
 */
exports.verifyPayment = async (req, res) => {
  try {
    const order_id = req.body.order_id || req.body.orderId || req.body.razorpay_order_id;
    const payment_id = req.body.payment_id || req.body.paymentId || req.body.razorpay_payment_id;
    const razorpay_signature = req.body.razorpay_signature || req.body.signature;

    // Missing fields validation
    if (!order_id || !payment_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        error: 'Missing required payment verification fields',
        required: ['order_id', 'payment_id', 'razorpay_signature'],
        received: {
          order_id: Boolean(order_id),
          payment_id: Boolean(payment_id),
          razorpay_signature: Boolean(razorpay_signature),
        },
      });
    }

    const keySecret = razorpayService.getKeySecret();
    if (!keySecret) {
      return res.status(500).json({
        success: false,
        error: 'Server misconfiguration: RAZORPAY_KEY_SECRET is not configured',
      });
    }

    // Algorithm: HMAC-SHA256(order_id + "|" + payment_id, KEY_SECRET)
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(`${order_id}|${payment_id}`)
      .digest('hex');

    // Compare generated signature with razorpay_signature
    let signaturesMatch = false;
    try {
      const expectedBuffer = Buffer.from(expectedSignature, 'utf8');
      const receivedBuffer = Buffer.from(razorpay_signature, 'utf8');
      if (expectedBuffer.length === receivedBuffer.length) {
        signaturesMatch = crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
      }
    } catch (_) {
      signaturesMatch = false;
    }

    if (!signaturesMatch) {
      return res.status(400).json({
        success: false,
        error: 'Payment signature verification failed. Signature mismatch.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Payment verified successfully',
      order_id,
      payment_id,
      status: 'PAID',
    });
  } catch (err) {
    console.error('[Razorpay verifyPayment] error:', err);
    return res.status(500).json({
      success: false,
      error: 'Internal server error while verifying payment',
      message: err.message,
    });
  }
};
