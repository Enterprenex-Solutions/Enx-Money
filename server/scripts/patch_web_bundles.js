const fs = require('fs');
const path = require('path');

const targets = [
  path.join(__dirname, '..', 'public', 'main.dart.js'),
  path.join(__dirname, '..', '..', 'client', 'build', 'web', 'main.dart.js'),
];

console.log('=== Patching Compiled Flutter Web Bundles ===\n');

targets.forEach((filePath) => {
  if (!fs.existsSync(filePath)) {
    console.warn(`File not found: ${filePath}`);
    return;
  }

  let content = fs.readFileSync(filePath, 'utf8');
  const initialLength = content.length;

  // 1. Privacy Policy Section 1 Scope & Entity
  const oldPrivacyS1 = 'operated by Enterprenex Solutions Pvt Ltd ("we", "our", or "us"), headquartered in Hyderabad, Telangana, India. ENX Money is a specialized digital bookkeeping utility and Khata ledger designed for small merchants, independent contractors, and enterprises.';
  const newPrivacyS1 = 'operated by Enterprenex Solutions Pvt. Ltd. ("we", "our", or "us"), headquartered at Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India. ENX Money is a specialized digital bookkeeping utility and Khata ledger designed for small merchants, independent contractors, and enterprises.';
  
  if (!content.includes(oldPrivacyS1)) {
    console.warn(`[WARN] oldPrivacyS1 not found in ${filePath}`);
  } else {
    content = content.replace(oldPrivacyS1, newPrivacyS1);
    console.log(`[OK] Replaced Privacy Policy Section 1`);
  }

  // 2. Privacy Policy Section 5 Deletion Portal URL
  const oldPrivacyS5 = 'public web portal at /delete-account.';
  const newPrivacyS5 = 'public web portal at https://enxmoney.enterprenex.solutions/delete-account.';
  if (!content.includes(oldPrivacyS5)) {
    console.warn(`[WARN] oldPrivacyS5 not found in ${filePath}`);
  } else {
    content = content.replace(oldPrivacyS5, newPrivacyS5);
    console.log(`[OK] Replaced Privacy Policy Section 5 URL`);
  }

  // 3. Privacy Policy Section 7 Privacy Officer Contact Details
  const oldPrivacyS7 = 'Company: Enterprenex Solutions Pvt Ltd\\nGrievance / Privacy Officer: Revanth Krishna\\nEmail: privacy@enxmoney.com\\nSupport: support@enxmoney.com\\nAddress: Hyderabad, Telangana, India';
  const newPrivacyS7 = 'Company: Enterprenex Solutions Pvt. Ltd.\\nGrievance / Privacy Officer: Mr. Rohit Pawar (Data Protection Officer)\\nPhone: +91-9226860060\\nBilling Email: billing@enterprenex.solutions\\nGeneral / Legal Email: info@enterprenex.solutions\\nTechnical Support Email: support@enxmoney.com\\nWebsite Domain: https://enxmoney.enterprenex.solutions\\nGitHub Pages Legal Host: https://enterprenex-solution-pvt-ltd.github.io/Enx-Money/\\nAddress: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';
  if (!content.includes(oldPrivacyS7)) {
    console.warn(`[WARN] oldPrivacyS7 not found in ${filePath}`);
  } else {
    content = content.replace(oldPrivacyS7, newPrivacyS7);
    console.log(`[OK] Replaced Privacy Policy Section 7 Contact Block`);
  }

  // 4. Terms Section 6 Limitation of Liability Entity Name
  const oldTermsS6 = 'applicable Indian law, Enterprenex Solutions Pvt Ltd and its directors shall not be liable';
  const newTermsS6 = 'applicable Indian law, Enterprenex Solutions Pvt. Ltd. and its directors shall not be liable';
  if (content.includes(oldTermsS6)) {
    content = content.replace(oldTermsS6, newTermsS6);
    console.log(`[OK] Replaced Terms Section 6 Entity`);
  }

  // 5. Terms Section 7 Arbitration Jurisdiction
  const oldTermsS7 = 'dispute shall be referred to arbitration in Hyderabad, Telangana, under the Arbitration and Conciliation Act, 1996.';
  const newTermsS7 = 'dispute shall be referred to arbitration in Chhatrapati Sambhajinagar, Maharashtra, under the Arbitration and Conciliation Act, 1996.';
  if (!content.includes(oldTermsS7)) {
    console.warn(`[WARN] oldTermsS7 not found in ${filePath}`);
  } else {
    content = content.replace(oldTermsS7, newTermsS7);
    console.log(`[OK] Replaced Terms Section 7 Arbitration`);
  }

  // 6. Terms Section 8 Legal Contact
  const oldTermsS8 = 'Legal inquiries: legal@enxmoney.com\\nGeneral support: support@enxmoney.com\\nOperating Entity: Enterprenex Solutions Pvt Ltd, Hyderabad, India';
  const newTermsS8 = 'Company: Enterprenex Solutions Pvt. Ltd.\\nBilling Support: billing@enterprenex.solutions\\nGeneral / Legal Email: info@enterprenex.solutions\\nTechnical Support Email: support@enxmoney.com\\nPhone: +91-9226860060\\nRegistered Address: Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';
  if (!content.includes(oldTermsS8)) {
    console.warn(`[WARN] oldTermsS8 not found in ${filePath}`);
  } else {
    content = content.replace(oldTermsS8, newTermsS8);
    console.log(`[OK] Replaced Terms Section 8 Legal Contact`);
  }

  // 7. Refund Policy Section 1 Entity
  const oldRefundS1 = 'Enterprenex Solutions Pvt Ltd ("we", "our", or "us") provides ENX Money.';
  const newRefundS1 = 'Enterprenex Solutions Pvt. Ltd. ("we", "our", or "us") provides ENX Money.';
  if (content.includes(oldRefundS1)) {
    content = content.replace(oldRefundS1, newRefundS1);
    console.log(`[OK] Replaced Refund Policy Section 1 Entity`);
  }

  // 8. Refund Policy Section 7 Contact
  const oldRefundS7 = 'Billing Support: support@enxmoney.com\\nLegal & Compliance: legal@enxmoney.com\\nCompany: Enterprenex Solutions Pvt Ltd, Hyderabad, Telangana, India';
  const newRefundS7 = 'Billing Support: billing@enterprenex.solutions\\nGeneral / Legal Email: info@enterprenex.solutions\\nTechnical Support: support@enxmoney.com\\nPhone: +91-9226860060\\nCompany: Enterprenex Solutions Pvt. Ltd., Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India';
  if (!content.includes(oldRefundS7)) {
    console.warn(`[WARN] oldRefundS7 not found in ${filePath}`);
  } else {
    content = content.replace(oldRefundS7, newRefundS7);
    console.log(`[OK] Replaced Refund Policy Section 7 Contact`);
  }

  // 9. Footer strings and Badges
  content = content.split('Permanent Production Document \\u2022 Enterprenex Solutions Pvt Ltd').join('Permanent Production Document \\u2022 Enterprenex Solutions Pvt. Ltd.');
  content = content.split('Permanent Production Document • Enterprenex Solutions Pvt Ltd').join('Permanent Production Document • Enterprenex Solutions Pvt. Ltd.');
  content = content.split('Enterprenex Solutions Pvt Ltd \\u2022 Policy v3.2.0 \\u2022 Effective: September 1, 2026').join('Enterprenex Solutions Pvt. Ltd. \\u2022 Policy v3.2.0 \\u2022 Effective: October 4, 2026');
  content = content.split('Effective: Sep 2026').join('Effective: Oct 2026');

  // Subtitle cards in screens
  content = content.split('A.c("Enterprenex Solutions Pvt Ltd",k,k,k,k,A.m(k,k,f,k,k,k,k,k,k,k,k,12').join('A.c("Enterprenex Solutions Pvt. Ltd.",k,k,k,k,A.m(k,k,f,k,k,k,k,k,k,k,k,12');

  // Modal in string table
  content = content.split('Operating Entity: Enterprenex Solutions Pvt Ltd\\nGoverning Standard: Google Play Developer Compliance & DPDP Act (India)').join('Operating Entity: Enterprenex Solutions Pvt. Ltd.\\nGoverning Standard: Google Play Developer Compliance & DPDP Act (India)');

  // 10. Update API endpoint candidate list to include api.enxmoney.enterprenex.solutions/api/v1
  const oldBcb = 'bCB(){var s=A.a([],t.s)\ns.push("https://enxmoney.enterprenex.solutions/api")';
  const newBcb = 'bCB(){var s=A.a([],t.s)\ns.push("https://api.enxmoney.enterprenex.solutions/api/v1")\ns.push("https://enxmoney.enterprenex.solutions/api")';
  if (content.includes(oldBcb)) {
    content = content.replace(oldBcb, newBcb);
    console.log(`[OK] Injected api.enxmoney.enterprenex.solutions to candidate Base URLs`);
  }

  // 11. Add /app and /web routes to route table
  const targetRouteStr = '"/app-lock",new A.baW(),"/",new A.baX(),"/onboarding"';
  const patchedRouteStr = '"/app-lock",new A.baW(),"/",new A.baX(),"/app",new A.baX(),"/web",new A.baX(),"/onboarding"';
  if (content.includes(targetRouteStr)) {
    content = content.replace(targetRouteStr, patchedRouteStr);
    console.log(`[OK] Injected /app and /web routes into Flutter router table`);
  }

  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`[SUCCESS] Patched ${filePath} (Bytes: ${initialLength} -> ${content.length})\n`);
});
