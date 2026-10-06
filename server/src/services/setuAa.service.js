const https = require('https');

/**
 * Setu Account Aggregator Service
 * Connects to Setu AA Gateway to create consent requests and obtain automated Webview SDK redirect URLs.
 * Documentation: https://docs.setu.co/data/account-aggregator/api-integration
 */
class SetuAaService {
  static get clientId() {
    return process.env.SETU_CLIENT_ID || '';
  }

  static get clientSecret() {
    return process.env.SETU_CLIENT_SECRET || '';
  }

  static get productInstanceId() {
    return process.env.SETU_PRODUCT_INSTANCE_ID || '';
  }

  static get isConfigured() {
    return !!(this.clientId && this.clientSecret);
  }

  static get baseUrl() {
    return process.env.SETU_ENV === 'production'
      ? 'https://fiu.setu.co'
      : 'https://fiu-sandbox.setu.co';
  }

  /**
   * Make HTTPS request to Setu FIU API
   */
  static _request(endpoint, method = 'GET', body = null) {
    return new Promise((resolve, reject) => {
      const url = new URL(endpoint, this.baseUrl);
      const options = {
        hostname: url.hostname,
        port: 443,
        path: url.pathname + url.search,
        method: method.toUpperCase(),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': this.clientId,
          'x-client-secret': this.clientSecret,
        },
      };

      if (this.productInstanceId) {
        options.headers['x-product-instance-id'] = this.productInstanceId;
      }

      const req = https.request(options, (res) => {
        let rawData = '';
        res.on('data', (chunk) => { rawData += chunk; });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(rawData);
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve(parsed);
            } else {
              reject(new Error(parsed.message || parsed.error || `Setu AA error: ${res.statusCode}`));
            }
          } catch (e) {
            reject(new Error(`Invalid JSON response from Setu: ${rawData}`));
          }
        });
      });

      req.on('error', (err) => reject(err));

      if (body) {
        req.write(JSON.stringify(body));
      }
      req.end();
    });
  }

  /**
   * Initiate Account Aggregator Consent Request
   * Calls Setu's /consents API to retrieve the automated redirectUrl.
   *
   * @param {Object} options
   * @param {string} options.phone - Customer 10-digit mobile number
   * @param {string} options.redirectUrl - Callback URL (enxmoney://bank-success)
   * @param {string} options.hostUrl - Server host URL for local simulator fallback
   * @returns {Promise<Object>} { consentId, redirectUrl, isLive }
   */
  static async createConsentRequest({ phone = '9876543210', redirectUrl = 'enxmoney://bank-success', hostUrl = '' } = {}) {
    const cleanPhone = String(phone).replace(/\D/g, '').slice(-10) || '9876543210';
    const consentId = `cst_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    // 1. Try real Setu AA API if credentials are configured
    if (this.isConfigured) {
      try {
        const payload = {
          Detail: {
            consentMode: 'STORE',
            fetchType: 'PERIODIC',
            consentTypes: ['TRANSACTIONS', 'PROFILE', 'SUMMARY'],
            fiTypes: ['DEPOSIT'],
            DataConsumer: {
              id: this.productInstanceId || 'setu-fiu-id',
            },
            Customer: {
              id: `${cleanPhone}@setu`,
            },
            Purpose: {
              code: '101',
              refUri: 'https://api.rebit.org.in',
              text: 'Bank account verification and financial management',
              Category: {
                type: 'Financial Management',
              },
            },
            FIDataRange: {
              from: new Date(Date.now() - 365 * 24 * 3600 * 1000).toISOString(),
              to: new Date().toISOString(),
            },
            DataLife: {
              unit: 'MONTH',
              value: 12,
            },
            Frequency: {
              unit: 'MONTH',
              value: 1,
            },
            DataFilter: [
              {
                type: 'TRANSACTIONAMOUNT',
                operator: '>=',
                value: '0',
              },
            ],
          },
          redirectUrl,
        };

        const res = await this._request('/consents', 'POST', payload);
        const liveRedirectUrl = res.url || res.redirectUrl || (res.data && (res.data.url || res.data.redirectUrl));

        if (liveRedirectUrl) {
          return {
            success: true,
            consentId: res.id || res.consentId || consentId,
            redirectUrl: liveRedirectUrl,
            status: res.status || 'PENDING',
            isLive: true,
          };
        }
      } catch (err) {
        console.warn('[SetuAaService] Live Setu API call failed, falling back to pre-built webview simulator:', err.message);
      }
    }

    // 2. Pre-built Automated Webview SDK Simulator
    // If live credentials are not set or during local development/sandbox,
    // generate automated Setu Webview URL that renders the Setu consent experience.
    const fallbackBase = hostUrl ? hostUrl.replace(/\/$/, '') : 'http://localhost:5000';
    const simulatorUrl = `${fallbackBase}/api/v1/bank/setu-webview?consentId=${consentId}&phone=${cleanPhone}&redirectUrl=${encodeURIComponent(redirectUrl)}`;

    return {
      success: true,
      consentId,
      redirectUrl: simulatorUrl,
      status: 'PENDING',
      isLive: false,
    };
  }
}

module.exports = SetuAaService;
