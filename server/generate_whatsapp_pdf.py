"""
Generates the comprehensive ENX Money WhatsApp Chatbot & Gemini AI Integration PDF Manual.
"""

import sys
import os
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
    KeepTogether,
    HRFlowable,
)
from reportlab.pdfgen import canvas

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


class NumberedCanvas(canvas.Canvas):
    """Adds running headers, footers, and page numbers."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))

        # Header (pages after cover)
        if self._pageNumber > 1:
            self.drawString(54, 11 * 72 - 36, "ENX Money — WhatsApp Chatbot & Gemini AI Integration Guide")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.5)
            self.line(54, 11 * 72 - 42, 8.5 * 72 - 54, 11 * 72 - 42)

        # Footer
        footer_text = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(8.5 * 72 - 54, 32, footer_text)
        self.drawString(54, 32, "Confidential — Enterprenex Solutions Pvt. Ltd. — ENX Money v2.0")
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 44, 8.5 * 72 - 54, 44)
        self.restoreState()


def create_pdf(output_path: str):
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54,
    )

    styles = getSampleStyleSheet()

    # Custom styles
    primary_color = colors.HexColor("#0D1B3E")
    accent_green = colors.HexColor("#008069")
    accent_blue = colors.HexColor("#1565C0")
    dark_slate = colors.HexColor("#1E293B")
    body_color = colors.HexColor("#334155")
    code_bg = colors.HexColor("#0F172A")

    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=30,
        textColor=primary_color,
        spaceAfter=6,
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=accent_green,
        spaceAfter=15,
    )

    h1_style = ParagraphStyle(
        'Header1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=20,
        textColor=primary_color,
        spaceBefore=14,
        spaceAfter=8,
        keepWithNext=True,
    )

    h2_style = ParagraphStyle(
        'Header2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=accent_blue,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True,
    )

    body_style = ParagraphStyle(
        'Body',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=body_color,
        spaceAfter=6,
    )

    bullet_style = ParagraphStyle(
        'BulletText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=body_color,
        leftIndent=12,
        spaceAfter=3,
    )

    code_style = ParagraphStyle(
        'CodeBlock',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#A7F3D0"),
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white,
    )

    table_cell_style = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=dark_slate,
    )

    table_code_style = ParagraphStyle(
        'TableCode',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#0369A1"),
    )

    story = []

    # ─────────────────────────────────────────────────────────────────────────
    # COVER / HEADER
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("ENX Money — WhatsApp Chatbot", title_style))
    story.append(Paragraph("Secure Conversational Banking & Gemini AI Integration Specification", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=accent_green, spaceAfter=14))

    # Meta banner
    doc_meta_data = [
        [
            Paragraph("<b>Version:</b> 2.0.0 (Production Ready)", table_cell_style),
            Paragraph("<b>AI Engine:</b> Google Gemini 2.5 Flash / Grok", table_cell_style),
            Paragraph("<b>Status:</b> Verified & Integrated", table_cell_style),
        ],
        [
            Paragraph("<b>Client:</b> Flutter Web & Mobile", table_cell_style),
            Paragraph("<b>Backend:</b> Node.js / FastAPI", table_cell_style),
            Paragraph("<b>Date:</b> September 2026", table_cell_style),
        ]
    ]
    meta_table = Table(doc_meta_data, colWidths=[168, 168, 168])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F1F5F9")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 1: ENVIRONMENT & CREDENTIALS
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("1. Core Environment Variables & Configuration", h1_style))
    story.append(Paragraph(
        "Configure these environment variables in your <code>server/.env</code> file to activate the Meta WhatsApp Cloud API and Google Gemini API integration:",
        body_style
    ))

    env_data = [
        [
            Paragraph("<b>Variable Name</b>", table_header_style),
            Paragraph("<b>Required Value / Template</b>", table_header_style),
            Paragraph("<b>Description</b>", table_header_style),
        ],
        [
            Paragraph("<code>WHATSAPP_VERIFY_TOKEN</code>", table_code_style),
            Paragraph("<code>enx_money_webhook_token_2026</code>", table_cell_style),
            Paragraph("Secret token matched during Meta Webhook validation handshake.", table_cell_style),
        ],
        [
            Paragraph("<code>WHATSAPP_ACCESS_TOKEN</code>", table_code_style),
            Paragraph("<code>&lt;Meta System User Access Token&gt;</code>", table_cell_style),
            Paragraph("Permanent bearer token from Meta Business Manager to send WhatsApp messages.", table_cell_style),
        ],
        [
            Paragraph("<code>WHATSAPP_PHONE_NUMBER_ID</code>", table_code_style),
            Paragraph("<code>&lt;Meta Phone Number ID&gt;</code>", table_cell_style),
            Paragraph("15-digit Phone Number ID assigned in Meta WhatsApp API Dashboard.", table_cell_style),
        ],
        [
            Paragraph("<code>GEMINI_API_KEY</code>", table_code_style),
            Paragraph("<code>&lt;Your Google AI Studio Gemini Key&gt;</code>", table_cell_style),
            Paragraph("API key for Gemini 2.5 Flash model with Function Calling.", table_cell_style),
        ],
        [
            Paragraph("<code>WHATSAPP_PROVIDER</code>", table_code_style),
            Paragraph("<code>meta</code> | <code>twilio</code> | <code>simulator</code>", table_cell_style),
            Paragraph("Outbound message driver. Defaults to 'simulator' in dev mode.", table_cell_style),
        ],
    ]
    t_env = Table(env_data, colWidths=[140, 160, 204])
    t_env.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_env)
    story.append(Spacer(1, 10))

    # Env Code Block Box
    env_snippet = (
        "# ENX Money WhatsApp & AI Configuration\n"
        "WHATSAPP_VERIFY_TOKEN=enx_money_webhook_token_2026\n"
        "WHATSAPP_ACCESS_TOKEN=<Meta token>\n"
        "WHATSAPP_PHONE_NUMBER_ID=<Meta phone ID>\n"
        "GEMINI_API_KEY=<your Gemini key>\n"
        "GEMINI_MODEL=gemini-2.5-flash\n"
        "WHATSAPP_PROVIDER=simulator  # change to 'meta' for production"
    )
    t_snip = Table([[Paragraph(f"<pre>{env_snippet}</pre>", code_style)]], colWidths=[504])
    t_snip.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), code_bg),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#1E293B")),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    story.append(t_snip)
    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 2: SYSTEM ARCHITECTURE
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("2. System Architecture & Component Separation", h1_style))
    story.append(Paragraph(
        "The integration enforces strict boundary isolation between the WhatsApp channel, the conversational AI layer, the ENX Money backend controllers, and the database:",
        body_style
    ))

    arch_bullets = [
        "<b>WhatsApp Communication Layer:</b> Ingests webhook events from Meta Cloud API (or Twilio/Web Simulator). Handles signature verification and dispatches outbound formatted WhatsApp messages.",
        "<b>Session & Security Layer:</b> Maps incoming phone numbers to registered ENX Money accounts, executes 6-digit OTP pairings, prevents session hijacking, and generates single-use 10-minute expiring tokens.",
        "<b>Conversational AI Engine (Gemini / Grok):</b> Analyzes natural language messages, converts them into structured tool calls, invokes financial controller services, and formats rich WhatsApp responses.",
        "<b>ENX Money Financial Core:</b> Enforces user tenancy isolation, calculates balance and KPI summaries, records transactions, and checks customer receivables and vendor payables.",
    ]
    for b in arch_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))

    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 3: META WHATSAPP CLOUD API SETUP
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("3. Meta WhatsApp Cloud API Setup Walkthrough", h1_style))
    story.append(Paragraph(
        "Follow these exact steps in your Meta for Developers Console to connect the ENX Money server with a live WhatsApp Business number:",
        body_style
    ))

    steps = [
        ("Step 1: Create Meta Developer App", "Go to <code>developers.facebook.com</code>, click <b>Create App</b>, choose <b>Business</b> as App Type, and name it <b>ENX Money WhatsApp Bot</b>."),
        ("Step 2: Add WhatsApp Product", "In the App Dashboard, locate the <b>WhatsApp</b> tile and click <b>Set Up</b>. This provisions a test WhatsApp Business phone number and test credentials."),
        ("Step 3: Retrieve Phone Number ID", "Navigate to <b>WhatsApp &gt; API Setup</b>. Copy the <b>Phone number ID</b> (e.g., <code>105934812345678</code>) and set it as <code>WHATSAPP_PHONE_NUMBER_ID</code>."),
        ("Step 4: Generate Permanent Access Token", "Under Meta Business Manager &gt; <b>System Users</b>, create a System User with Admin access. Generate a permanent token with <code>whatsapp_business_messaging</code> and <code>whatsapp_business_management</code> scopes. Save as <code>WHATSAPP_ACCESS_TOKEN</code>."),
        ("Step 5: Configure Webhook Callback", "Under <b>WhatsApp &gt; Configuration &gt; Webhook</b>, click <b>Edit</b>:<br/>• <b>Callback URL:</b> <code>https://your-domain.com/api/whatsapp/webhook</code><br/>• <b>Verify Token:</b> <code>enx_money_webhook_token_2026</code><br/>Click <b>Verify and Save</b>, then manage fields and subscribe to <b>messages</b>."),
    ]
    for title, desc in steps:
        story.append(Paragraph(f"<b>{title}:</b> {desc}", body_style))

    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 4: GEMINI AI FUNCTION CALLING & FINANCIAL TOOLS
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("4. Gemini AI Function Calling & Financial Tools", h1_style))
    story.append(Paragraph(
        "The chatbot uses Gemini API tool declarations so that user queries are executed against real database calculations:",
        body_style
    ))

    tool_data = [
        [
            Paragraph("<b>Tool Function Name</b>", table_header_style),
            Paragraph("<b>Example User Prompts</b>", table_header_style),
            Paragraph("<b>Backend Operation</b>", table_header_style),
        ],
        [
            Paragraph("<code>getFinancialKPIs</code>", table_code_style),
            Paragraph('"What is my current balance and profit?", "Revenue this month"', table_cell_style),
            Paragraph("Aggregates total revenue, expense, net profit, receivables, and payables.", table_cell_style),
        ],
        [
            Paragraph("<code>getOutstandingReceivables</code>", table_code_style),
            Paragraph('"Who owes me money?", "Pending customer invoices"', table_cell_style),
            Paragraph("Filters customers with balance &gt; 0 and formats contact and invoice dues.", table_cell_style),
        ],
        [
            Paragraph("<code>getOutstandingPayables</code>", table_code_style),
            Paragraph('"What bills are due to suppliers?", "Vendor payables"', table_cell_style),
            Paragraph("Surfaces vendor payables grouped by category with payment deadlines.", table_cell_style),
        ],
        [
            Paragraph("<code>getRecentTransactions</code>", table_code_style),
            Paragraph('"Show recent transactions", "Last 5 expense entries"', table_cell_style),
            Paragraph("Fetches chronologically sorted ledger entries with clearance indicators.", table_cell_style),
        ],
        [
            Paragraph("<code>checkTransactionStatus</code>", table_code_style),
            Paragraph('"Status of invoice INV-2026-001"', table_cell_style),
            Paragraph("Looks up invoice number, clearance status, payment mode, and notes.", table_cell_style),
        ],
        [
            Paragraph("<code>stageQuickTransaction</code>", table_code_style),
            Paragraph('"Add expense 2500 for Office Supplies"', table_cell_style),
            Paragraph("Prepares draft and prompts CONFIRM or CANCEL before ledger write.", table_cell_style),
        ],
        [
            Paragraph("<code>createSecureAppHandoff</code>", table_code_style),
            Paragraph('"Give me a link to open the app", "Open compliance"', table_cell_style),
            Paragraph("Issues 10-minute expiring cryptographic token for deep linking.", table_cell_style),
        ],
    ]
    t_tools = Table(tool_data, colWidths=[140, 164, 200])
    t_tools.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_tools)
    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 5: SECURITY & USER PAIRING
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("5. Security, Tenancy & Handoff Protocols", h1_style))
    story.append(Paragraph(
        "Financial data privacy is safeguarded through multiple layers of authentication:",
        body_style
    ))

    sec_bullets = [
        "<b>6-Digit OTP Pairing:</b> Unregistered numbers cannot access data. The bot prompts for the user's registered ENX Money email and issues an OTP code with a 10-minute validity window.",
        "<b>Strict User Tenancy:</b> Every database query is scoped to <code>user_id</code> of the paired WhatsApp user. Users can never query another enterprise's transactions or balances.",
        "<b>Single-Use Cryptographic Handoff Tokens:</b> When a user asks to view deep reports or complete sensitive actions, the server generates a token (<code>enx_&lt;hex&gt;</code>) with 10-minute expiry and instant consumption on first click to eliminate replay attacks.",
        "<b>Confirmation Protocol:</b> Recording transactions via WhatsApp requires explicit <code>CONFIRM</code> reply from the user.",
    ]
    for b in sec_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))

    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 6: IN-APP FLUTTER ASSISTANT & WEB SIMULATOR
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("6. In-App Flutter Assistant & Web Simulator", h1_style))
    story.append(Paragraph(
        "The WhatsApp chatbot is accessible through two native interfaces for testing and daily operation:",
        body_style
    ))

    ui_bullets = [
        "<b>Flutter In-App Assistant:</b> Integrated into <code>Enx-Money/client</code> under the sidebar as <b>WhatsApp Assistant</b> (with <code>AI BOT</code> badge) and as a 1-tap AppBar icon on the Dashboard. Features authentic WhatsApp green theming, typing indicators, quick chips, and interactive buttons that jump directly to app tabs.",
        "<b>Web Simulator Console:</b> Available at <code>http://127.0.0.1:8000/whatsapp-simulator</code>. Provides a browser-based WhatsApp phone frame with a live <b>AI & Diagnostics Inspector</b> showing tool calls, latency, and JSON context.",
    ]
    for b in ui_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))

    story.append(Spacer(1, 14))

    # ─────────────────────────────────────────────────────────────────────────
    # SECTION 7: API & WEBHOOK ENDPOINTS REFERENCE
    # ─────────────────────────────────────────────────────────────────────────
    story.append(Paragraph("7. Complete Endpoint Reference", h1_style))

    api_data = [
        [
            Paragraph("<b>Endpoint</b>", table_header_style),
            Paragraph("<b>Method</b>", table_header_style),
            Paragraph("<b>Parameters / Body</b>", table_header_style),
            Paragraph("<b>Purpose</b>", table_header_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/webhook</code>", table_code_style),
            Paragraph("<code>GET</code>", table_cell_style),
            Paragraph("<code>hub.mode, hub.challenge, hub.verify_token</code>", table_cell_style),
            Paragraph("Meta WhatsApp Cloud API handshake verification.", table_cell_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/webhook</code>", table_code_style),
            Paragraph("<code>POST</code>", table_cell_style),
            Paragraph("Meta WhatsApp Cloud message payload", table_cell_style),
            Paragraph("Ingests incoming WhatsApp messages from Meta.", table_cell_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/twilio-webhook</code>", table_code_style),
            Paragraph("<code>POST</code>", table_cell_style),
            Paragraph("<code>From, Body</code> (Form-encoded)", table_cell_style),
            Paragraph("Twilio WhatsApp webhook ingestion (returns TwiML).", table_cell_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/simulate</code>", table_code_style),
            Paragraph("<code>POST</code>", table_cell_style),
            Paragraph("<code>{ phoneNumber, message }</code>", table_cell_style),
            Paragraph("REST API for in-app simulator and testing.", table_cell_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/sessions</code>", table_code_style),
            Paragraph("<code>GET</code>", table_cell_style),
            Paragraph("None", table_cell_style),
            Paragraph("Lists active paired users and conversation states.", table_cell_style),
        ],
        [
            Paragraph("<code>/api/whatsapp/handoff/open</code>", table_code_style),
            Paragraph("<code>GET</code>", table_cell_style),
            Paragraph("<code>token=&lt;enx_hex&gt;</code>", table_cell_style),
            Paragraph("Consumes token and authenticates user into the web app.", table_cell_style),
        ],
    ]
    t_api = Table(api_data, colWidths=[120, 50, 164, 170])
    t_api.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_color),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_api)
    story.append(Spacer(1, 18))

    # Sign-off box
    signoff_data = [
        [
            Paragraph("<b>Document Author:</b> ENX Money Engineering Team", table_cell_style),
            Paragraph("<b>Approved by:</b> Chief Technology Officer", table_cell_style),
            Paragraph("<b>Branch:</b> Anjali (Production Staging)", table_cell_style),
        ]
    ]
    t_sign = Table(signoff_data, colWidths=[168, 168, 168])
    t_sign.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_sign)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"✅ PDF successfully generated at: {output_path}")


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "exports"
    out_dir.mkdir(parents=True, exist_ok=True)
    pdf_file = out_dir / "ENX_Money_WhatsApp_Chatbot_Guide.pdf"
    create_pdf(str(pdf_file))
