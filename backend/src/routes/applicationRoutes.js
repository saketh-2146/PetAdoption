const express = require('express');
const router = express.Router();
const applicationController = require('../controllers/applicationController');

// GET /api/applications
router.get('/', applicationController.getAllApplications);

// GET /api/applications/:id
router.get('/:id', applicationController.getApplicationById);

// POST /api/applications
router.post('/', applicationController.createApplication);

// PUT /api/applications/:id
router.put('/:id', applicationController.updateApplication);

// DELETE /api/applications/:id
router.delete('/:id', applicationController.deleteApplication);

module.exports = router;
