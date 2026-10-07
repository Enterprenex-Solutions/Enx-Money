export interface FeatureItem {
  id: string;
  title: string;
  tagline: string;
  description: string;
  badge?: string;
  iconName: string;
}

export interface FaqItem {
  question: string;
  answer: string;
}

export interface MetricCard {
  label: string;
  value: string;
  change: string;
  isPositive: boolean;
  subtext: string;
}

export interface BusinessCategory {
  id: string;
  title: string;
  sub: string;
  icon: string;
  tag: string;
  color: string;
}

export const SITE_CONFIG = {
  brandName: 'ENX Money',
  companyName: 'Enterprenex Solutions Pvt. Ltd.',
  tagline: 'Simple • Paperless • Secure',
  supportingText:
    'Dukaan ka digital bahi-khata, GST billing aur payment collection ab aapke smartphone par. Automatic WhatsApp reminders se udhar wasool karein 3x jaldi.',
  heroHeadlineMain: 'Hisaab likho.',
  heroHeadlineHighlight: 'Yaad dilao.',
  heroHeadlineSub: 'Wasool karo.',
  heroSubheadline:
    'Dukaan ka udhar khata ab aapke phone mein. Har credit aur payment entry 100% safe aur secure. Automatic WhatsApp payment reminders se paisa wasool karein 3x jaldi. Bilkul aasan aur bharosemand.',
  
  // URLs - Web App & Direct Android APK
  googlePlayUrl: '/ENX-Money-Consumer.apk',
  webAppUrl: 'https://enterprenex.solutions/app',
  apkDirectDownloadUrl: '/ENX-Money-Consumer.apk',
  appVersion: 'v1.1.0 (Production Release)',

  // Company Contact Details
  officialPhone: '+91 9226860060',
  supportPhone: '+91 9226860060',
  whatsappPhone: '+91 92268 60060',
  whatsappUrl: 'https://wa.me/919226860060',
  billingEmail: 'billing@enterprenex.solutions',
  generalLegalEmail: 'info@enterprenex.solutions',
  supportEmail: 'billing@enterprenex.solutions',
  linkedinUrl: 'https://www.linkedin.com/company/enterprenex-solution-pvt-ltd',
  instagramUrl: 'https://www.instagram.com/enterprenexsolution?utm_source=ig_web_button_share_sheet&stkn=ZDNlZDc0MzIxNw==',
  address: 'Plot No. 148, Shrinand Plaza, CIDCO Waluj Mahanagar 1, Chhatrapati Sambhajinagar, Maharashtra - 431136, India',
  
  // Legal & Portal Links
  privacyUrl: '/privacy-policy',
  termsUrl: '/terms-and-conditions',
  refundUrl: '/refund-policy',
  accountDeletionUrl: '/delete-account',
  workforceUrl: '/workforce',
  staffPortalUrl: '/workforce',
};

export const STATS = [
  { value: '10,000+', label: 'App downloads', sub: 'Across India' },
  { value: '4.8 ★', label: 'Google Play rating', sub: 'Verified dukandaars' },
  { value: '500+', label: 'India ke sheher', sub: 'Metro & Tier 2/3' },
  { value: '100%', label: 'Safe & Secure', sub: 'DPDP Act 2023 Compliant' },
];

export const WORKFLOW_STEPS = [
  {
    step: '1',
    id: 'likho',
    title: 'Hisaab Likho',
    tag: 'Step 1 • Digital Bahi Khata',
    description:
      'Grahak aur supplier ka hisaab-kitab sirf 5 second mein note karein. Khata book khone ya phatne ka koi dar nahi.',
    highlight: 'Instant Balance Tracking',
    badge: '100% Paperless',
  },
  {
    step: '2',
    id: 'yaad-dilao',
    title: 'Yaad Dilao',
    tag: 'Step 2 • Free WhatsApp Reminder',
    description:
      'Ek click par WhatsApp ya SMS se friendly payment reminder bhejein jisme UPI QR code aur bill summary attached hota hai.',
    highlight: 'Zero awkward conversations',
    badge: 'Automatic Reminders',
  },
  {
    step: '3',
    id: 'wasool-karo',
    title: 'Wasool Karo',
    tag: 'Step 3 • Instant Bank Settlement',
    description:
      'Grahak PhonePe, GPay ya Paytm se seedhe aapke bank account mein payment karein. Paisa wasool karein 3 guna jaldi.',
    highlight: 'Direct Bank Settlement',
    badge: '3x Faster Collections',
  },
];

