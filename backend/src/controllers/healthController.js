// GET /api/health
exports.checkHealth = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: 'Node.js backend is running'
    });
  } catch (error) {
    next(error);
  }
};
