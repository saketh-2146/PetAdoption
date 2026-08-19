// GET /api/pets
exports.getAllPets = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: 'Get all pets - Not implemented yet',
      data: []
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/pets/:id
exports.getPetById = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: `Get pet ${req.params.id} - Not implemented yet`,
      data: null
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/pets
exports.createPet = async (req, res, next) => {
  try {
    res.status(201).json({
      success: true,
      message: 'Create pet - Not implemented yet',
      data: null
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/pets/:id
exports.updatePet = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: `Update pet ${req.params.id} - Not implemented yet`,
      data: null
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/pets/:id
exports.deletePet = async (req, res, next) => {
  try {
    res.status(200).json({
      success: true,
      message: `Delete pet ${req.params.id} - Not implemented yet`
    });
  } catch (error) {
    next(error);
  }
};
