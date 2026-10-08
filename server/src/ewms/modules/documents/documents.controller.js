/**
 * ZeroCarbonix EWMS — Documents & Knowledge Base Controller
 * Manages document storage metadata with strict access-level enforcement
 */

const { repository } = require('../../database/ewms_repository');
const auditService = require('../audit/audit.service');

class DocumentsController {
  list(req, res) {
    const isHrOrAdmin = ['SUPER_ADMIN', 'COMPANY_ADMIN', 'HR_ADMIN'].includes(req.user.role);

    // Filter out CONFIDENTIAL documents for regular employees & managers unless authorized
    const docs = repository.documents.filter(d => {
      if (d.organizationId !== req.organizationId) return false;
      if (d.accessLevel === 'CONFIDENTIAL' && !isHrOrAdmin) return false;
      return true;
    });

    res.json({
      success: true,
      data: docs,
    });
  }

  create(req, res) {
    const { title, category, accessLevel = 'INTERNAL', fileUrl, projectId } = req.body;
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const doc = {
      id: `doc-${Date.now()}`,
      organizationId: req.organizationId,
      title,
      category: category || 'General',
      accessLevel,
      fileUrl: fileUrl || `https://storage.zerocarbonix.com/docs/${encodeURIComponent(title)}.pdf`,
      projectId: projectId || null,
      uploadedBy: req.user.id,
      createdAt: new Date(),
    };

    repository.documents.push(doc);

    auditService.log({
      organizationId: req.organizationId,
      actorId: req.user.id,
      action: 'DOCUMENT_UPLOADED',
      entityName: 'documents',
      entityId: doc.id,
      afterState: { title, accessLevel },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    res.status(201).json({
      success: true,
      data: doc,
    });
  }
}

module.exports = new DocumentsController();