export const BUSINESS_CATEGORIES: BusinessCategory[] = [
  {
    id: 'kirana',
    title: 'Kirana & General Store',
    sub: 'Daily udhar, milk, grocery ledger & fast billing',
    icon: 'Store',
    tag: 'Sabse Zyada Popular',
    color: 'from-emerald-500 to-teal-600',
  },
  {
    id: 'electronics',
    title: 'Electronics & Mobile',
    sub: 'Serial number tracking, GST bills & warranty cards',
    icon: 'Smartphone',
    tag: 'GST Ready',
    color: 'from-blue-500 to-indigo-600',
  },
  {
    id: 'hardware',
    title: 'Hardware & Sanitary',
    sub: 'Bulk contractor khata, material bills & part payments',
    icon: 'Wrench',
    tag: 'Wholesale & Retail',
    color: 'from-amber-500 to-orange-600',
  },
  {
    id: 'garments',
    title: 'Garments & Fashion',
    sub: 'Size/color inventory, festive seasonal credit & invoices',
    icon: 'Shirt',
    tag: 'Smart Inventory',
    color: 'from-purple-500 to-pink-600',
  },
  {
    id: 'pharmacy',
    title: 'Pharmacy & Medical',
    sub: 'Batch tracking, expiry alerts & fast retail billing',
    icon: 'Pill',
    tag: 'Batch Tracking',
    color: 'from-rose-500 to-red-600',
  },
  {
    id: 'wholesale',
    title: 'Wholesale & Distribution',
    sub: 'Party credit limits, salesman field orders & daybooks',
    icon: 'Truck',
    tag: 'High Volume',
    color: 'from-cyan-500 to-blue-600',
  },
];

export const FEATURES: FeatureItem[] = [
  {
    id: 'digital-khata',
    title: 'Digital Udhar Khata',
    tagline: 'Grahak & Supplier Ka Bahi-Khata',
    description:
      'Sabhi grahak aur vyapariyon ka len-den phone par manage karein. Jama (Received) aur Udhar (Given) entries maintain karein with real-time balance calculations.',
    badge: 'Zero Errors',
    iconName: 'BookOpen',
  },
  {
    id: 'whatsapp-reminders',
    title: 'Automatic WhatsApp Reminders',
    tagline: 'Paisa Wasool Karein 3x Tezi Se',
    description:
      'Grahak ko bina sharam ke payment reminder bhejein. WhatsApp par PDF statement aur dynamic UPI payment link bhejne ki suvidha.',
    badge: 'Paisa Wasooli',
    iconName: 'Send',
  },
  {
    id: 'gst-invoicing',
    title: 'GST Billing & Invoices',
    tagline: 'Professional Bills in 10 Seconds',
    description:
      'Aapke dukan ke naam aur logo ke saath Sundar GST aur Non-GST bills banayein. CGST, SGST, IGST aur HSN codes automatic calculate hote hain.',
    badge: '100% Tax Compliant',
    iconName: 'FileCheck',
  },
  {
    id: 'inventory',
    title: 'Smart Stock & Inventory',
    tagline: 'Samaan Ka Pura Hisaab',
    description:
      'Stock kitna bacha hai, kab naya maal khareedna hai, sab track karein. Low-stock alerts se maal khatam hone se pehle update payein.',
    badge: 'Stock Alerts',
    iconName: 'Package',
  },
  {
    id: 'upi-payments',
    title: 'Direct UPI QR Payments',
    tagline: 'Payment Seedhe Bank Account Mein',
    description:
      'Grahak kisi bhi app (PhonePe, Google Pay, Paytm) se QR code scan karke payment kar sakte hain. No middleman, zero deduction.',
    badge: 'Instant UPI',
    iconName: 'Wallet',
  },
  {
    id: 'business-reports',
    title: 'Munafa & Business Reports',
    tagline: 'Roz Ka Sale, Kharcha Aur Profit',
    description:
      'Rozana aur mahine ka sale, kharcha aur net profit ek screen par dekhein. GSTR reports aur account balance sheet 1-click mein download karein.',
    badge: 'Profit Clarity',
    iconName: 'BarChart3',
  },
  {
    id: 'health-score',
    title: 'Business Health Score',
    tagline: 'Dhandhe Ki Asli Tarakki',
    description:
      'Collection speed, payment regularity aur profit margin ko milakar banta hai aapka Business Health Score. Janein aapka dhandha kitna strong hai.',
    badge: 'Smart Insights',
    iconName: 'TrendingUp',
  },
  {
    id: 'security',
    title: '100% Safe Cloud Backup',
    tagline: 'Phone Khone Par Bhi Data Safe',
    description:
      'Aapka sara hisaab secure cloud par automatically save hota hai. Phone badalne ya khone par naye phone mein OTP daalte hi sara data wapas mil jayega.',
    badge: 'Auto Backup',
    iconName: 'ShieldCheck',
  },
];

export const HOW_IT_WORKS = [
  {
    step: '01',
    title: 'Apna Business Register Karein',
    description:
      'Sirf apna mobile number daalein aur OTP se verify karein. Dukaan ka naam aur category select karein—2 minute mein setup complete.',
    highlight: 'Sirf 2 Minute Mein Setup',
  },
  {
    step: '02',
    title: 'Grahak Add Karein & Hisaab Likhein',
    description:
      'Phonebook se direct grahak add karein. Udhar (Given) ya Jama (Received) amount daalein aur item bill attach karein.',
    highlight: 'Zero Accounting Training Needed',
  },
  {
    step: '03',
    title: 'WhatsApp Reminder Bhejein & Collection Karein',
    description:
      'Ek click par grahak ko WhatsApp bill aur payment link bhejein. Payment aate hi ledger automatic update ho jata hai.',
    highlight: '3x Tezi Se Paisa Wasool',
  },
];

export const TRUST_POINTS = [
  {
    title: 'Built for Indian Dukandaars & MSMEs',
    description: 'Desi vyapar ke bahi-khata aur payment culture ko dhyan mein rakh kar banaya gaya platform.',
    icon: 'Store',
  },
  {
    title: 'GST-Ready Billing & HSN Support',
    description: 'Bina kisi accountant ke aasani se professional GST tax invoices aur delivery challan banayein.',
    icon: 'FileCheck',
  },
  {
    title: '100% Safe & Automatic Cloud Backup',
    description: 'Phone khone ya tootne par bhi aapka sara data safe rehta hai. New phone par turant restore.',
    icon: 'ShieldCheck',
  },
  {
    title: 'Mobile App + Computer Web Dono Par',
    description: 'Dukaan par computer se billing karein aur counter ya market mein phone se hisaab dekhein.',
    icon: 'Smartphone',
  },
  {
    title: 'WhatsApp PDF Statement & UPI QR',
    description: 'Grahak ko sundar digital statement aur QR code bhejein taaki payment aane mein deri na ho.',
    icon: 'QrCode',
  },
  {
    title: 'DPDP Act 2023 & RBI Guidelines Aligned',
    description: 'Enterprenex Solutions Pvt. Ltd. ke dwara highest security standards ke saath developed.',
    icon: 'Building2',
  },
];

export const FAQS: FaqItem[] = [
  {
    question: 'Kya ENX Money use karne ke liye accounting aana zaroori hai?',
    answer:
      'Bilkul nahi! ENX Money ko itna aasan banaya gaya hai ki koi bhi dukandar ise bina kisi accounting training ke 2 minute mein chalana seekh sakta hai. Sirf grahak ka naam, Udhar (Given) ya Jama (Received) likhna hota hai.',
  },
  {
    question: 'Agar mera phone kho gaya ya toot gaya, toh kya mera hisaab chala jayega?',
    answer:
      'Kabhi nahi! Aapka sara bahi-khata aur billing data securely cloud par saved rehta hai. Naye phone mein sirf apna registered mobile number daal kar OTP verify karein, sara data 10 second mein wapas aa jayega.',
  },
  {
    question: 'WhatsApp payment reminder kaise kaam karta hai?',
    answer:
      'Aap kisi bhi grahak ke khate mein jakar "Send WhatsApp Reminder" par tap kar sakte hain. App automatic ek professional message generate karega jisme unka baki balance, bill breakdown aur direct UPI QR link hota hai.',
  },
  {
    question: 'Kya main computer / laptop par bhi ENX Money chala sakta hoon?',
    answer:
      'Haan! ENX Money mobile app aur Web Platform dono par seamlessly chalta hai. "Web par chalayein" link se aap computer par billing aur full inventory manage kar sakte hain.',
  },
  {
    question: 'Mere grahak ko reminder bhejte waqt kya koi extra charge lagta hai?',
    answer:
      'Nahi, aap direct apne WhatsApp se unlimited free payment reminders bhej sakte hain. Iska koi hidden charge nahi hai.',
  },
  {
    question: 'Mera data kitna secure hai?',
    answer:
      'ENX Money DPDP Act 2023 compliant hai aur 256-bit bank-grade encryption use karta hai. Aapka customer ya sales data poori tarah confidential rehta hai aur kisi third-party ke saath share nahi kiya jata.',
  },
];
